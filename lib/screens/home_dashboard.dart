import 'package:flutter/material.dart';
import 'qr_code_screen.dart';
import '../backend/firestore_service.dart';

class HomeDashboard extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('NutriCare')),
            body: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.local_dining, size: 80, color: Colors.green),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                            icon: Icon(Icons.restaurant),
                            label: Text('My Food Log'),
                            onPressed: () => Navigator.pushNamed(context, '/log'),
                            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 60)),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                            icon: Icon(Icons.chat),
                            label: Text('Chat with Nutrition Bot'),
                            onPressed: () => Navigator.pushNamed(context, '/chat'),
                            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 60)),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                            icon: Icon(Icons.qr_code),
                            label: Text('Nutritionist Access (QR)'),
                            onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => QRCodeScreen()));
                            },
                            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 60)),
                        ),
                        SizedBox(height: 32),
                        ElevatedButton.icon(
                            icon: Icon(Icons.cloud_upload),
                            label: Text('Upload Food Data'),
                            onPressed: () async {
                                await FirestoreService.sendMockFoodData();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Food data uploaded!')));
                            },
                            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 60)),
                        ),
                    ],
                ),
            ),
        );
    }
}
