import 'package:flutter/material.dart';
import 'screens/home_dashboard.dart';
import 'screens/food_log.dart';
import 'screens/chat_page.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    // TODO: Initialize Firebase here
    runApp(NutriCareApp());
}

class NutriCareApp extends StatelessWidget {
    const NutriCareApp({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            title: 'NutriCare',
            theme: ThemeData(
                primarySwatch: Colors.green,
                visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            initialRoute: '/',
            routes: {
                '/': (context) => HomeDashboard(),
                '/log': (context) => FoodLog(),
                '/chat': (context) => ChatPage(),
            },
        );
    }
}
