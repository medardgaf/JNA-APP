import 'package:flutter/material.dart';
import 'screens/auth/login_pin_screen.dart';
import 'utils/colors.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KLIV',
      theme: ThemeData(
        primaryColor: KlivColors.primary,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LoginPinScreen(),
    );
  }
}
