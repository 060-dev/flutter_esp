import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_esp/flutter_esp.dart';
import 'package:flutter_esp/flutter_esp_platform_interface.dart';
import 'package:flutter_esp/flutter_esp_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterEspPlatform
    with MockPlatformInterfaceMixin
    implements FlutterEspPlatform {
  @override
  Future<List<SearchResult>?> searchBluetoothDevices(
          [SearchArguments args = const SearchArguments()]) =>
      Future.value([const SearchResult(name: "name", id: "42")]);

  @override
  Future<void> connectBluetoothDevice(GetNetworksArguments args) =>
      Future.value();

  @override
  Future<List<GetNetworksResult>?> getAvailableNetworks(
          GetNetworksArguments args) =>
      Future.value([
        GetNetworksResult(
          ssid: "ssid",
          rssi: 42,
          auth: 1,
          bssid: Uint8List(1),
        ),
      ]);
}

void main() {
  final FlutterEspPlatform initialPlatform = FlutterEspPlatform.instance;

  test('$MethodChannelFlutterEsp is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterEsp>());
  });

  test('searchBluetoothDevices', () async {
    FlutterEsp flutterEspPlugin = FlutterEsp();
    MockFlutterEspPlatform fakePlatform = MockFlutterEspPlatform();
    FlutterEspPlatform.instance = fakePlatform;

    expect((await flutterEspPlugin.searchBluetoothDevices())?[0].id, '42');
  });

  test('getAvailableNetworks', () async {
    FlutterEsp flutterEspPlugin = FlutterEsp();
    MockFlutterEspPlatform fakePlatform = MockFlutterEspPlatform();
    FlutterEspPlatform.instance = fakePlatform;

    expect(
      (await flutterEspPlugin.getAvailableNetworks(
        const GetNetworksArguments(deviceId: "deviceId"),
      ))?[0]
          .ssid,
      'ssid',
    );
  });
}
