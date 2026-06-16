/// Configuración del endpoint del backend.
///
/// Se puede sobreescribir en tiempo de compilación:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String conversionsPath = '/api/v1/conversions';
}
