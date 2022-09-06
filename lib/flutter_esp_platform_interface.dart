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

  Future<List<SearchResult>?> searchBluetoothDevices(SearchArguments args) {
    throw UnimplementedError(
        'searchBluetoothDevices() has not been implemented.');
  }

  Future<void> connectBluetoothDevice(GetNetworksArguments args) {
    throw UnimplementedError(
        'connectBluetoothDevice() has not been implemented.');
  }

  Future<List<GetNetworksResult>?> getAvailableNetworks(
      GetNetworksArguments args) {
    throw UnimplementedError(
        'getAvailableNetworks() has not been implemented.');
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

class GetNetworksArguments {
  final String deviceId;
  final String? proofOfPossession;
  final bool secure;

  const GetNetworksArguments(
      {required this.deviceId, this.proofOfPossession, this.secure = true});

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'proofOfPossession': proofOfPossession,
      'secure': secure,
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
