import 'package:flutter/cupertino.dart';

import 'l10n/app_localizations.dart';
import 'l10n/app_strings.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ConvertidorApp());
}

class ConvertidorApp extends StatefulWidget {
  const ConvertidorApp({super.key});

  @override
  State<ConvertidorApp> createState() => _ConvertidorAppState();
}

class _ConvertidorAppState extends State<ConvertidorApp> {
  // Acento rojo sobrio (estilo YouTube) sobre el fondo agrupado de iOS.
  static const Color _accent = Color(0xFFE53935);

  // Idioma activo de la interfaz (por defecto, español).
  AppLocale _locale = AppLocale.es;

  @override
  Widget build(BuildContext context) {
    return AppLocalizations(
      locale: _locale,
      setLocale: (locale) => setState(() => _locale = locale),
      child: const CupertinoApp(
        title: 'Convertidor YouTube',
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: _accent,
          scaffoldBackgroundColor: Color(0xFFF2F2F7),
        ),
        home: HomeScreen(),
      ),
    );
  }
}
