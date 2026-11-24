package com.clearwave.clearwave.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import com.clearwave.clearwave.MainActivity
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.ByteBuffer

class ClearwaveVpnService : VpnService() {

    companion object {
        private const val TAG = "ClearwaveVpn"
        const val ACTION_START = "com.clearwave.START_VPN"
        const val ACTION_STOP = "com.clearwave.STOP_VPN"
        const val NOTIFICATION_ID = 2026
        const val CHANNEL_ID = "clearwave_vpn_status"

        @Volatile
        var isRunning: Boolean = false
            private set

        @Volatile
        var upstreamDnsIp: String = "9.9.9.9" // Quad9 default

        // Callback listener to stream live DNS query events back to Flutter
        var onDnsEventListener: ((domain: String, isBlocked: Boolean, rule: String, latencyMs: Long) -> Unit)? = null
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        setupNetworkMonitoring()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopVpn()
            else -> startVpn()
        }
        return START_STICKY
    }

    private fun startVpn() {
        if (isRunning) return

        try {
            val builder = Builder()
            builder.setSession("CLEARWAVE")
            builder.setMtu(1500)

            // Loopback Virtual IP (DNS only)
            builder.addAddress("10.222.0.1", 32)
            builder.addDnsServer("10.222.0.1")
            builder.addRoute("10.222.0.1", 32)

            // IPv6 Loopback DNS
            try {
                builder.addAddress("fd00::1", 128)
                builder.addDnsServer("fd00::1")
                builder.addRoute("fd00::1", 128)
            } catch (e: Exception) {
                Log.w(TAG, "IPv6 configuration skipped: ${e.message}")
            }

            // Route ONLY DNS traffic through this loopback TUN interface.
            // Exclude CLEARWAVE from VPN routing so upstream resolution doesn't loop.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    builder.addDisallowedApplication(packageName)
                } catch (e: Exception) {
                    Log.w(TAG, "addDisallowedApplication: ${e.message}")
                }
            }

            vpnInterface = builder.establish()
            if (vpnInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface (null)")
                stopSelf()
                return
            }

            isRunning = true
            startForeground(NOTIFICATION_ID, buildForegroundNotification())

            // Start reading and processing packets
            serviceScope.launch {
                runPacketLoop(vpnInterface!!)
            }

            Log.i(TAG, "CLEARWAVE DNS filtering engine started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN: ${e.message}", e)
            stopVpn()
        }
    }

    /**
     * Reads IPv4 packets from TUN, sinkholes blocked domains locally,
     * and forwards clean/allowed DNS requests to the upstream resolver.
     */
    private suspend fun runPacketLoop(descriptor: ParcelFileDescriptor) = withContext(Dispatchers.IO) {
        val inputStream = FileInputStream(descriptor.fileDescriptor)
        val outputStream = FileOutputStream(descriptor.fileDescriptor)
        val packetBuffer = ByteArray(32767)

        val upstreamSocket = DatagramSocket()
        protect(upstreamSocket) // Standard Android VpnService: bypasses TUN loopback
        upstreamSocket.soTimeout = 4000

        try {
            while (isActive && isRunning) {
                val length = inputStream.read(packetBuffer)
                if (length <= 0) continue

                val query = DnsPacketParser.parseIpv4UdpDns(packetBuffer, length)
                if (query == null) {
                    // Non-DNS packet or invalid format, discard
                    continue
                }

                val startTime = System.currentTimeMillis()
                val match = NativeFilterMatcher.evaluate(query.domain)

                if (match.isBlocked) {
                    // SINKHOLE: Generate 0.0.0.0 local response packet and write to TUN
                    val responsePacket = DnsPacketParser.buildSinkholeResponsePacket(query)
                    outputStream.write(responsePacket)
                    outputStream.flush()

                    onDnsEventListener?.invoke(
                        query.domain,
                        true,
                        match.matchedRule,
                        System.currentTimeMillis() - startTime
                    )
                } else {
                    // ALLOWED: Forward UDP query to protected upstream resolver
                    launch {
                        try {
                            val upstreamAddr = InetAddress.getByName(upstreamDnsIp)
                            val outPacket = DatagramPacket(
                                query.rawUdpPayload,
                                query.rawUdpPayload.size,
                                upstreamAddr,
                                53
                            )

                            upstreamSocket.send(outPacket)

                            val respBuffer = ByteArray(4096)
                            val inPacket = DatagramPacket(respBuffer, respBuffer.size)
                            upstreamSocket.receive(inPacket)

                            val latency = System.currentTimeMillis() - startTime

                            // Synthesize IPv4 packet around the upstream DNS answer
                            val replyPacket = wrapDnsResponseInIpUdp(query, inPacket.data, inPacket.length)
                            synchronized(outputStream) {
                                outputStream.write(replyPacket)
                                outputStream.flush()
                            }

                            onDnsEventListener?.invoke(
                                query.domain,
                                false,
                                match.matchedRule,
                                latency
                            )
                        } catch (e: Exception) {
                            Log.w(TAG, "Upstream DNS resolution error for ${query.domain}: ${e.message}")
                        }
                    }
                }
            }
        } catch (e: Exception) {
            if (isRunning) {
                Log.e(TAG, "Packet loop terminated: ${e.message}")
            }
        } finally {
            try {
                upstreamSocket.close()
                inputStream.close()
                outputStream.close()
            } catch (e: Exception) {
                // Ignore closing cleanup
            }
        }
    }

    private fun wrapDnsResponseInIpUdp(query: DnsPacketParser.DnsQuery, dnsPayload: ByteArray, dnsLength: Int): ByteArray {
        val totalLength = 20 + 8 + dnsLength
        val packet = ByteBuffer.allocate(totalLength)

        // 1. IP Header
        packet.put(0x45.toByte())
        packet.put(0x00.toByte())
        packet.putShort(totalLength.toShort())
        packet.putShort(query.transactionId)
        packet.putShort(0x4000.toShort())
        packet.put(64.toByte())
        packet.put(17.toByte())
        packet.putShort(0)
        packet.put(query.dstIp) // Swap
        packet.put(query.srcIp) // Swap

        // Checksum
        var sum = 0
        for (i in 0 until 20 step 2) {
            val high = packet.get(i).toInt() and 0xFF
            val low = packet.get(i + 1).toInt() and 0xFF
            sum += (high shl 8) or low
        }
        while ((sum shr 16) > 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        val ipChecksum = (sum.inv() and 0xFFFF).toShort()
        packet.putShort(10, ipChecksum)

        // 2. UDP Header
        val udpLength = 8 + dnsLength
        packet.putShort(query.dstPort.toShort())
        packet.putShort(query.srcPort.toShort())
        packet.putShort(udpLength.toShort())
        packet.putShort(0)

        // 3. DNS Response Data
        packet.put(dnsPayload, 0, dnsLength)
        return packet.array()
    }

    private fun stopVpn() {
        isRunning = false
        serviceScope.cancel()

        try {
            vpnInterface?.close()
            vpnInterface = null
        } catch (e: Exception) {
            Log.e(TAG, "Error closing VPN descriptor: ${e.message}")
        }

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.i(TAG, "CLEARWAVE DNS filtering engine stopped")
    }

    private fun setupNetworkMonitoring() {
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                Log.d(TAG, "Network active: $network")
            }

            override fun onLost(network: Network) {
                Log.d(TAG, "Network disconnected: $network")
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        connectivityManager?.registerNetworkCallback(request, networkCallback!!)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CLEARWAVE Protection Status",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows active on-device DNS filter firewall status"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("CLEARWAVE Protection Active")
            .setContentText("Local DNS firewall running • Zero HTTPS interception")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        stopVpn()
        networkCallback?.let { connectivityManager?.unregisterNetworkCallback(it) }
        super.onDestroy()
    }
}

