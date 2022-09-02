import 'package:flutter/material.dart';

import 'bluetooth_search_page.dart';
import 'home_page.dart';
import 'qrcode_scan_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter ESP Example', routes: {
      HomePage.url: (context) => const HomePage(),
      QRCodeScanPage.url: (context) => const QRCodeScanPage(),
      BluetoothSearchPage.url: (context) => const BluetoothSearchPage(),
    });
  }
}
