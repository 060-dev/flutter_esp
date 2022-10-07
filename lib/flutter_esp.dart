import 'flutter_esp_platform_interface.dart';

class FlutterEsp {
  Future<List<SearchResult>?> searchBluetoothDevices(
      [SearchArguments args = const SearchArguments()]) async {
    return FlutterEspPlatform.instance.searchBluetoothDevices(args);
  }

  Future<bool> create(CreateArguments args) async {
    return await FlutterEspPlatform.instance.createBluetoothDevice(args);
  }

  Future<List<GetNetworksResult>?> getAvailableNetworks(
      GetNetworksArguments args) async {
    await FlutterEspPlatform.instance.connectBluetoothDevice(args);
    return FlutterEspPlatform.instance
        .getAvailableNetworks(GetNetworksArguments(deviceId: args.deviceId));
  }

  Future<void> provision(ProvisionArguments args) async {
    await FlutterEspPlatform.instance.provision(args);
  }
}
