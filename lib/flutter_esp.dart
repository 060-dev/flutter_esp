import 'flutter_esp_platform_interface.dart';

class FlutterEsp {
  Future<List<String>?> searchBluetoothDevices({
    String prefix = 'PROV_',
    bool secure = true,
  }) async {
    return FlutterEspPlatform.instance.searchBluetoothDevices();
  }
}
