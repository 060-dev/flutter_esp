import 'flutter_esp_platform_interface.dart';

class FlutterEsp {
  Future<List<String>?> searchBluetoothDevices(
      [SearchArguments args = const SearchArguments()]) async {
    return FlutterEspPlatform.instance.searchBluetoothDevices(args);
  }

  Future<void> connectBluetoothDevice(ConnectArguments args) async {
    return FlutterEspPlatform.instance.connectBluetoothDevice(args);
  }
}
