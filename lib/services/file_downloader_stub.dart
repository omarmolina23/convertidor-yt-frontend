/// Implementación de respaldo para plataformas no-web (y para los tests en VM).
/// No realiza ninguna acción de navegador; simplemente está disponible para que
/// el código compile fuera de la web.
void triggerBrowserDownload(String url, {String? fileName}) {
  // No-op fuera del navegador. La app objetivo es Flutter Web.
}
