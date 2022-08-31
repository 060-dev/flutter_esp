import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_esp_method_channel.dart';

abstract class FlutterEspPlatform extends PlatformInterface {
  /// Constructs a FlutterEspPlatform.
  FlutterEspPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterEspPlatform _instance = MethodChannelFlutterEsp();

  /// The default instance of [FlutterEspPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterEsp].
  static FlutterEspPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterEspPlatform] when
  /// they register themselves.
  static set instance(FlutterEspPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
