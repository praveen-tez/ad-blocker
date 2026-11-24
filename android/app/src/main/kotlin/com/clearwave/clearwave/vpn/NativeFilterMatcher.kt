package com.clearwave.clearwave.vpn

import java.util.concurrent.ConcurrentHashMap

/**
 * Thread-safe, ultra-low-latency in-memory domain matching engine in Kotlin.
 * Evaluates real packets arriving on the Android TUN interface.
 */
object NativeFilterMatcher {

    // Allowlist: domain -> note/rule description
    val activeAllowlist = ConcurrentHashMap<String, String>()

    // Blocklist: domain -> category/rule description
    val activeBlocklist = ConcurrentHashMap<String, String>()

    data class MatchResult(
        val isBlocked: Boolean,
        val matchedRule: String,
        val matchedDomain: String?
    )

    /**
     * Evaluates a domain against in-memory rule sets with strict allowlist precedence.
     */
    fun evaluate(rawDomain: String): MatchResult {
        val canonical = rawDomain.trim().lowercase()
        val hierarchy = getDomainHierarchy(canonical)

        // 1. STRICT ALLOWLIST PRECEDENCE:
        // If an exact domain or any parent domain is in the allowlist, allow it immediately!
        for (domainPart in hierarchy) {
            val rule = activeAllowlist[domainPart]
            if (rule != null) {
                return MatchResult(
                    isBlocked = false,
                    matchedRule = "Allowlist Precedence ($domainPart)",
                    matchedDomain = domainPart
                )
            }
        }

        // 2. BLOCKLIST CHECK:
        // If an exact domain or parent domain matches the blocklist, sinkhole it!
        for (domainPart in hierarchy) {
            val rule = activeBlocklist[domainPart]
            if (rule != null) {
                return MatchResult(
                    isBlocked = true,
                    matchedRule = rule.ifEmpty { "Blocklist ($domainPart)" },
                    matchedDomain = domainPart
                )
            }
        }

        // 3. CLEAN UPSTREAM:
        return MatchResult(
            isBlocked = false,
            matchedRule = "Upstream Resolver",
            matchedDomain = null
        )
    }

    private fun getDomainHierarchy(domain: String): List<String> {
        val parts = domain.split(".")
        if (parts.size <= 1) return listOf(domain)

        val hierarchy = mutableListOf<String>()
        for (i in 0..parts.size - 2) {
            hierarchy.add(parts.subList(i, parts.size).joinToString("."))
        }
        return hierarchy
    }

    fun syncRules(allowlist: Map<String, String>, blocklist: Map<String, String>) {
        activeAllowlist.clear()
        activeAllowlist.putAll(allowlist)

        activeBlocklist.clear()
        activeBlocklist.putAll(blocklist)
    }
}

