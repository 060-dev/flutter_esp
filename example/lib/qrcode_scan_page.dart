import 'package:flutter/material.dart';
import 'package:flutter_esp_example/bluetooth_search_page.dart';

class QRCodeScanPage extends StatelessWidget {
  const QRCodeScanPage({super.key});

  // Page url
  static const String url = '/scan';

  // Navigate to QR Code scan page
  static void go(BuildContext context) {
    Navigator.of(context).pushNamed(url);
  }

  // Text padding insets
  static const EdgeInsets _textPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: Placeholder()),
            const SizedBox(height: 8.0),
            Padding(
              padding: _textPadding,
              child: Text(
                'Looking for QR Code',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: _textPadding,
              child: Text(
                'Please position the camera to point at the QR Code',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: _textPadding,
                child: OutlinedButton(
                  onPressed: () => BluetoothSearchPage.go(context),
                  child: const Text('I don\'t have a QR code'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
