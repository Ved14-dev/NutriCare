import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';

class QRCodeScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        final token = Random().nextInt(999999).toString().padLeft(6, '0');
        final nutritionistId = 'NUT${Random().nextInt(9999).toString().padLeft(4, '0')}';
        final qrData = '{"token":"$token","nutritionistId":"$nutritionistId"}';

        return Scaffold(
            appBar: AppBar(title: Text('Nutritionist Access QR')),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text('Show this QR to your nutritionist:', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 24),
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                        SizedBox(height: 24),
                        Text('Token: $token\nNutritionist ID: $nutritionistId', textAlign: TextAlign.center),
                    ],
                ),
            ),
        );
    }
}
