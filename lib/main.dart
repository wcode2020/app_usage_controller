import 'package:flutter/material.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تقنين استخدام التطبيقات',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'Arial', // You can add Arabic fonts later
      ),
      home: const SettingsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

