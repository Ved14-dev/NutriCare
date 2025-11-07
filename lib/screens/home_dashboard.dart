import 'package:flutter/material.dart';
import 'qr_code_screen.dart';
import '../backend/firestore_service.dart';

class HomeDashboard extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        // Use a simple color scheme
        final Color primaryColor = Colors.teal.shade600;
        final Color accentColor = Colors.white;
        final Color buttonColor = Colors.teal.shade700;
        final Color iconColor = Colors.white;

        return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
                title: Text('NutriCare'),
                backgroundColor: primaryColor,
                foregroundColor: accentColor,
                elevation: 0,
            ),
            body: LayoutBuilder(
                builder: (context, constraints) {
                    return SingleChildScrollView(
                        child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                                child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                            Container(
                                                decoration: BoxDecoration(
                                                    color: primaryColor,
                                                    borderRadius: BorderRadius.circular(24),
                                                    boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.black12,
                                                            blurRadius: 12,
                                                            offset: Offset(0, 6),
                                                        ),
                                                    ],
                                                ),
                                                padding: EdgeInsets.all(32),
                                                margin: EdgeInsets.only(bottom: 32),
                                                child: Column(
                                                    children: [
                                                        Icon(Icons.local_dining, size: 100, color: iconColor),
                                                        SizedBox(height: 12),
                                                        Text(
                                                            'Welcome to NutriCare',
                                                            style: TextStyle(
                                                                color: accentColor,
                                                                fontSize: 26,
                                                                fontWeight: FontWeight.bold,
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                            ...[
                                                {
                                                    'icon': Icons.restaurant,
                                                    'label': 'My Food Log',
                                                    'onPressed': () => Navigator.pushNamed(context, '/log'),
                                                },
                                                {
                                                    'icon': Icons.chat,
                                                    'label': 'Chat with Nutrition Bot',
                                                    'onPressed': () => Navigator.pushNamed(context, '/chat'),
                                                },
                                                {
                                                    'icon': Icons.qr_code,
                                                    'label': 'Nutritionist Access (QR)',
                                                    'onPressed': () {
                                                        Navigator.push(context, MaterialPageRoute(builder: (_) => QRCodeScreen()));
                                                    },
                                                },
                                                {
                                                    'icon': Icons.cloud_upload,
                                                    'label': 'Upload Food Data',
                                                    'onPressed': () async {
                                                        await FirestoreService.sendMockFoodData();
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Food data uploaded!')),
                                                        );
                                                    },
                                                },
                                            ].asMap().entries.map((entry) {
                                                int idx = entry.key;
                                                var btn = entry.value;
                                                return Padding(
                                                    padding: EdgeInsets.only(bottom: idx == 3 ? 0 : 20),
                                                    child: ElevatedButton.icon(
                                                        icon: Icon(btn['icon'] as IconData, color: iconColor, size: 32),
                                                        label: Padding(
                                                            padding: EdgeInsets.symmetric(vertical: 18),
                                                            child: Text(
                                                                btn['label'] as String,
                                                                style: TextStyle(
                                                                    fontSize: 20,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: iconColor,
                                                                ),
                                                            ),
                                                        ),
                                                        onPressed: btn['onPressed'] as void Function(),
                                                        style: ElevatedButton.styleFrom(
                                                            backgroundColor: buttonColor,
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(16),
                                                            ),
                                                            elevation: 4,
                                                            minimumSize: Size(double.infinity, 70),
                                                        ),
                                                    ),
                                                );
                                            }).toList(),
                                            Spacer(),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    );
                },
            ),
        );
    }
}
