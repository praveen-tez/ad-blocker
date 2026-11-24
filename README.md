# CLEARWAVE — Cross-Platform On-Device Ad & Tracker Blocker

[![Flutter](https://img.shields.io/badge/Flutter-3.50.1-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.14.0-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20macOS-brightgreen)]()
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device%20DNS-success)]()

CLEARWAVE is a privacy-first, on-device ad and tracker protection application for Android and iOS. Built with a shared Flutter frontend, an on-device SQLite database, a high-performance native Kotlin `VpnService` DNS loopback engine on Android, and Apple's native `NEDNSSettingsManager` encrypted DNS engine on iOS.

---

## 1. Architectural Overview

```
+-----------------------------------------------------------------------------------+
|                                CLEARWAVE UI & STATE                               |
|   (Flutter / Dart — Obsidian & Neon Cyan Theme — No external backend dependencies)  |
|                                                                                   |
|  - Onboarding Tour        - Protection Dashboard        - Rules & Allowlist Mgr   |
|  - Domain Inspector Tool  - Upstream DNS Selector       - Streaming Limitations   |
+-----------------------------------------------------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                           LOCAL SQLite DATABASE LAYER                             |
|                        (clearwave.db via sqflite / ffi)                           |
|                                                                                   |
|  - filter_rules (exact + wildcard domain matching, is_blocked vs is_allowed)       |
|  - categories (Ads, Trackers, Telemetry, Malware, Social, Streaming)              |
|  - query_logs (On-device DNS audit trail with retention pruning)                  |
|  - settings (Key-value persistent configuration)                                  |
|                                                                                   |
|  * STRICT PRECEDENCE: Allowlist rules ALWAYS override blocklists *                |
+-----------------------------------------------------------------------------------+
                                          |
                +-------------------------+-------------------------+
                | MethodChannel & EventChannel: "com.clearwave/engine" |
                v                                                   v
+-----------------------------------+   +-------------------------------------------+
|          ANDROID ENGINE           |   |                iOS ENGINE                 |
|       (Kotlin VpnService)         |   |          (Swift NetworkExtension)         |
|                                   |   |                                           |
| • TUN Interface (10.222.0.1/32)   |   | • NEDNSSettingsManager:                   |
| • Captures ONLY Port 53 (DNS)     |   |   Public Apple API for system-wide DoH    |
| • Custom DnsPacketParser (IPv4)   |   |   (DNS-over-HTTPS Quad9 / Cloudflare)     |
| • Synthetic Sinkhole:             |   | • Safari Content Blocker:                 |
|   - A Queries -> 0.0.0.0          |   |   Compiled SFContentBlockerManager JSON   |
|   - AAAA Queries -> ::            |   | • Zero fake packet tunnel claims          |
| • Upstream Forwarding:            |   |   (Transparent capability detection)      |
|   Protected socket to Quad9/CF    |   +-------------------------------------------+
+-----------------------------------+
```

---

## 2. Core Privacy & Filtering Principles

1. **DNS-Level Filtering Only**:
   - CLEARWAVE intercepts and resolves DNS query names. It **never** intercepts HTTPS payload traffic, inspects packet contents, or prompts to install custom Root CA certificates.
2. **100% On-Device Processing**:
   - Zero browsing history or telemetry leaves the device. All logs and rules are stored in the local SQLite database.
3. **Strict Precedence**:
   - If a domain is on the allowlist (or matches an allowlist parent wildcard like `*.mybank.com`), it is **always allowed**, even if blocked by general rules like `doubleclick.net` or category filters.
4. **Transparent Streaming Disclosures**:
   - CLEARWAVE includes explicit technical documentation explaining why server-side ad insertion (SSAI) used by YouTube, Hulu, and Netflix cannot be separated from video content purely via DNS sinkholing without breaking playback.

---

## 3. Stages Implemented (End-to-End)

| Stage | Scope | Status | Notes |
|---|---|---|---|
| **Stage 1** | Foundation, UI, Theme, Navigation | **Completed** | Obsidian/cyan palette, dashboard, responsive cards, 0 analyzer issues |
| **Stage 2** | Local SQLite Database & Rules Engine | **Completed** | `clearwave.db`, exact & subdomain matching, allowlist precedence, live inspector |
| **Stage 3** | Android Native Engine (Kotlin) | **Completed** | `ClearwaveVpnService`, `DnsPacketParser`, synthetic 0.0.0.0 sinkhole, telemetry |
| **Stage 4** | iOS Implementation & Capabilities | **Completed** | `NEDNSSettingsManager` DoH/DoT, Safari Content Blocker JSON exporter |
| **Stage 5** | Integration, Verification & Tests | **Completed** | 19 automated tests passing across 4 test suites, 0 analyzer warnings |

---

## 4. How to Run & Verify

### A. Run Automated Tests & Static Analysis
```bash
# Analyze Dart code for syntax, types, and deprecations
flutter analyze

# Run all 19 automated unit, database, platform channel, and widget tests
flutter test test/filtering_test.dart test/database_test.dart test/native_platform_test.dart test/widget_test.dart
```

### B. Run on Android (Emulator or Physical Device)
1. Start an Android emulator (API level 24+) or connect a physical Android device with USB debugging enabled.
2. Execute:
   ```bash
   flutter run -d android
   ```
3. In the CLEARWAVE app:
   - Tap the central **Shield / Protection Switch**.
   - Android will display the standard system prompt: *"CLEARWAVE wants to set up a VPN connection..."*
   - Tap **OK / Allow**.
   - The engine status will turn to **ACTIVE (ON)** with a persistent foreground service notification in the status bar.
4. Verify DNS filtering in logcat:
   ```bash
   adb logcat -s ClearwaveVpn
   ```
   Open Chrome on the device and visit `https://doubleclick.net` or test an ad domain. Observe the logcat output:
   ```
   ClearwaveVpn: BLOCKED: doubleclick.net (matched blocklist)
   ```
   The domain resolves to `0.0.0.0` immediately without touching external networks!

### C. Run on iOS (Simulator or Physical Device)
1. Start the iOS Simulator (iOS 14.0+) or connect an iPhone:
   ```bash
   flutter run -d ios
   ```
2. In the CLEARWAVE app:
   - Open **Settings & Engine** > **Platform Capabilities & iOS Export**.
   - Tap **Check Capabilities** to view the runtime capability report (`NEDNSSettingsManager` supported: `true`).
   - Tap **Safari JSON Rules** to inspect the compiled Apple Content Blocker JSON rule set.
   - Tap the central Protection switch to activate the system-wide DoH profile via `NEDNSSettingsManager.shared().saveToPreferences()`.

### D. Run on Desktop (macOS / Linux / Windows)
CLEARWAVE includes an integrated fallback simulation engine that allows full UI, database, rule management, and domain evaluation on desktop without requiring root or VPN tunnels:
```bash
flutter run -d macos
```
- Use the **Live Domain Inspector** on the dashboard to test any domain (e.g. `ad.doubleclick.net`, `auth.mybank.com`, `sub.example.org`) and watch the SQLite hierarchical evaluation engine trace its decision path in real time.

---

## 5. File Structure Reference

```
clearwave/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml                  # VpnService declarations & permissions
│       └── kotlin/com/clearwave/clearwave/
│           ├── MainActivity.kt                  # Platform channel bridge
│           └── vpn/
│               ├── ClearwaveVpnService.kt       # Native loopback TUN & upstream forwarder
│               ├── DnsPacketParser.kt           # RFC 1035 UDP/DNS parser & 0.0.0.0 synthesizer
│               └── NativeFilterMatcher.kt       # High-speed in-memory hierarchy matcher
├── ios/
│   └── Runner/
│       └── AppDelegate.swift                    # NEDNSSettingsManager & Safari rules exporter
├── lib/
│   ├── app.dart                                 # Root MaterialApp configuration
│   ├── main.dart                                # Database initialization and bootstrap
│   ├── core/
│   │   ├── constants/                           # AppColors and AppStrings
│   │   ├── database/                            # SQLite AppDatabase and DAOs
│   │   ├── filtering/                           # DomainNormalizer and FilteringEngine
│   │   ├── platform/                            # Native/Simulated platform channel interfaces
│   │   └── theme/                               # Obsidian & cyan dark theme
│   ├── features/
│   │   ├── dashboard/                           # Protection card, stats, live inspector
│   │   ├── rules/                               # Rule management, category toggles, search
│   │   ├── settings/                            # Upstream DNS, IPv6, iOS capability inspector
│   │   ├── streaming/                           # Technical disclosure on video SSAI
│   │   └── onboarding/                          # 4-step introduction tour
│   ├── models/                                  # Rule, Category, Stats, and DNS models
│   └── providers/                               # ProtectionController & ProtectionScope
└── test/
    ├── database_test.dart                       # SQLite schema, CRUD & DAO tests
    ├── filtering_test.dart                      # Exact, wildcard & strict precedence tests
    ├── native_platform_test.dart                # Android & iOS platform channel tests
    └── widget_test.dart                         # UI smoke & domain inspector widget tests
```
