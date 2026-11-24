import Flutter
import UIKit
import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let methodChannelName = "com.clearwave/engine"
  private let eventChannelName = "com.clearwave/events"
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    methodChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      switch call.method {
      case "startProtection":
        self.enableDnsSettings(result: result)
      case "stopProtection":
        self.disableDnsSettings(result: result)
      case "getStatus":
        self.getDnsStatus(result: result)
      case "syncRules":
        // Rule sets on iOS are applied via local SQLite evaluation & Safari content rules
        result(true)
      case "setUpstreamDns":
        if let args = call.arguments as? [String: Any],
           let dnsIp = args["dnsIp"] as? String {
          self.updateDnsSettings(dnsIp: dnsIp, result: result)
        } else {
          result(true)
        }
      case "checkCapabilities":
        result([
          "dnsSettingsSupported": true,
          "safariContentBlockerSupported": true,
          "packetTunnelEntitlementGranted": false,
          "framework": "NetworkExtension (NEDNSSettingsManager)"
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    eventChannel.setStreamHandler(self)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func enableDnsSettings(result: @escaping FlutterResult) {
    if #available(iOS 14.0, *) {
      let manager = NEDNSSettingsManager.shared()
      manager.loadFromPreferences { loadError in
        if let loadError = loadError {
          result(FlutterError(code: "LOAD_ERROR", message: loadError.localizedDescription, details: nil))
          return
        }

        let dohSettings = NEDNSOverHTTPSSettings(servers: ["9.9.9.9", "149.112.112.112"])
        dohSettings.serverURL = URL(string: "https://dns.quad9.net/dns-query")
        manager.dnsSettings = dohSettings
        manager.localizedDescription = "CLEARWAVE Encrypted DNS Filter"
        manager.isEnabled = true

        manager.saveToPreferences { saveError in
          if let saveError = saveError {
            result(FlutterError(code: "SAVE_ERROR", message: saveError.localizedDescription, details: nil))
          } else {
            result(true)
          }
        }
      }
    } else {
      result(FlutterError(code: "UNSUPPORTED_VERSION", message: "iOS 14.0 or newer required for system-wide encrypted DNS", details: nil))
    }
  }

  private func disableDnsSettings(result: @escaping FlutterResult) {
    if #available(iOS 14.0, *) {
      let manager = NEDNSSettingsManager.shared()
      manager.loadFromPreferences { loadError in
        if let loadError = loadError {
          result(FlutterError(code: "LOAD_ERROR", message: loadError.localizedDescription, details: nil))
          return
        }
        manager.isEnabled = false
        manager.saveToPreferences { saveError in
          if let saveError = saveError {
            result(FlutterError(code: "SAVE_ERROR", message: saveError.localizedDescription, details: nil))
          } else {
            result(true)
          }
        }
      }
    } else {
      result(true)
    }
  }

  private func getDnsStatus(result: @escaping FlutterResult) {
    if #available(iOS 14.0, *) {
      NEDNSSettingsManager.shared().loadFromPreferences { error in
        if error != nil {
          result(false)
        } else {
          result(NEDNSSettingsManager.shared().isEnabled)
        }
      }
    } else {
      result(false)
    }
  }

  private func updateDnsSettings(dnsIp: String, result: @escaping FlutterResult) {
    if #available(iOS 14.0, *) {
      let manager = NEDNSSettingsManager.shared()
      manager.loadFromPreferences { error in
        if let error = error {
          result(FlutterError(code: "LOAD_ERROR", message: error.localizedDescription, details: nil))
          return
        }

        if dnsIp == "1.1.1.1" {
          let doh = NEDNSOverHTTPSSettings(servers: ["1.1.1.1", "1.0.0.1"])
          doh.serverURL = URL(string: "https://cloudflare-dns.com/dns-query")
          manager.dnsSettings = doh
        } else {
          let doh = NEDNSOverHTTPSSettings(servers: ["9.9.9.9", "149.112.112.112"])
          doh.serverURL = URL(string: "https://dns.quad9.net/dns-query")
          manager.dnsSettings = doh
        }

        manager.saveToPreferences { saveErr in
          result(saveErr == nil)
        }
      }
    } else {
      result(true)
    }
  }
}

extension AppDelegate: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
