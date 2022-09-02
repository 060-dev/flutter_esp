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
      switch call.method {
      case "searchBluetoothDevices":
          if let args = call.arguments as? Dictionary<String, Any>,
             let prefix = args["prefix"] as? String,
             let secure = args["secure"] as? Bool
          {
              btSearch(result, prefix: prefix, secure: secure)
          }else{
              result(FlutterError.init(code: "BAD_ARGUMENTS", message: nil, details: nil))
          }
          break
      default: result(FlutterMethodNotImplemented)
          break
          
      }
     
  }

    private func btSearch(_ result: @escaping FlutterResult, prefix: String = "PROV_", secure: Bool = true){
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: prefix, transport: .ble, security: secure ? .secure : .unsecure) {
            deviceList, error in
            DispatchQueue.main.async {
                result(deviceList?.map {$0.name})
            }
        }
    }
}
