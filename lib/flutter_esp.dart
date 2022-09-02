import 'flutter_esp_platform_interface.dart';

class FlutterEsp {
  Future<List<String>?> getPlatformVersion() {
    return FlutterEspPlatform.instance.getPlatformVersion().then((value) {
      return value?.split(',');
    });
  }
}
