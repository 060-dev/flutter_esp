import 'flutter_esp_platform_interface.dart';

class FlutterEsp {
  Future<void> create(CreateArguments args) {
    return FlutterEspPlatform.instance.createBluetoothDevice(args);
  }

  Future<List<GetNetworksResult>?> getAvailableNetworks() async {
    await FlutterEspPlatform.instance.connectBluetoothDevice();
    return FlutterEspPlatform.instance.getAvailableNetworks();
  }

  Future<void> provision(ProvisionArguments args) async {
    await FlutterEspPlatform.instance.provision(args);
  }
}
