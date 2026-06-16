import 'package:flutter/cupertino.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ConvertidorApp());
}

class ConvertidorApp extends StatelessWidget {
  const ConvertidorApp({super.key});

  // Acento rojo sobrio (estilo YouTube) sobre el fondo agrupado de iOS.
  static const Color _accent = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Convertidor YouTube',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: _accent,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: HomeScreen(),
    );
  }
}
