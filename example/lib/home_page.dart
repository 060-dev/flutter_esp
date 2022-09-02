import 'package:flutter/material.dart';
import 'package:flutter_esp_example/qrcode_scan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Page url
  static const String url = '/';

  // Go to home page
  static void go(BuildContext context) {
    Navigator.of(context).pushNamed(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter ESP BLE Prov'),
      ),
      body: SafeArea(
        child: Center(
          child: ElevatedButton(
            onPressed: () => QRCodeScanPage.go(context),
            child: const Text('Provision New Device'),
          ),
        ),
      ),
    );
  }
}
