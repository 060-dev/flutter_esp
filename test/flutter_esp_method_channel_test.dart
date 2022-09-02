import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_esp/flutter_esp_method_channel.dart';

void main() {
  MethodChannelFlutterEsp platform = MethodChannelFlutterEsp();
  const MethodChannel channel = MethodChannel('flutter_esp');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return ['42'];
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('searchBluetoothDevices', () async {
    expect(await platform.searchBluetoothDevices(), ['42']);
  });
}
