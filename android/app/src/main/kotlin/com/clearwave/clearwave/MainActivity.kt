package com.clearwave.clearwave

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import com.clearwave.clearwave.vpn.ClearwaveVpnService
import com.clearwave.clearwave.vpn.NativeFilterMatcher
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val VPN_REQUEST_CODE = 2026
        private const val METHOD_CHANNEL = "com.clearwave/engine"
        private const val EVENT_CHANNEL = "com.clearwave/events"
    }

    private var pendingMethodResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. MethodChannel for VPN Engine Lifecycle & Rule Sync
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startProtection" -> {
                    startVpnProtection(result)
                }
                "stopProtection" -> {
                    stopVpnProtection()
                    result.success(true)
                }
                "getStatus" -> {
                    result.success(ClearwaveVpnService.isRunning)
                }
                "syncRules" -> {
                    val allowlist = call.argument<Map<String, String>>("allowlist") ?: emptyMap()
                    val blocklist = call.argument<Map<String, String>>("blocklist") ?: emptyMap()
                    NativeFilterMatcher.syncRules(allowlist, blocklist)
                    result.success(true)
                }
                "setUpstreamDns" -> {
                    val dnsIp = call.argument<String>("dnsIp") ?: "9.9.9.9"
                    ClearwaveVpnService.upstreamDnsIp = dnsIp
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 2. EventChannel for Live DNS Query Streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    ClearwaveVpnService.onDnsEventListener = { domain, isBlocked, rule, latency ->
                        runOnUiThread {
                            eventSink?.success(
                                mapOf(
                                    "domain" to domain,
                                    "isBlocked" to isBlocked,
                                    "matchedRule" to rule,
                                    "latencyMs" to latency,
                                    "timestamp" to System.currentTimeMillis()
                                )
                            )
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    ClearwaveVpnService.onDnsEventListener = null
                }
            }
        )
    }

    private fun startVpnProtection(result: MethodChannel.Result) {
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent != null) {
            // VPN permission dialog needed from user
            pendingMethodResult = result
            startActivityForResult(prepareIntent, VPN_REQUEST_CODE)
        } else {
            // Already authorized, start service immediately
            startVpnServiceInternal()
            result.success(true)
        }
    }

    private fun startVpnServiceInternal() {
        val intent = Intent(this, ClearwaveVpnService::class.java).apply {
            action = ClearwaveVpnService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopVpnProtection() {
        val intent = Intent(this, ClearwaveVpnService::class.java).apply {
            action = ClearwaveVpnService.ACTION_STOP
        }
        startService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                startVpnServiceInternal()
                pendingMethodResult?.success(true)
            } else {
                pendingMethodResult?.error(
                    "VPN_PERMISSION_DENIED",
                    "User denied VPN configuration permission",
                    null
                )
            }
            pendingMethodResult = null
        }
    }
}
