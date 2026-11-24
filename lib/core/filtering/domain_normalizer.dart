/// Utility to validate and normalize domain names into canonical FQDNs.
class DomainNormalizer {
  DomainNormalizer._();

  static final RegExp _domainRegex = RegExp(
    r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}$',
  );

  /// Cleans and canonicalizes a user-input domain.
  /// Strips URL schemas (http://, https://), paths (/path), query parameters (?x=1),
  /// ports (:8080), leading/trailing whitespace, and trailing dots.
  static String? normalize(String rawInput) {
    var cleaned = rawInput.trim().toLowerCase();

    // Remove schema if present
    if (cleaned.startsWith('http://')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('https://')) {
      cleaned = cleaned.substring(8);
    }

    // Remove paths and query strings
    final slashIndex = cleaned.indexOf('/');
    if (slashIndex != -1) {
      cleaned = cleaned.substring(0, slashIndex);
    }

    final queryIndex = cleaned.indexOf('?');
    if (queryIndex != -1) {
      cleaned = cleaned.substring(0, queryIndex);
    }

    // Remove port numbers (e.g., example.com:443)
    final colonIndex = cleaned.indexOf(':');
    if (colonIndex != -1) {
      cleaned = cleaned.substring(0, colonIndex);
    }

    // Remove leading wildcard notation like *.example.com or .example.com
    if (cleaned.startsWith('*.')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('.')) {
      cleaned = cleaned.substring(1);
    }

    // Remove trailing dot if present (FQDN notation)
    if (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    cleaned = cleaned.trim();

    if (isValid(cleaned)) {
      return cleaned;
    }
    return null;
  }

  /// Checks if a normalized string is a valid domain name.
  static bool isValid(String domain) {
    if (domain.isEmpty || domain.length > 253) return false;
    return _domainRegex.hasMatch(domain);
  }

  /// Returns the domain and all its parent domains in hierarchy order.
  /// Example: 'sub.ads.example.com' -> ['sub.ads.example.com', 'ads.example.com', 'example.com']
  static List<String> getDomainHierarchy(String domain) {
    final parts = domain.split('.');
    if (parts.length <= 1) return [domain];

    final hierarchy = <String>[];
    for (var i = 0; i <= parts.length - 2; i++) {
      hierarchy.add(parts.sublist(i).join('.'));
    }
    return hierarchy;
  }
}

