import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ConvertidorApp());
}

class ConvertidorApp extends StatelessWidget {
  const ConvertidorApp({super.key});

  // Paleta minimalista: superficies neutras claras + un acento rojo sobrio.
  static const Color _accent = Color(0xFFE53935);
  static const Color _surface = Color(0xFFF6F7F9);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.light,
    ).copyWith(surface: _surface);

    return MaterialApp(
      title: 'Convertidor YouTube',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _surface,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
