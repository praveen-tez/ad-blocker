import 'domain_normalizer.dart';
import '../../models/filter_rule.dart';

enum DecisionType {
  allowlistPrecedence,
  customBlock,
  categoryBlock,
  upstreamAllowed,
}

/// Evaluation result for a tested or queried domain.
class FilterDecision {
  final String queryDomain;
  final String canonicalDomain;
  final bool isBlocked;
  final DecisionType decisionType;
  final String matchedRule;
  final String? matchedDomain;
  final String? categoryId;

  const FilterDecision({
    required this.queryDomain,
    required this.canonicalDomain,
    required this.isBlocked,
    required this.decisionType,
    required this.matchedRule,
    this.matchedDomain,
    this.categoryId,
  });

  bool get isAllowed => !isBlocked;

  String get summaryLabel {
    switch (decisionType) {
      case DecisionType.allowlistPrecedence:
        return 'ALLOWED (Allowlist Precedence)';
      case DecisionType.customBlock:
        return 'BLOCKED (Custom Rule)';
      case DecisionType.categoryBlock:
        return 'BLOCKED (Filter Category)';
      case DecisionType.upstreamAllowed:
        return 'PASS (Allowed Upstream)';
    }
  }
}

/// Core DNS filtering logic engine for CLEARWAVE.
/// Enforces exact and subdomain wildcard matching with strict allowlist precedence.
class FilteringEngine {
  /// Evaluates an input domain against active allowlists and blocklists.
  ///
  /// Matching Algorithm:
  /// 1. Canonicalizes domain.
  /// 2. Generates hierarchy: e.g. 'sub.tracker.domain.com' -> ['sub.tracker.domain.com', 'tracker.domain.com', 'domain.com'].
  /// 3. Checks Allowlist hierarchy: If ANY parent or exact domain matches an active Allowlist rule,
  ///    it is immediately ALLOWED with allowlist precedence (even if present in blocklists).
  /// 4. Checks Blocklist hierarchy: If ANY parent or exact domain matches an active Blocklist rule,
  ///    it is BLOCKED with the corresponding rule / category origin.
  /// 5. If neither matches, ALLOWS and passes to Upstream DNS.
  static FilterDecision evaluateDomain({
    required String rawDomain,
    required Map<String, FilterRule> activeAllowlist,
    required Map<String, FilterRule> activeBlocklist,
  }) {
    final canonical = DomainNormalizer.normalize(rawDomain);
    if (canonical == null) {
      return FilterDecision(
        queryDomain: rawDomain,
        canonicalDomain: rawDomain.trim().toLowerCase(),
        isBlocked: false,
        decisionType: DecisionType.upstreamAllowed,
        matchedRule: 'Invalid domain syntax (Passed)',
      );
    }

    final hierarchy = DomainNormalizer.getDomainHierarchy(canonical);

    // 1. Check Allowlist Precedence (Exact and Subdomain matches)
    for (var i = 0; i < hierarchy.length; i++) {
      final domainPart = hierarchy[i];
      final allowRule = activeAllowlist[domainPart];

      if (allowRule != null && allowRule.isEnabled) {
        // If it's a parent domain, only match if wildcard enabled (default true)
        if (i == 0 || allowRule.isWildcard) {
          final isExact = (i == 0);
          return FilterDecision(
            queryDomain: rawDomain,
            canonicalDomain: canonical,
            isBlocked: false,
            decisionType: DecisionType.allowlistPrecedence,
            matchedDomain: domainPart,
            matchedRule: isExact
                ? 'Allowlist Precedence: Exact match (${allowRule.domain})'
                : 'Allowlist Precedence: Subdomain match via ${allowRule.domain}',
          );
        }
      }
    }

    // 2. Check Blocklist (Custom rules & Enabled categories)
    for (var i = 0; i < hierarchy.length; i++) {
      final domainPart = hierarchy[i];
      final blockRule = activeBlocklist[domainPart];

      if (blockRule != null && blockRule.isEnabled) {
        if (i == 0 || blockRule.isWildcard) {
          final isExact = (i == 0);
          final isCategory = blockRule.categoryId != null;

          return FilterDecision(
            queryDomain: rawDomain,
            canonicalDomain: canonical,
            isBlocked: true,
            decisionType: isCategory
                ? DecisionType.categoryBlock
                : DecisionType.customBlock,
            matchedDomain: domainPart,
            categoryId: blockRule.categoryId,
            matchedRule: isCategory
                ? 'Category [${blockRule.categoryId}]: ${isExact ? blockRule.domain : "Subdomain of ${blockRule.domain}"}'
                : 'Custom Block: ${isExact ? blockRule.domain : "Subdomain of ${blockRule.domain}"}',
          );
        }
      }
    }

    // 3. Fallback: Passed Upstream
    return FilterDecision(
      queryDomain: rawDomain,
      canonicalDomain: canonical,
      isBlocked: false,
      decisionType: DecisionType.upstreamAllowed,
      matchedRule: 'Clean (Passed to Upstream Resolver)',
    );
  }
}

