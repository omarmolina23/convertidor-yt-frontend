import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Expone el idioma activo y los textos traducidos a todo el árbol de widgets.
///
/// Es un [InheritedWidget] colocado por encima de `CupertinoApp`, de modo que
/// cualquier widget puede leer los textos con `AppLocalizations.of(context)` y
/// cambiar el idioma con `setLocale`. Al cambiar el idioma, los widgets que
/// dependen de él se reconstruyen automáticamente.
class AppLocalizations extends InheritedWidget {
  const AppLocalizations({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  /// Idioma activo.
  final AppLocale locale;

  /// Cambia el idioma activo (lo gestiona el estado raíz de la app).
  final ValueChanged<AppLocale> setLocale;

  /// Textos traducidos del idioma activo.
  AppStrings get strings => AppStrings.of(locale);

  static AppLocalizations of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<AppLocalizations>();
    assert(result != null, 'No se encontró AppLocalizations en el contexto');
    return result!;
  }

  @override
  bool updateShouldNotify(AppLocalizations oldWidget) =>
      oldWidget.locale != locale;
}
