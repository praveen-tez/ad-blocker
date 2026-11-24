import 'package:flutter_test/flutter_test.dart';
import 'package:clearwave/core/filtering/domain_normalizer.dart';
import 'package:clearwave/core/filtering/filtering_engine.dart';
import 'package:clearwave/models/filter_rule.dart';

void main() {
  group('DomainNormalizer Tests', () {
    test('normalizes URLs and strips schemas, paths, ports, and queries', () {
      expect(
        DomainNormalizer.normalize('https://ads.example.com/path?query=1'),
        'ads.example.com',
      );
      expect(
        DomainNormalizer.normalize('http://tracker.io:8080/'),
        'tracker.io',
      );
      expect(
        DomainNormalizer.normalize('*.wildcard.domain.org.'),
        'wildcard.domain.org',
      );
      expect(
        DomainNormalizer.normalize('  SUB.UPPERCASE.COM  '),
        'sub.uppercase.com',
      );
    });

    test('validates valid and invalid domain strings', () {
      expect(DomainNormalizer.isValid('google.com'), isTrue);
      expect(DomainNormalizer.isValid('a.b.c.co.uk'), isTrue);
      expect(DomainNormalizer.isValid('not a domain'), isFalse);
      expect(DomainNormalizer.isValid('invalid_chars!.com'), isFalse);
      expect(DomainNormalizer.isValid(''), isFalse);
    });

    test('produces correct hierarchy for subdomain matching', () {
      final hierarchy = DomainNormalizer.getDomainHierarchy('a.b.c.example.com');
      expect(hierarchy, [
        'a.b.c.example.com',
        'b.c.example.com',
        'c.example.com',
        'example.com',
      ]);
    });
  });

  group('FilteringEngine & Precedence Tests', () {
    final now = DateTime.now();

    final activeAllowlist = <String, FilterRule>{
      'auth.mybank.com': FilterRule(
        id: 'al_1',
        domain: 'auth.mybank.com',
        type: RuleType.allow,
        addedAt: now,
      ),
      'apple.com': FilterRule(
        id: 'al_2',
        domain: 'apple.com',
        type: RuleType.allow,
        isWildcard: true,
        addedAt: now,
      ),
    };

    final activeBlocklist = <String, FilterRule>{
      'mybank.com': FilterRule(
        id: 'bl_bank',
        domain: 'mybank.com',
        type: RuleType.block,
        addedAt: now,
      ),
      'doubleclick.net': FilterRule(
        id: 'bl_1',
        domain: 'doubleclick.net',
        type: RuleType.block,
        categoryId: 'ads',
        isWildcard: true,
        addedAt: now,
      ),
      'pixel.facebook.com': FilterRule(
        id: 'bl_2',
        domain: 'pixel.facebook.com',
        type: RuleType.block,
        categoryId: 'trackers',
        isWildcard: true,
        addedAt: now,
      ),
      'advertising.apple.com': FilterRule(
        id: 'bl_apple_ad',
        domain: 'advertising.apple.com',
        type: RuleType.block,
        categoryId: 'ads',
        addedAt: now,
      ),
    };

    test('Rule matching: Blocks exact and subdomain matches of blocklist', () {
      final d1 = FilteringEngine.evaluateDomain(
        rawDomain: 'doubleclick.net',
        activeAllowlist: activeAllowlist,
        activeBlocklist: activeBlocklist,
      );
      expect(d1.isBlocked, isTrue);
      expect(d1.decisionType, DecisionType.categoryBlock);

      final d2 = FilteringEngine.evaluateDomain(
        rawDomain: 'sub.ads.doubleclick.net',
        activeAllowlist: activeAllowlist,
        activeBlocklist: activeBlocklist,
      );
      expect(d2.isBlocked, isTrue);
      expect(d2.decisionType, DecisionType.categoryBlock);
    });

    test('STRICT PRECEDENCE: Allowlist overrides blocklist even if parent domain is blocked', () {
      // 'mybank.com' is in blocklist, BUT 'auth.mybank.com' is in allowlist!
      final decision = FilteringEngine.evaluateDomain(
        rawDomain: 'auth.mybank.com',
        activeAllowlist: activeAllowlist,
        activeBlocklist: activeBlocklist,
      );
      expect(decision.isBlocked, isFalse);
      expect(decision.decisionType, DecisionType.allowlistPrecedence);
      expect(decision.matchedDomain, 'auth.mybank.com');
    });

    test('STRICT PRECEDENCE: Wildcard allowlist overrides blocklist subdomains', () {
      // 'advertising.apple.com' is in blocklist, BUT 'apple.com' is wildcard in allowlist!
      final decision = FilteringEngine.evaluateDomain(
        rawDomain: 'advertising.apple.com',
        activeAllowlist: activeAllowlist,
        activeBlocklist: activeBlocklist,
      );
      expect(decision.isBlocked, isFalse);
      expect(decision.decisionType, DecisionType.allowlistPrecedence);
      expect(decision.matchedDomain, 'apple.com');
    });

    test('Upstream Fallback: Clean domains are passed upstream', () {
      final decision = FilteringEngine.evaluateDomain(
        rawDomain: 'https://en.wikipedia.org/wiki/DNS',
        activeAllowlist: activeAllowlist,
        activeBlocklist: activeBlocklist,
      );
      expect(decision.isBlocked, isFalse);
      expect(decision.decisionType, DecisionType.upstreamAllowed);
      expect(decision.canonicalDomain, 'en.wikipedia.org');
    });
  });
}
