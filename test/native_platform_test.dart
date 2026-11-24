import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwave/core/platform/platform_channel_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeAndroidProtectionEngine Platform Channel Tests', () {
    const methodChannel = MethodChannel('com.clearwave/engine');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getStatus':
            return false;
          case 'startProtection':
            return true;
          case 'stopProtection':
            return true;
          case 'syncRules':
            return true;
          case 'setUpstreamDns':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('startProtection and stopProtection invoke native Android method channel', () async {
      final engine = NativeAndroidProtectionEngine();

      final started = await engine.startProtection();
      expect(started, isTrue);
      expect(log.any((call) => call.method == 'startProtection'), isTrue);

      final stopped = await engine.stopProtection();
      expect(stopped, isTrue);
      expect(log.any((call) => call.method == 'stopProtection'), isTrue);

      engine.dispose();
    });

    test('syncRules passes allowlist and blocklist to native Android engine', () async {
      final engine = NativeAndroidProtectionEngine();

      final synced = await engine.syncRules(
        allowlist: {'auth.mybank.com': 'Banking override'},
        blocklist: {'doubleclick.net': 'Category: Ads'},
      );

      expect(synced, isTrue);
      final syncCall = log.firstWhere((call) => call.method == 'syncRules');
      final args = syncCall.arguments as Map;
      expect(args['allowlist']['auth.mybank.com'], 'Banking override');
      expect(args['blocklist']['doubleclick.net'], 'Category: Ads');

      engine.dispose();
    });

    test('setUpstreamResolver translates resolver names to proper DNS IPs', () async {
      final engine = NativeAndroidProtectionEngine();

      await engine.setUpstreamResolver('Cloudflare 1.1.1.1');
      var call = log.firstWhere((c) => c.method == 'setUpstreamDns');
      expect((call.arguments as Map)['dnsIp'], '1.1.1.1');

      log.clear();
      await engine.setUpstreamResolver('Quad9 (Encrypted)');
      call = log.firstWhere((c) => c.method == 'setUpstreamDns');
      expect((call.arguments as Map)['dnsIp'], '9.9.9.9');

      engine.dispose();
    });
  });

  group('NativeIosProtectionEngine Platform Channel & Feasibility Tests', () {
    const methodChannel = MethodChannel('com.clearwave/engine');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getStatus':
            return false;
          case 'startProtection':
            return true;
          case 'stopProtection':
            return true;
          case 'syncRules':
            return true;
          case 'setUpstreamDns':
            return true;
          case 'checkCapabilities':
            return {
              'platform': 'iOS',
              'dnsSettingsSupported': true,
              'safariContentBlockerSupported': true,
              'packetTunnelEntitlementGranted': false,
              'framework': 'NetworkExtension (NEDNSSettingsManager)',
            };
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('NativeIosProtectionEngine lifecycle and capabilities inspection', () async {
      final engine = NativeIosProtectionEngine();

      final started = await engine.startProtection();
      expect(started, isTrue);
      expect(log.any((call) => call.method == 'startProtection'), isTrue);

      final caps = await engine.checkCapabilities();
      expect(caps['platform'], 'iOS');
      expect(caps['dnsSettingsSupported'], isTrue);
      expect(caps['packetTunnelEntitlementGranted'], isFalse);

      final stopped = await engine.stopProtection();
      expect(stopped, isTrue);
      expect(log.any((call) => call.method == 'stopProtection'), isTrue);

      engine.dispose();
    });
  });
}
