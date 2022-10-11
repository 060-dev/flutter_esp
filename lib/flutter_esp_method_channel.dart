import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_esp_platform_interface.dart';

/// An implementation of [FlutterEspPlatform] that uses method channels.
class MethodChannelFlutterEsp extends FlutterEspPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_esp');

  @override
  Future<void> createBluetoothDevice(CreateArguments args) async {
    await methodChannel.invokeMethod<void>(
      'createBluetoothDevice',
      args.toMap(),
    );
  }

  @override
  Future<void> connectBluetoothDevice() async {
    await methodChannel.invokeMethod<void>(
      'connectBluetoothDevice',
    ) as String?;
  }

  @override
  Future<List<GetNetworksResult>?> getAvailableNetworks() async {
    final objects = await methodChannel.invokeMethod<List<Object?>>(
      'getAvailableNetworks',
    );

    if (objects == null) {
      return null;
    }

    final List<GetNetworksResult> result = [];

    for (final object in objects) {
      try {
        result.add(GetNetworksResult.fromMap(object as Map<Object?, Object?>));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }

    return result;
  }

  @override
  Future<void> provision(ProvisionArguments args) async {
    await methodChannel.invokeMethod(
      'provision',
      args.toMap(),
    );
  }
}
