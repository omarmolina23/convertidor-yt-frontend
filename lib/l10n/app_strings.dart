import 'package:flutter/foundation.dart';

/// Idiomas soportados por la interfaz.
///
/// [code] es la etiqueta corta para el botón (ES/EN/PT) y [nativeName] el
/// nombre del idioma en su propia lengua (lo habitual en selectores de idioma).
enum AppLocale {
  es('ES', 'Español'),
  en('EN', 'English'),
  pt('PT', 'Português');

  const AppLocale(this.code, this.nativeName);

  final String code;
  final String nativeName;
}

/// Conjunto inmutable de textos de la interfaz para un idioma concreto.
///
/// Se mantiene como tabla de constantes (una instancia por idioma) en vez de
/// usar `gen-l10n`/ARB para no añadir dependencias ni pasos de build: la app es
/// de una sola pantalla y el cambio de idioma es manual desde la UI.
@immutable
class AppStrings {
  const AppStrings({
    required this.appTitle,
    required this.subtitle,
    required this.linkLabel,
    required this.linkPlaceholder,
    required this.formatLabel,
    required this.audioQualityLabel,
    required this.resolutionLabel,
    required this.intervalTitle,
    required this.intervalSubtitle,
    required this.startLabel,
    required this.endLabel,
    required this.convertButton,
    required this.processing,
    required this.downloadButton,
    required this.cancel,
    required this.errorEnterLink,
    required this.errorNotYouTube,
    required this.errorRequired,
    required this.errorTimeFormat,
    required this.phaseProcessing,
    required this.phaseConverting,
    required this.phaseDownloading,
    required this.conversionFailed,
    required this.fileFallback,
    required this.footer,
    required this.languageTitle,
  });

  final String appTitle;
  final String subtitle;
  final String linkLabel;
  final String linkPlaceholder;
  final String formatLabel;
  final String audioQualityLabel;
  final String resolutionLabel;
  final String intervalTitle;
  final String intervalSubtitle;
  final String startLabel;
  final String endLabel;
  final String convertButton;
  final String processing;
  final String downloadButton;
  final String cancel;
  final String errorEnterLink;
  final String errorNotYouTube;
  final String errorRequired;
  final String errorTimeFormat;
  final String phaseProcessing;
  final String phaseConverting;
  final String phaseDownloading;
  final String conversionFailed;
  final String fileFallback;
  final String footer;
  final String languageTitle;

  static AppStrings of(AppLocale locale) => _byLocale[locale]!;

  static const Map<AppLocale, AppStrings> _byLocale = {
    AppLocale.es: _es,
    AppLocale.en: _en,
    AppLocale.pt: _pt,
  };

  static const AppStrings _es = AppStrings(
    appTitle: 'Convertidor YouTube',
    subtitle: 'Convierte cualquier video a MP3 o MP4',
    linkLabel: 'Enlace',
    linkPlaceholder: 'Pega el enlace de YouTube',
    formatLabel: 'Formato',
    audioQualityLabel: 'Calidad de audio',
    resolutionLabel: 'Resolución',
    intervalTitle: 'Recortar por intervalo',
    intervalSubtitle: 'Descarga solo un tramo (MM:SS o HH:MM:SS)',
    startLabel: 'Inicio',
    endLabel: 'Fin',
    convertButton: 'Convertir',
    processing: 'Procesando…',
    downloadButton: 'Descargar archivo',
    cancel: 'Cancelar',
    errorEnterLink: 'Ingresa un enlace',
    errorNotYouTube: 'Debe ser un enlace de YouTube',
    errorRequired: 'Requerido',
    errorTimeFormat: 'MM:SS o HH:MM:SS',
    phaseProcessing: 'Procesando…',
    phaseConverting: 'Convirtiendo…',
    phaseDownloading: 'Descargando…',
    conversionFailed: 'La conversión falló',
    fileFallback: 'archivo',
    footer: 'Solo para contenido propio, de dominio público o con licencia.',
    languageTitle: 'Idioma',
  );

  static const AppStrings _en = AppStrings(
    appTitle: 'YouTube Converter',
    subtitle: 'Convert any video to MP3 or MP4',
    linkLabel: 'Link',
    linkPlaceholder: 'Paste the YouTube link',
    formatLabel: 'Format',
    audioQualityLabel: 'Audio quality',
    resolutionLabel: 'Resolution',
    intervalTitle: 'Trim by interval',
    intervalSubtitle: 'Download only a segment (MM:SS or HH:MM:SS)',
    startLabel: 'Start',
    endLabel: 'End',
    convertButton: 'Convert',
    processing: 'Processing…',
    downloadButton: 'Download file',
    cancel: 'Cancel',
    errorEnterLink: 'Enter a link',
    errorNotYouTube: 'Must be a YouTube link',
    errorRequired: 'Required',
    errorTimeFormat: 'MM:SS or HH:MM:SS',
    phaseProcessing: 'Processing…',
    phaseConverting: 'Converting…',
    phaseDownloading: 'Downloading…',
    conversionFailed: 'Conversion failed',
    fileFallback: 'file',
    footer: 'Only for your own, public-domain, or licensed content.',
    languageTitle: 'Language',
  );

  static const AppStrings _pt = AppStrings(
    appTitle: 'Conversor YouTube',
    subtitle: 'Converta qualquer vídeo para MP3 ou MP4',
    linkLabel: 'Link',
    linkPlaceholder: 'Cole o link do YouTube',
    formatLabel: 'Formato',
    audioQualityLabel: 'Qualidade de áudio',
    resolutionLabel: 'Resolução',
    intervalTitle: 'Cortar por intervalo',
    intervalSubtitle: 'Baixe apenas um trecho (MM:SS ou HH:MM:SS)',
    startLabel: 'Início',
    endLabel: 'Fim',
    convertButton: 'Converter',
    processing: 'Processando…',
    downloadButton: 'Baixar arquivo',
    cancel: 'Cancelar',
    errorEnterLink: 'Insira um link',
    errorNotYouTube: 'Deve ser um link do YouTube',
    errorRequired: 'Obrigatório',
    errorTimeFormat: 'MM:SS ou HH:MM:SS',
    phaseProcessing: 'Processando…',
    phaseConverting: 'Convertendo…',
    phaseDownloading: 'Baixando…',
    conversionFailed: 'A conversão falhou',
    fileFallback: 'arquivo',
    footer: 'Apenas para conteúdo próprio, de domínio público ou licenciado.',
    languageTitle: 'Idioma',
  );
}
