import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_esp/flutter_esp.dart';
import 'package:flutter_esp/flutter_esp_platform_interface.dart';
import 'package:flutter_esp_example/network_selection_page.dart';
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

// Text padding insets
const EdgeInsets _contentPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 8,
);

class _BluetoothSearchPageState extends State<BluetoothSearchPage> {
  final _flutterEspPlugin = FlutterEsp();

  // Bluetooth search state
  _ScanState state = _ScanState.loading();

  // Device name filter
  String _prefix = 'PROV_';
  String? _pop;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    // Request location permission
    await Permission.locationWhenInUse.request();
    // Request bluetooth permission
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();

    setState(() {
      state = _ScanState.loading();
    });

    List<SearchResult> devices = [];
    String? error;
    try {
      devices = await _flutterEspPlugin
              .searchBluetoothDevices(SearchArguments(prefix: _prefix)) ??
          [];
    } on PlatformException catch (e) {
      error = 'Failed to get devices: ${e.code} | ${e.message}';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      state = _ScanState(
        devices: devices,
        error: error,
        loading: false,
      );
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
            actions: [
              IconButton(
                onPressed: state.loading ? null : _scan,
                icon: const Icon(Icons.refresh),
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DeviceList(
                    state: state,
                    onSelect: (id) => NetworkSelectionPage.go(
                      context,
                      NetworkSelectionPageArgs(
                        deviceId: id,
                        proofOfPossession: _pop,
                      ),
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Padding(
                  padding: _contentPadding,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Prefix Filter',
                      icon: Icon(Icons.filter_alt),
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _prefix,
                    onChanged: (value) {
                      _prefix = value;
                    },
                  ),
                ),
                Padding(
                  padding: _contentPadding,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Proof of Possession Key',
                      icon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _pop,
                    onChanged: (value) {
                      _pop = value;
                    },
                  ),
                ),
                const Padding(
                  padding: _contentPadding,
                  child: Text(
                    'To provision your new device, please make sure that your Phone\'s Bluetooth is turned on and within range of your new device.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          )),
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({super.key, required this.state, required this.onSelect});

  // Bluetooth search state
  final _ScanState state;
  // Callback for when a device is selected
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      return Center(
        child: Padding(
          padding: _contentPadding,
          child: Text(
            state.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    } else if (state.devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: _contentPadding,
          child: Text(
            'No devices found. Please, check the prefix filter below.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: state.devices.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(state.devices[index].name),
            subtitle: Text(state.devices[index].id),
            onTap: () => onSelect(state.devices[index].id),
          );
        },
      );
    }
  }
}

class _ScanState {
  final bool loading;
  final String? error;
  final List<SearchResult> devices;

  _ScanState(
      {required this.loading, required this.error, required this.devices});

  factory _ScanState.loading() =>
      _ScanState(loading: true, error: null, devices: []);
}
