import 'flutter_esp_platform_interface.dart';

class FlutterEsp {
  Future<void> create(CreateArguments args) {
    return FlutterEspPlatform.instance.createBluetoothDevice(args);
  }

  Future<void> connect() {
    return FlutterEspPlatform.instance.connectBluetoothDevice();
  }

  Future<void> disconnect() {
    return FlutterEspPlatform.instance.disconnectBluetoothDevice();
  }

  Future<List<GetNetworksResult>?> getAvailableNetworks() {
    return FlutterEspPlatform.instance.getAvailableNetworks();
  }

  Future<void> provision(ProvisionArguments args) {
    return FlutterEspPlatform.instance.provision(args);
  }
}
