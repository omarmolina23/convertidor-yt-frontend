import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ConvertidorApp());
}

class ConvertidorApp extends StatelessWidget {
  const ConvertidorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convertidor YouTube',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF0000)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
