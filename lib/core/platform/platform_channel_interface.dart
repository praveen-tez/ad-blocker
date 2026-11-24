import 'dart:async';
import '../../models/protection_status.dart';
import '../../models/blocking_stats.dart';

/// Contract for native platform communication with Android VpnService and iOS NetworkExtension.
/// In Stage 1 Foundation, [SimulatedProtectionEngine] satisfies this interface
/// and provides clear disclosures that native filtering is pending Stage 3 & 4.
abstract class ProtectionPlatformInterface {
  Future<bool> initialize();
  Future<ProtectionState> getStatus();
  Future<bool> startProtection();
  Future<bool> stopProtection();
  Future<BlockingStats> getTelemetry();
  Stream<ProtectionState> get statusStream;
}

/// Stage 1 implementation: Simulates engine lifecycle states for UI validation
/// without claiming real network packet interception.
class SimulatedProtectionEngine implements ProtectionPlatformInterface {
  final _statusController = StreamController<ProtectionState>.broadcast();
  ProtectionState _state = ProtectionState.disabled;

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<ProtectionState> getStatus() async {
    return _state;
  }

  @override
  Future<bool> startProtection() async {
    _state = ProtectionState.connecting;
    _statusController.add(_state);

    await Future.delayed(const Duration(milliseconds: 600));

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
  Future<BlockingStats> getTelemetry() async {
    return BlockingStats.placeholder();
  }

  @override
  Stream<ProtectionState> get statusStream => _statusController.stream;

  void dispose() {
    _statusController.close();
  }
}

