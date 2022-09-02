import Flutter
import UIKit
import ESPProvision

public class SwiftFlutterEspPlugin: NSObject, FlutterPlugin {
    var bleDevices:[ESPDevice]?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_esp", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterEspPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      ESPProvisionManager.shared.searchESPDevices(devicePrefix: "PROV_", transport: .ble, security: .secure) {deviceList, error in
          DispatchQueue.main.async {
              result(deviceList?.map {$0.name}.joined(separator:", "))
          }
      }
  }
}
