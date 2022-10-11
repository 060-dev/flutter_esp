import 'package:flutter/foundation.dart';
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

  Future<void> createBluetoothDevice(CreateArguments args) {
    throw UnimplementedError(
        'searchBluetoothDevices() has not been implemented.');
  }

  Future<void> connectBluetoothDevice() {
    throw UnimplementedError(
        'connectBluetoothDevice() has not been implemented.');
  }

  Future<List<GetNetworksResult>?> getAvailableNetworks() {
    throw UnimplementedError(
        'getAvailableNetworks() has not been implemented.');
  }

  Future<void> provision(ProvisionArguments args) {
    throw UnimplementedError('provision() has not been implemented.');
  }
}

class CreateArguments {
  final String name;
  final String? pop;
  final bool? secure;

  const CreateArguments({required this.name, this.pop, this.secure = true});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pop': pop,
      'secure': secure,
    };
  }
}

class ProvisionArguments {
  final String ssid;
  final String? password;

  const ProvisionArguments({required this.ssid, this.password});

  Map<String, dynamic> toMap() {
    return {
      'ssid': ssid,
      'password': password,
    };
  }
}

class GetNetworksResult {
  final String ssid;
  final int rssi;
  final int auth;
  final Uint8List? bssid;

  const GetNetworksResult({
    required this.ssid,
    required this.rssi,
    required this.auth,
    this.bssid,
  });

  factory GetNetworksResult.fromMap(Map<Object?, Object?> map) {
    return GetNetworksResult(
      ssid: map['ssid'] as String,
      rssi: map['rssi'] as int,
      auth: map['auth'] as int,
      bssid: map['bssid'] as Uint8List?,
    );
  }

  String? getMacAddress() {
    return bssid?.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
  }
}
