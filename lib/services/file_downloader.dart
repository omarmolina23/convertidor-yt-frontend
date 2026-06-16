// Selecciona la implementación adecuada según la plataforma de compilación.
// En web usa la API del navegador; en otras plataformas usa un stub seguro.
export 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';
