enum ProtectionState {
  disabled,
  connecting,
  active,
  error,
}

extension ProtectionStateX on ProtectionState {
  bool get isActive => this == ProtectionState.active;
  bool get isConnecting => this == ProtectionState.connecting;
  bool get isDisabled => this == ProtectionState.disabled;
  bool get isError => this == ProtectionState.error;

  String get label {
    switch (this) {
      case ProtectionState.active:
        return 'Protected';
      case ProtectionState.connecting:
        return 'Starting...';
      case ProtectionState.disabled:
        return 'Unprotected';
      case ProtectionState.error:
        return 'Service Error';
    }
  }

  String get subtitle {
    switch (this) {
      case ProtectionState.active:
        return 'Local DNS firewall active (Preview Mode)';
      case ProtectionState.connecting:
        return 'Establishing local loopback filter';
      case ProtectionState.disabled:
        return 'Tap to enable on-device blocking';
      case ProtectionState.error:
        return 'Check system permissions & settings';
    }
  }
}
