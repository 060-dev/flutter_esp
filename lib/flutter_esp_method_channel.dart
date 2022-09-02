import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_esp_platform_interface.dart';

/// An implementation of [FlutterEspPlatform] that uses method channels.
class MethodChannelFlutterEsp extends FlutterEspPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_esp');

  @override
  Future<List<String>?> searchBluetoothDevices(SearchArguments args) async {
    final objects = await methodChannel.invokeMethod<List<Object?>>(
      'searchBluetoothDevices',
      args.toMap(),
    );

    if (objects == null) {
      return null;
    }

    final List<String> result = [];

    for (final object in objects) {
      if (object is String) {
        result.add(object);
      }
    }

    return result;
  }

  @override
  Future<void> connectBluetoothDevice(ConnectArguments args) async {
    await methodChannel.invokeMethod<void>(
      'connectBluetoothDevice',
      args.toMap(),
    );
  }
}
