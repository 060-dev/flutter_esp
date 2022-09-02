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

  Future<List<SearchResult>?> searchBluetoothDevices(SearchArguments args) {
    throw UnimplementedError(
        'searchBluetoothDevices() has not been implemented.');
  }

  Future<void> connectBluetoothDevice(ConnectArguments args) {
    throw UnimplementedError(
        'connectBluetoothDevice() has not been implemented.');
  }
}

class SearchArguments {
  final String prefix;
  final bool secure;

  const SearchArguments({this.prefix = 'PROV', this.secure = true});

  Map<String, dynamic> toMap() {
    return {
      'prefix': prefix,
      'secure': secure,
    };
  }
}

class SearchResult {
  final String name;
  final String id;

  const SearchResult({required this.name, required this.id});

  factory SearchResult.fromMap(Map<Object?, Object?> map) {
    return SearchResult(
      name: map['name'] as String,
      id: map['id'] as String,
    );
  }
}

class ConnectArguments {
  final String deviceId;

  const ConnectArguments({required this.deviceId});

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
    };
  }
}
