import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_esp/flutter_esp.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _flutterEspPlugin = FlutterEsp();

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> scan() async {
    // Request location permission
    await Permission.locationWhenInUse.request();
    // Request bluetooth permission
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();

    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _flutterEspPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException catch (e) {
      platformVersion =
          'Failed to get platform version: ${e.code} | ${e.message}';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: scan,
          child: const Icon(Icons.bluetooth_searching),
        ),
      ),
    );
  }
}
