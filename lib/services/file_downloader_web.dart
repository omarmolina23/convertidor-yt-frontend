import 'package:web/web.dart' as web;

/// Dispara la descarga del archivo en el navegador creando un enlace temporal.
/// El backend ya envía Content-Disposition: attachment, así que el navegador
/// guardará el archivo en lugar de abrirlo.
void triggerBrowserDownload(String url, {String? fileName}) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..download = fileName ?? '';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
