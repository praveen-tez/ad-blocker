package com.clearwave.clearwave.vpn

import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets

/**
 * High-performance low-level IPv4 / UDP / DNS packet parser and synthesizer.
 * Handles parsing client DNS requests and generating 0.0.0.0 / :: sinkhole responses.
 */
object DnsPacketParser {

    data class DnsQuery(
        val transactionId: Short,
        val domain: String,
        val qType: Int,
        val qClass: Int,
        val srcIp: ByteArray,
        val dstIp: ByteArray,
        val srcPort: Int,
        val dstPort: Int,
        val rawUdpPayload: ByteArray
    )

    /**
     * Parses raw IPv4 packet from TUN interface. Returns DnsQuery if it is a UDP packet to port 53.
     */
    fun parseIpv4UdpDns(packet: ByteArray, length: Int): DnsQuery? {
        if (length < 28) return null // 20 bytes IP + 8 bytes UDP

        val versionAndIhl = packet[0].toInt() and 0xFF
        val version = versionAndIhl shr 4
        if (version != 4) return null // Only IPv4 for now

        val ihl = (versionAndIhl and 0x0F) * 4
        if (length < ihl + 8) return null

        val protocol = packet[9].toInt() and 0xFF
        if (protocol != 17) return null // UDP protocol only

        val srcIp = packet.copyOfRange(12, 16)
        val dstIp = packet.copyOfRange(16, 20)

        // Parse UDP Header
        val srcPort = ((packet[ihl].toInt() and 0xFF) shl 8) or (packet[ihl + 1].toInt() and 0xFF)
        val dstPort = ((packet[ihl + 2].toInt() and 0xFF) shl 8) or (packet[ihl + 3].toInt() and 0xFF)

        if (dstPort != 53) return null // Must be destined for DNS port 53

        val udpPayloadOffset = ihl + 8
        val udpPayloadLength = length - udpPayloadOffset
        if (udpPayloadLength < 12) return null // Minimum DNS header length

        val rawPayload = packet.copyOfRange(udpPayloadOffset, length)
        val buffer = ByteBuffer.wrap(rawPayload)

        val txId = buffer.short
        val flags = buffer.short.toInt() and 0xFFFF
        val isQuery = (flags and 0x8000) == 0
        if (!isQuery) return null

        val qdCount = buffer.short.toInt() and 0xFFFF
        if (qdCount < 1) return null

        buffer.position(12) // Skip to Question section
        val domain = extractDomainName(buffer) ?: return null

        if (buffer.remaining() < 4) return null
        val qType = buffer.short.toInt() and 0xFFFF
        val qClass = buffer.short.toInt() and 0xFFFF

        return DnsQuery(
            transactionId = txId,
            domain = domain,
            qType = qType,
            qClass = qClass,
            srcIp = srcIp,
            dstIp = dstIp,
            srcPort = srcPort,
            dstPort = dstPort,
            rawUdpPayload = rawPayload
        )
    }

    /**
     * Extracts canonical QNAME domain name from DNS question section.
     */
    private fun extractDomainName(buffer: ByteBuffer): String? {
        val parts = mutableListOf<String>()
        try {
            while (buffer.hasRemaining()) {
                val len = buffer.get().toInt() and 0xFF
                if (len == 0) break // End of domain labels

                if ((len and 0xC0) == 0xC0) {
                    // Pointer compression, skip offset byte
                    if (buffer.hasRemaining()) buffer.get()
                    break
                }

                if (buffer.remaining() < len) return null
                val bytes = ByteArray(len)
                buffer.get(bytes)
                parts.add(String(bytes, StandardCharsets.UTF_8))
            }
        } catch (e: Exception) {
            return null
        }
        return if (parts.isEmpty()) null else parts.joinToString(".").lowercase()
    }

    /**
     * Builds a synthesized DNS Block/Sinkhole response packet (0.0.0.0 for A, :: for AAAA).
     */
    fun buildSinkholeResponsePacket(query: DnsQuery): ByteArray {
        val dnsResponse = buildDnsSinkholePayload(query)

        // IP Header (20 bytes) + UDP Header (8 bytes) + DNS Payload
        val totalLength = 20 + 8 + dnsResponse.size
        val packet = ByteBuffer.allocate(totalLength)

        // 1. IPv4 Header
        packet.put(0x45.toByte()) // Version 4, IHL 5 (20 bytes)
        packet.put(0x00.toByte()) // DSCP/ECN
        packet.putShort(totalLength.toShort()) // Total Length
        packet.putShort(query.transactionId) // Identification
        packet.putShort(0x4000.toShort()) // Flags: Don't Fragment
        packet.put(64.toByte()) // TTL: 64
        packet.put(17.toByte()) // Protocol: UDP (17)
        packet.putShort(0) // Checksum placeholder
        packet.put(query.dstIp) // Swap: Dest IP becomes Source IP
        packet.put(query.srcIp) // Swap: Source IP becomes Dest IP

        // Compute and write IPv4 header checksum
        val ipChecksum = computeIpChecksum(packet.array(), 0, 20)
        packet.putShort(10, ipChecksum)

        // 2. UDP Header
        val udpLength = 8 + dnsResponse.size
        packet.putShort(query.dstPort.toShort()) // Swap: Dest Port becomes Source Port (53)
        packet.putShort(query.srcPort.toShort()) // Swap: Source Port becomes Dest Port
        packet.putShort(udpLength.toShort())
        packet.putShort(0) // UDP Checksum optional in IPv4 (0 means disabled)

        // 3. DNS Payload
        packet.put(dnsResponse)

        return packet.array()
    }

    /**
     * Synthesizes standard DNS response payload with authoritative answers.
     */
    private fun buildDnsSinkholePayload(query: DnsQuery): ByteArray {
        val out = ByteBuffer.allocate(512)

        // Header
        out.putShort(query.transactionId)
        // Flags: QR=1 (response), Opcode=0, AA=1 (authoritative), RD=1, RA=1, RCODE=0 (NoError)
        out.putShort(0x8580.toShort())
        out.putShort(1.toShort()) // QDCOUNT (1 question)

        val isA = query.qType == 1
        val isAaaa = query.qType == 28
        val hasAnswer = isA || isAaaa

        out.putShort((if (hasAnswer) 1 else 0).toShort()) // ANCOUNT
        out.putShort(0) // NSCOUNT
        out.putShort(0) // ARCOUNT

        // Echo Question Section
        encodeDomainName(out, query.domain)
        out.putShort(query.qType.toShort())
        out.putShort(query.qClass.toShort())

        // Answer Section
        if (hasAnswer) {
            // Name pointer to question domain (offset 12 = 0xC00C)
            out.putShort(0xC00C.toShort())
            out.putShort(query.qType.toShort())
            out.putShort(query.qClass.toShort())
            out.putInt(300) // TTL: 300 seconds

            if (isA) {
                out.putShort(4.toShort()) // RDLENGTH: 4 bytes
                out.put(byteArrayOf(0, 0, 0, 0)) // 0.0.0.0
            } else {
                out.putShort(16.toShort()) // RDLENGTH: 16 bytes
                out.put(ByteArray(16)) // :: (zeros)
            }
        }

        val result = ByteArray(out.position())
        System.arraycopy(out.array(), 0, result, 0, out.position())
        return result
    }

    private fun encodeDomainName(buffer: ByteBuffer, domain: String) {
        val labels = domain.split(".")
        for (label in labels) {
            val bytes = label.toByteArray(StandardCharsets.UTF_8)
            buffer.put(bytes.size.toByte())
            buffer.put(bytes)
        }
        buffer.put(0.toByte()) // Root null terminator
    }

    private fun computeIpChecksum(data: ByteArray, offset: Int, length: Int): Short {
        var sum = 0
        for (i in offset until offset + length step 2) {
            val high = data[i].toInt() and 0xFF
            val low = data[i + 1].toInt() and 0xFF
            sum += (high shl 8) or low
        }
        while ((sum shr 16) > 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        return (sum.inv() and 0xFFFF).toShort()
    }
}

