import Flutter
import UIKit
import ESPProvision

public class SwiftFlutterEspPlugin: NSObject, FlutterPlugin {
    var espDevice: ESPDevice?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_esp", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterEspPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    //  MARK: - Method switch
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createBluetoothDevice":
            if let args = call.arguments as? Dictionary<String, Any>,
               let name = args["name"] as? String,
               let pop = args["pop"] as? String,
               let secure = args["secure"] as? Bool
            {
                btCreate(result, name: name, pop: pop, secure: secure)
            }else{
                result(FlutterError(code: "BAD_ARGUMENTS", message: nil, details: nil))
            }
            break
        case "connectBluetoothDevice":
            btConnect(result)
            break
        case "getAvailableNetworks":
            btGetNetworks(result)
            break
        case "provision":
            if let args = call.arguments as? Dictionary<String, Any>,
               let ssid = args["ssid"] as? String
            {
                btProvision(result, ssid:ssid, passPhrase: args["password"] as? String)
            }
            break
        default: result(FlutterMethodNotImplemented)
            break
            
        }
        
    }
    
    //  MARK: - Create
    private func btCreate(_ result: @escaping FlutterResult, name: String, pop: String, secure: Bool = true){
        ESPProvisionManager.shared.createESPDevice(deviceName: name, transport: .ble, security: secure ? .secure : .unsecure, proofOfPossession: pop) {
            device, error in
            if(device == nil){
                result(FlutterError(code: "CREATE_ERROR", message: "Device is nil" , details: nil))
                return
            } else if(error != nil){
                result(FlutterError(code: "CREATE_ERROR", message: error?.description, details: nil))
                return
            }else{
                self.espDevice = device
                result(nil)
            }
        }
    }
    //  MARK: - Connect
    private func btConnect(_ result: @escaping FlutterResult){
        if let device = self.espDevice{
            device.connect() {
                status in
                switch status {
                case .connected:
                    result(nil)
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
    //  MARK: - Get Networks
    private func btGetNetworks(_ result: @escaping FlutterResult){
        if let device = self.espDevice{
            device.scanWifiList(){
                networks,error in
                result(networks?.map{["ssid": $0.ssid, "rssi": $0.rssi, "auth": $0.auth.rawValue, "bssid": $0.bssid]})
            }
        }else{
            result(FlutterError(code: "DEVICE_NOT_FOUND", message: nil, details: nil))
        }
    }
    //  MARK: - Provision
    private func btProvision(_ result: @escaping FlutterResult, ssid: String, passPhrase: String?){
        if let device = self.espDevice {
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
                            result(FlutterError(code: "WIFI_AUTHENTICATION_FAILED", message: error.description, details: nil))
                            return
                        default:
                            result(FlutterError(code: "COULD_NOT_PROVISION", message: error.description, details: nil))
                            return
                        }
                    default:
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

