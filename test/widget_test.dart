import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:convertidor_yt_frontend/main.dart';

void main() {
  testWidgets('La pantalla principal muestra el formulario', (tester) async {
    await tester.pumpWidget(const ConvertidorApp());

    expect(find.text('Convertidor YouTube → MP3/MP4'), findsOneWidget);
    expect(find.text('Convertir'), findsOneWidget);
    expect(find.text('MP3'), findsOneWidget);
    expect(find.text('MP4'), findsOneWidget);
  });

  testWidgets('Validación: rechaza URL que no es de YouTube', (tester) async {
    await tester.pumpWidget(const ConvertidorApp());

    await tester.enterText(
        find.byType(TextFormField).first, 'https://example.com');
    await tester.tap(find.text('Convertir'));
    await tester.pump();

    expect(find.text('Debe ser un enlace de YouTube'), findsOneWidget);
  });
}
