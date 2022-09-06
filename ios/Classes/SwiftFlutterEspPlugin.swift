import Flutter
import UIKit
import ESPProvision

// MARK: - ESPDevice extensions
extension ESPDevice: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension ESPDevice: Equatable {
    public static func ==(lhs: ESPDevice, rhs: ESPDevice) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

//  MARK: - Plugin inplementation
public class SwiftFlutterEspPlugin: NSObject, FlutterPlugin {
    var bleDevices: [String: ESPDevice]?
    
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
                result(FlutterError(code: "BAD_ARGUMENTS", message: nil, details: nil))
            }
            break
        case "connectBluetoothDevice":
            if let args = call.arguments as? Dictionary<String, Any>,
               let id = args["deviceId"] as? String
            {
                btConnect(result, id: id, pop: args["proofOfPossession"] as? String)
            }
            else{
                result(FlutterError(code: "BAD_ARGUMENTS", message: nil, details: nil))
            }
            break
        case "getAvailableNetworks":
            if let args = call.arguments as? Dictionary<String, Any>,
               let id = args["deviceId"] as? String
            {
                btGetNetworks(result, id: id)
            }
            else{
                result(FlutterError(code: "BAD_ARGUMENTS", message: nil, details: nil))
            }
            break
        case "provision":
            if let args = call.arguments as? Dictionary<String, Any>,
               let id = args["deviceId"] as? String,
               let ssid = args["ssid"] as? String
            {
                btProvision(result, id: id, ssid:ssid, passPhrase: args["password"] as? String)
            }
            break
        default: result(FlutterMethodNotImplemented)
            break
            
        }
        
    }
    
    private func btSearch(_ result: @escaping FlutterResult, prefix: String = "PROV_", secure: Bool = true){
        // TODO: detect if it is already connected to a device and if so, return error.
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: prefix, transport: .ble, security: secure ? .secure : .unsecure) {
            deviceList, error in
            if(error != nil){
                result(FlutterError(code: "SEARCH_ERROR", message: error?.description, details: nil))
            }
            self.bleDevices = deviceList?.reduce(into: [String: ESPDevice]()) {$0[String($1.hashValue)] = $1}
            result(deviceList?.map {["name": $0.name, "id": String($0.hashValue)]})
        }
    }
    
    private func btConnect(_ result: @escaping FlutterResult, id: String, pop: String?){
        if let device = bleDevices?[id]{
            device.connect(delegate: ConnectionHadler(pop: pop)) {
                status in
                switch status {
                case .connected:
                    result(id)
                    return
                case let .failedToConnect(error):
                    switch error {
                    case .securityMismatch, .versionInfoError:
                        result(FlutterError(code: "FAILED_TO_CONNECT", message: error.description, details: nil))
                        return
                    default:
                        result(FlutterError(code: "FAILED_TO_CONNECT_WITH_THIS_POP", message: error.description, details: nil))
                        return
                    }
                default:
                    result(FlutterError(code: "DEVICE_DISCONNECTED", message: nil, details: nil ))
                }
            }
        }else{
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: nil, details: nil))
        }
        
    }
    
    private func btGetNetworks(_ result: @escaping FlutterResult, id: String){
        if let device = bleDevices?[id]{
            device.scanWifiList(){
                networks,error in
                result(networks?.map{["ssid": $0.ssid, "rssi": $0.rssi, "auth": $0.auth.rawValue, "bssid": $0.bssid]})
            }
        }
    }
    
    private func btProvision(_ result: @escaping FlutterResult, id: String, ssid: String, passPhrase: String?){
        if let device = bleDevices?[id] {
            if(passPhrase != nil){
                device.provision(ssid: ssid, passPhrase: passPhrase!){
                    status in
                    switch status {
                    case .success:
                        result(nil)
                        return
                    case let .failure(error):
                        switch error {
                        case .wifiStatusAuthenticationError:
                            result(FlutterError(code: "WIFI_AUTHENTICATION_FAILED", message: nil, details: nil))
                            return
                        default:
                            result(FlutterError(code: "COULD_NOT_PROVISION", message: nil, details: nil))
                            return
                        }
                    default:
                        result(FlutterError(code: "COULD_NOT_PROVISION", message: nil, details: nil))
                        return
                    }
                }
            }else{
                device.provision(ssid: ssid){
                    status in
                    result(status)
                }
            }
        }
    }
}


// MARK: - Connection delegates
private class ConnectionHadler: ESPDeviceConnectionDelegate {
    var pop: String?
    
    init(pop: String?){
        self.pop = pop
    }
    public func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler(pop ?? "")
    }
}

