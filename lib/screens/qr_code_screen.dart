
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_scaffold.dart';
import 'dart:convert';

class QRCodeScreen extends StatefulWidget {
    const QRCodeScreen({super.key});

    @override
    State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
    String? _qrData;
    bool _loading = true;
    String? _error;

    @override
    void initState() {
        super.initState();
        _fetchAllUserData();
    }

    dynamic _fixTimestamps(dynamic value) {
        if (value is Map) {
            return value.map((k, v) => MapEntry(k, _fixTimestamps(v)));
        } else if (value is List) {
            return value.map(_fixTimestamps).toList();
        } else if (value != null && value.runtimeType.toString() == 'Timestamp') {
            // Firestore Timestamp: convert to ISO8601 string
            return value.toDate().toIso8601String();
        }
        return value;
    }

    Future<void> _fetchAllUserData() async {
        try {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
                setState(() {
                    _error = 'Not logged in.';
                    _loading = false;
                });
                return;
            }
            final uid = user.uid;
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
            final profile = userDoc.data() ?? {};

            // Personal details (assume stored in user doc)
            final personalDetails = {
                'age': profile['age'],
                'height': profile['height'],
                'weight': profile['weight'],
                'bmi': profile['bmi'],
                'gender': profile['gender'],
            };

            // Food logs (last 10 for brevity)
            final foodLogsSnap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('food_logs')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .get();
            final foodLogs = foodLogsSnap.docs.map((d) => _fixTimestamps(d.data())).toList();

            // Hydration logs (last 7 days)
            final hydrationSnap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('hydration_logs')
                    .orderBy('date', descending: true)
                    .limit(7)
                    .get();
            final hydrationLogs = hydrationSnap.docs.map((d) => _fixTimestamps(d.data())).toList();

            // Compose all data
            final allData = {
                'profile': {
                    'name': profile['name'] ?? user.displayName,
                    'email': profile['email'] ?? user.email,
                    'uid': uid,
                },
                'personal_details': personalDetails,
                'food_logs': foodLogs,
                'hydration_logs': hydrationLogs,
            };

            final qrData = jsonEncode(_fixTimestamps(allData));
            setState(() {
                _qrData = qrData;
                _loading = false;
            });
        } catch (e) {
            setState(() {
                _error = 'Failed to load user data: $e';
                _loading = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return AppScaffold(
            title: 'Nutritionist Access',
            child: Center(
                child: _loading
                        ? const CircularProgressIndicator()
                        : _error != null
                                ? Text(_error!, style: const TextStyle(color: Colors.red))
                                : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Text('Show this QR to your nutritionist:', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 24),
                                            Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.surface,
                                                    borderRadius: BorderRadius.circular(16),
                                                    boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.06), blurRadius: 8)],
                                                ),
                                                child: QrImageView(
                                                    data: _qrData!,
                                                    version: QrVersions.auto,
                                                    size: 220.0,
                                                ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text('Scan with any QR scanner to get your nutrition data.', textAlign: TextAlign.center, style: GoogleFonts.inter()),
                                        ],
                                    ),
            ),
        );
    }
}
