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
  Future<void> connectBluetoothDevice(ConnectArguments args) => Future.value();
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
}
