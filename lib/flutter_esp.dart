
import 'flutter_esp_platform_interface.dart';

class FlutterEsp {
  Future<String?> getPlatformVersion() {
    return FlutterEspPlatform.instance.getPlatformVersion();
  }
}
