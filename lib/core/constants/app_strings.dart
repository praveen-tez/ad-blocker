/// App-wide string constants and transparent product disclosures.
class AppStrings {
  AppStrings._();

  static const String appName = 'CLEARWAVE';
  static const String appTagline = 'Private, on-device ad & tracker blocking';

  // Disclosures & Stage 1 Notices
  static const String stage1NoticeTitle = 'Stage 1 — Foundation Preview';
  static const String stage1NoticeBody =
      'Native VPN/DNS engines will be integrated in Stage 3 (Android) and Stage 4 (iOS). '
      'Displayed metrics and engine toggles are currently operating in Foundation Preview mode.';
  static const String simulationNotice = 'Preview Telemetry';

  // Principles
  static const String privacyPromise =
      'Zero traffic inspection. No HTTPS decryption or custom certificate installation. '
      'All DNS decisions occur locally on your device.';
  static const String streamingDisclaimer =
      'DNS-level filtering cannot decouple server-stitched video advertisements (e.g., YouTube) '
      'from primary streams without breaking playback. Third-party ad trackers and web ads are blocked.';
}

