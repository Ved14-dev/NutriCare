import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import '../widgets/app_scaffold.dart';

class QRCodeScreen extends StatelessWidget {
    const QRCodeScreen({super.key});

    @override
    Widget build(BuildContext context) {
        final token = Random().nextInt(999999).toString().padLeft(6, '0');
        final nutritionistId = 'NUT${Random().nextInt(9999).toString().padLeft(4, '0')}';
        final qrData = '{"token":"$token","nutritionistId":"$nutritionistId"}';

        return AppScaffold(
            title: 'Nutritionist Access',
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text('Show this QR to your nutritionist:', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.06), blurRadius: 8)]),
                            child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 220.0,
                            ),
                        ),
                        const SizedBox(height: 24),
                        Text('Token: $token\nNutritionist ID: $nutritionistId', textAlign: TextAlign.center, style: GoogleFonts.inter()),
                    ],
                ),
            ),
        );
    }
}
