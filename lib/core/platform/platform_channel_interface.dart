import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/protection_status.dart';
import '../../models/blocking_stats.dart';
import '../../models/dns_log_entry.dart';

/// Contract for native platform communication with Android VpnService and iOS NetworkExtension.
abstract class ProtectionPlatformInterface {
  Future<bool> initialize();
  Future<ProtectionState> getStatus();
  Future<bool> startProtection();
  Future<bool> stopProtection();
  Future<bool> syncRules({
    required Map<String, String> allowlist,
    required Map<String, String> blocklist,
  });
  Future<bool> setUpstreamResolver(String resolverName);
  Future<Map<String, dynamic>> checkCapabilities();
  Future<BlockingStats> getTelemetry();
  Stream<ProtectionState> get statusStream;
  Stream<DnsLogEntry> get dnsEventStream;

  static ProtectionPlatformInterface create() {
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return NativeAndroidProtectionEngine();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return NativeIosProtectionEngine();
      }
    }
    return SimulatedProtectionEngine();
  }
}

/// Real Android Native Engine using VpnService via MethodChannel and EventChannel.
class NativeAndroidProtectionEngine implements ProtectionPlatformInterface {
  static const MethodChannel _methodChannel = MethodChannel('com.clearwave/engine');
  static const EventChannel _eventChannel = EventChannel('com.clearwave/events');

  final _statusController = StreamController<ProtectionState>.broadcast();
  final _dnsEventController = StreamController<DnsLogEntry>.broadcast();
  StreamSubscription? _eventSubscription;
  ProtectionState _currentState = ProtectionState.disabled;

  @override
  Future<bool> initialize() async {
    try {
      final isRunning = await _methodChannel.invokeMethod<bool>('getStatus') ?? false;
      _currentState = isRunning ? ProtectionState.active : ProtectionState.disabled;
      _statusController.add(_currentState);

      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (data) {
          if (data is Map) {
            final entry = DnsLogEntry(
              domain: (data['domain'] as String?) ?? '',
              isBlocked: (data['isBlocked'] as bool?) ?? false,
              matchedRule: (data['matchedRule'] as String?) ?? '',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                (data['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
              ),
              latencyMs: (data['latencyMs'] as int?) ?? 1,
            );
            _dnsEventController.add(entry);
          }
        },
        onError: (err) {
          debugPrint('Error from native event stream: $err');
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error initializing NativeAndroidProtectionEngine: $e');
      return false;
    }
  }

  @override
  Future<ProtectionState> getStatus() async {
    try {
      final isRunning = await _methodChannel.invokeMethod<bool>('getStatus') ?? false;
      _currentState = isRunning ? ProtectionState.active : ProtectionState.disabled;
      return _currentState;
    } catch (e) {
      return _currentState;
    }
  }

  @override
  Future<bool> startProtection() async {
    try {
      _currentState = ProtectionState.connecting;
      _statusController.add(_currentState);

      final started = await _methodChannel.invokeMethod<bool>('startProtection') ?? false;
      _currentState = started ? ProtectionState.active : ProtectionState.disabled;
      _statusController.add(_currentState);
      return started;
    } catch (e) {
      debugPrint('Error starting native VPN service: $e');
      _currentState = ProtectionState.error;
      _statusController.add(_currentState);
      return false;
    }
  }

  @override
  Future<bool> stopProtection() async {
    try {
      final stopped = await _methodChannel.invokeMethod<bool>('stopProtection') ?? false;
      _currentState = ProtectionState.disabled;
      _statusController.add(_currentState);
      return stopped;
    } catch (e) {
      debugPrint('Error stopping native VPN service: $e');
      return false;
    }
  }

  @override
  Future<bool> syncRules({
    required Map<String, String> allowlist,
    required Map<String, String> blocklist,
  }) async {
    try {
      return await _methodChannel.invokeMethod<bool>('syncRules', {
            'allowlist': allowlist,
            'blocklist': blocklist,
          }) ??
          false;
    } catch (e) {
      debugPrint('Error syncing rules to native engine: $e');
      return false;
    }
  }

  @override
  Future<bool> setUpstreamResolver(String resolverName) async {
    String dnsIp = '9.9.9.9'; // Quad9
    if (resolverName.contains('1.1.1.1')) {
      dnsIp = '1.1.1.1'; // Cloudflare
    } else if (resolverName.contains('AdGuard')) {
      dnsIp = '94.140.14.14'; // AdGuard DNS
    }

    try {
      return await _methodChannel.invokeMethod<bool>('setUpstreamDns', {
            'dnsIp': dnsIp,
          }) ??
          false;
    } catch (e) {
      debugPrint('Error setting upstream DNS: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> checkCapabilities() async {
    return {
      'platform': 'Android',
      'engine': 'VpnService',
      'dnsFilteringSupported': true,
      'fullTrafficIntercept': false,
      'rootRequired': false,
    };
  }

  @override
  Future<BlockingStats> getTelemetry() async {
    return BlockingStats.placeholder();
  }

  @override
  Stream<ProtectionState> get statusStream => _statusController.stream;

  @override
  Stream<DnsLogEntry> get dnsEventStream => _dnsEventController.stream;

  void dispose() {
    _eventSubscription?.cancel();
    _statusController.close();
    _dnsEventController.close();
  }
}

/// Real iOS Native Engine using Apple NetworkExtension NEDNSSettingsManager.
class NativeIosProtectionEngine implements ProtectionPlatformInterface {
  static const MethodChannel _methodChannel = MethodChannel('com.clearwave/engine');

  final _statusController = StreamController<ProtectionState>.broadcast();
  final _dnsEventController = StreamController<DnsLogEntry>.broadcast();
  ProtectionState _currentState = ProtectionState.disabled;

  @override
  Future<bool> initialize() async {
    try {
      final isRunning = await _methodChannel.invokeMethod<bool>('getStatus') ?? false;
      _currentState = isRunning ? ProtectionState.active : ProtectionState.disabled;
      _statusController.add(_currentState);
      return true;
    } catch (e) {
      debugPrint('Error initializing NativeIosProtectionEngine: $e');
      return false;
    }
  }

  @override
  Future<ProtectionState> getStatus() async {
    try {
      final isRunning = await _methodChannel.invokeMethod<bool>('getStatus') ?? false;
      _currentState = isRunning ? ProtectionState.active : ProtectionState.disabled;
      return _currentState;
    } catch (e) {
      return _currentState;
    }
  }

  @override
  Future<bool> startProtection() async {
    try {
      _currentState = ProtectionState.connecting;
      _statusController.add(_currentState);

      final started = await _methodChannel.invokeMethod<bool>('startProtection') ?? false;
      _currentState = started ? ProtectionState.active : ProtectionState.disabled;
      _statusController.add(_currentState);
      return started;
    } catch (e) {
      debugPrint('Error enabling iOS DNS configuration: $e');
      _currentState = ProtectionState.error;
      _statusController.add(_currentState);
      return false;
    }
  }

  @override
  Future<bool> stopProtection() async {
    try {
      final stopped = await _methodChannel.invokeMethod<bool>('stopProtection') ?? false;
      _currentState = ProtectionState.disabled;
      _statusController.add(_currentState);
      return stopped;
    } catch (e) {
      debugPrint('Error disabling iOS DNS configuration: $e');
      return false;
    }
  }

  @override
  Future<bool> syncRules({
    required Map<String, String> allowlist,
    required Map<String, String> blocklist,
  }) async {
    try {
      return await _methodChannel.invokeMethod<bool>('syncRules', {
            'allowlist': allowlist,
            'blocklist': blocklist,
          }) ??
          true;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<bool> setUpstreamResolver(String resolverName) async {
    String dnsIp = '9.9.9.9';
    if (resolverName.contains('1.1.1.1')) {
      dnsIp = '1.1.1.1';
    } else if (resolverName.contains('AdGuard')) {
      dnsIp = '94.140.14.14';
    }

    try {
      return await _methodChannel.invokeMethod<bool>('setUpstreamDns', {
            'dnsIp': dnsIp,
          }) ??
          false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> checkCapabilities() async {
    try {
      final caps = await _methodChannel.invokeMethod<Map>('checkCapabilities');
      if (caps != null) {
        return Map<String, dynamic>.from(caps);
      }
    } catch (e) {
      debugPrint('checkCapabilities error: $e');
    }
    return {
      'platform': 'iOS',
      'dnsSettingsSupported': true,
      'framework': 'NetworkExtension (NEDNSSettingsManager)',
      'packetTunnelEntitlementGranted': false,
    };
  }

  @override
  Future<BlockingStats> getTelemetry() async {
    return BlockingStats.placeholder();
  }

  @override
  Stream<ProtectionState> get statusStream => _statusController.stream;

  @override
  Stream<DnsLogEntry> get dnsEventStream => _dnsEventController.stream;

  void dispose() {
    _statusController.close();
    _dnsEventController.close();
  }
}

/// Fallback Simulated Engine for Desktop and Automated Testing environments.
class SimulatedProtectionEngine implements ProtectionPlatformInterface {
  final _statusController = StreamController<ProtectionState>.broadcast();
  final _dnsEventController = StreamController<DnsLogEntry>.broadcast();
  ProtectionState _state = ProtectionState.disabled;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<ProtectionState> getStatus() async => _state;

  @override
  Future<bool> startProtection() async {
    _state = ProtectionState.connecting;
    _statusController.add(_state);

    await Future.delayed(const Duration(milliseconds: 300));

    _state = ProtectionState.active;
    _statusController.add(_state);
    return true;
  }

  @override
  Future<bool> stopProtection() async {
    _state = ProtectionState.disabled;
    _statusController.add(_state);
    return true;
  }

  @override
  Future<bool> syncRules({
    required Map<String, String> allowlist,
    required Map<String, String> blocklist,
  }) async =>
      true;

  @override
  Future<bool> setUpstreamResolver(String resolverName) async => true;

  @override
  Future<Map<String, dynamic>> checkCapabilities() async {
    return {
      'platform': 'Simulated / Host VM',
      'engine': 'Local In-Memory / SQLite Engine',
      'nativeBound': false,
    };
  }

  @override
  Future<BlockingStats> getTelemetry() async {
    return BlockingStats.placeholder();
  }

  @override
  Stream<ProtectionState> get statusStream => _statusController.stream;

  @override
  Stream<DnsLogEntry> get dnsEventStream => _dnsEventController.stream;

  void dispose() {
    _statusController.close();
    _dnsEventController.close();
  }
}
