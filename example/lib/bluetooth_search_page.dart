import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_esp/flutter_esp.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothSearchPage extends StatefulWidget {
  const BluetoothSearchPage({super.key});

  // Page url
  static const String url = '/ble';

  // Navigate to QR Code scan page
  static void go(BuildContext context) {
    Navigator.of(context).pushNamed(url);
  }

  @override
  State<BluetoothSearchPage> createState() => _BluetoothSearchPageState();
}

class _BluetoothSearchPageState extends State<BluetoothSearchPage> {
  // Text padding insets
  static const EdgeInsets _contentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  final _flutterEspPlugin = FlutterEsp();

  // Bluetooth search state
  List<String> _devices = [];
  String? _error;
  bool _loading = false;

  // Device name filter
  final String _prefix = 'PROV_';

  @override
  void initState() {
    super.initState();
    scan();
  }

  Future<void> scan() async {
    // Request location permission
    await Permission.locationWhenInUse.request();
    // Request bluetooth permission
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();

    setState(() {
      _loading = true;
    });

    List<String> devices = [];
    String? error;
    try {
      devices = await _flutterEspPlugin.searchBluetoothDevices() ?? [];
    } on PlatformException catch (e) {
      error = 'Failed to get devices: ${e.code} | ${e.message}';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _devices = devices;
      _error = error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Connect to Device'),
            leading: BackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: _contentPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Prefix: $_prefix',
                        ),
                      ),
                      const ElevatedButton(
                          onPressed: null, child: Text('Change'))
                    ],
                  ),
                ),
                const Padding(
                  padding: _contentPadding,
                  child: Text(
                    'To provision your new device, please make sure that your Phone\'s Bluetooth is turned on and within range of your new device.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(
                  height: 20,
                ),
                Padding(
                  padding: _contentPadding,
                  child: Text(
                    'Devices',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: _contentPadding,
                    child: Text(
                      _error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_devices[index]),
                          // title: Text(_devices[index].name),
                          // subtitle: Text(_devices[index].address),
                          // onTap: () =>
                          // _flutterEspPlugin.connect(_devices[index].address),
                        );
                      },
                    ),
                  ),
              ],
            ),
          )),
    );
  }
}
