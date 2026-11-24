/// Simulated query log entry for Stage 1 telemetry preview.
class DnsLogEntry {
  final String domain;
  final bool isBlocked;
  final String matchedRule;
  final DateTime timestamp;
  final int latencyMs;

  const DnsLogEntry({
    required this.domain,
    required this.isBlocked,
    required this.matchedRule,
    required this.timestamp,
    required this.latencyMs,
  });

  static List<DnsLogEntry> mockFeed() {
    final now = DateTime.now();
    return [
      DnsLogEntry(
        domain: 'pagead2.googlesyndication.com',
        isBlocked: true,
        matchedRule: 'Category: Advertising',
        timestamp: now.subtract(const Duration(seconds: 14)),
        latencyMs: 1,
      ),
      DnsLogEntry(
        domain: 'graph.facebook.com',
        isBlocked: true,
        matchedRule: 'Category: Trackers',
        timestamp: now.subtract(const Duration(seconds: 32)),
        latencyMs: 1,
      ),
      DnsLogEntry(
        domain: 'api.github.com',
        isBlocked: false,
        matchedRule: 'Upstream Quad9 (Allowed)',
        timestamp: now.subtract(const Duration(seconds: 55)),
        latencyMs: 14,
      ),
      DnsLogEntry(
        domain: 'auth.mybank.com',
        isBlocked: false,
        matchedRule: 'Custom Allowlist (Precedence)',
        timestamp: now.subtract(const Duration(minutes: 2)),
        latencyMs: 18,
      ),
      DnsLogEntry(
        domain: 'track.mixpanel.com',
        isBlocked: true,
        matchedRule: 'Category: Trackers',
        timestamp: now.subtract(const Duration(minutes: 3)),
        latencyMs: 1,
      ),
    ];
  }
}
