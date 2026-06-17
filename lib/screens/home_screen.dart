import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_strings.dart';
import '../models/conversion_models.dart';
import '../services/conversion_service.dart';
import '../services/file_downloader.dart';

/// Error de validación por campo. Se guarda como clave (no como texto) para que
/// el mensaje se re-traduzca solo si el usuario cambia de idioma.
enum _FieldError { enterLink, notYoutube, timeRequired, timeFormat }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ConversionService();

  final _urlController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  OutputFormat _format = OutputFormat.mp3;
  String _quality = '192';
  bool _useInterval = false;

  Timer? _pollTimer;
  JobStatus? _status;
  bool _submitting = false;
  String? _errorMessage;

  // Errores de validación por campo (estilo iOS: texto rojo bajo el campo).
  _FieldError? _urlError;
  _FieldError? _startError;
  _FieldError? _endError;

  static const Color _accent = Color(0xFFE53935);
  static const Color _fieldFill = Color(0xFFF2F2F7);
  static const Color _fieldBorder = Color(0xFFE0E0E5);
  static const Color _ink = Color(0xFF1C1C1E);
  static const Color _inkSoft = Color(0xFF6E6E73);

  static const _audioQualities = ['128', '192', '256', '320'];
  static const _videoQualities = ['480', '720', '1080'];

  @override
  void dispose() {
    _pollTimer?.cancel();
    _urlController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  AppStrings get _t => AppLocalizations.of(context).strings;

  List<String> get _qualities =>
      _format == OutputFormat.mp3 ? _audioQualities : _videoQualities;

  bool _validate() {
    _FieldError? urlErr;
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      urlErr = _FieldError.enterLink;
    } else if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      urlErr = _FieldError.notYoutube;
    }

    _FieldError? startErr;
    _FieldError? endErr;
    if (_useInterval) {
      startErr = _timeError(_startController.text);
      endErr = _timeError(_endController.text);
    }

    setState(() {
      _urlError = urlErr;
      _startError = startErr;
      _endError = endErr;
    });
    return urlErr == null && startErr == null && endErr == null;
  }

  _FieldError? _timeError(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return _FieldError.timeRequired;
    final regex = RegExp(r'^([0-9]{1,2}:)?[0-5]?[0-9]:[0-5][0-9]$');
    if (!regex.hasMatch(v)) return _FieldError.timeFormat;
    return null;
  }

  String _fieldErrorText(_FieldError error) {
    final t = _t;
    switch (error) {
      case _FieldError.enterLink:
        return t.errorEnterLink;
      case _FieldError.notYoutube:
        return t.errorNotYouTube;
      case _FieldError.timeRequired:
        return t.errorRequired;
      case _FieldError.timeFormat:
        return t.errorTimeFormat;
    }
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _status = null;
    });

    final request = ConversionRequest(
      url: _urlController.text.trim(),
      format: _format,
      quality: _quality,
      startTime: _useInterval ? _startController.text.trim() : null,
      endTime: _useInterval ? _endController.text.trim() : null,
    );

    try {
      final jobId = await _service.createJob(request);
      _startPolling(jobId);
    } on ConversionApiException catch (e) {
      setState(() {
        _submitting = false;
        _errorMessage = e.message;
      });
    }
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) async {
      try {
        final status = await _service.fetchStatus(jobId);
        if (!mounted) return;
        setState(() => _status = status);

        if (status.state == JobState.ready || status.state == JobState.failed) {
          _pollTimer?.cancel();
          setState(() {
            _submitting = false;
            if (status.state == JobState.failed) {
              _errorMessage = status.error ?? _t.conversionFailed;
            }
          });
        }
      } on ConversionApiException catch (e) {
        _pollTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _errorMessage = e.message;
        });
      }
    });
  }

  void _download() {
    final status = _status;
    if (status == null) return;
    triggerBrowserDownload(_service.downloadUrl(status),
        fileName: status.fileName);
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildLanguageButton(),
                  ),
                  const SizedBox(height: 8),
                  _buildHeader(t),
                  const SizedBox(height: 24),
                  _buildCard(t),
                  const SizedBox(height: 18),
                  _buildFooter(t),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton() {
    final current = AppLocalizations.of(context).locale;
    return GestureDetector(
      key: const Key('language-button'),
      onTap: _showLanguageOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _fieldBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.globe, size: 16, color: _inkSoft),
            const SizedBox(width: 6),
            Text(current.code,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(width: 2),
            const Icon(CupertinoIcons.chevron_down, size: 13, color: _inkSoft),
          ],
        ),
      ),
    );
  }

  void _showLanguageOptions() {
    FocusScope.of(context).unfocus();
    final loc = AppLocalizations.of(context);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(loc.strings.languageTitle),
        actions: AppLocale.values.map((option) {
          final selected = option == loc.locale;
          return CupertinoActionSheetAction(
            onPressed: () {
              loc.setLocale(option);
              Navigator.of(popupContext).pop();
            },
            child: selected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(option.nativeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: _accent)),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.checkmark,
                          size: 20, color: _accent),
                    ],
                  )
                : Text(option.nativeName),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(popupContext).pop(),
          child: Text(loc.strings.cancel),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings t) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(CupertinoIcons.play_fill,
              color: CupertinoColors.white, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          t.appTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
        ),
      ],
    );
  }

  Widget _buildCard(AppStrings t) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(t.linkLabel),
          const SizedBox(height: 8),
          _buildUrlField(t),
          const SizedBox(height: 20),
          _label(t.formatLabel),
          const SizedBox(height: 10),
          _buildFormatSelector(),
          const SizedBox(height: 20),
          _label(_format == OutputFormat.mp3
              ? t.audioQualityLabel
              : t.resolutionLabel),
          const SizedBox(height: 10),
          _buildQualitySelector(),
          const SizedBox(height: 14),
          _buildIntervalSection(t),
          const SizedBox(height: 22),
          _buildSubmitButton(t),
          _buildResultSection(t),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _inkSoft,
      ),
    );
  }

  BoxDecoration _fieldDecoration(bool hasError) {
    return BoxDecoration(
      color: _fieldFill,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: hasError ? CupertinoColors.systemRed : _fieldBorder,
        width: hasError ? 1.4 : 1,
      ),
    );
  }

  Widget _fieldError(_FieldError? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        _fieldErrorText(error),
        style: const TextStyle(fontSize: 12.5, color: CupertinoColors.systemRed),
      ),
    );
  }

  Widget _buildUrlField(AppStrings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          placeholder: t.linkPlaceholder,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          style: const TextStyle(color: _ink),
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.link,
                size: 20, color: CupertinoColors.systemGrey),
          ),
          decoration: _fieldDecoration(_urlError != null),
          onChanged: (_) {
            if (_urlError != null) setState(() => _urlError = null);
          },
        ),
        _fieldError(_urlError),
      ],
    );
  }

  Widget _buildFormatSelector() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<OutputFormat>(
        groupValue: _format,
        backgroundColor: _fieldFill,
        thumbColor: CupertinoColors.white,
        padding: const EdgeInsets.all(4),
        children: {
          OutputFormat.mp3: _segment(CupertinoIcons.music_note, 'MP3'),
          OutputFormat.mp4: _segment(CupertinoIcons.film, 'MP4'),
        },
        onValueChanged: (value) {
          if (value == null) return;
          setState(() {
            _format = value;
            _quality = _qualities.first;
          });
        },
      ),
    );
  }

  Widget _segment(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: _ink),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    final text = _format == OutputFormat.mp3 ? '$_quality kbps' : '${_quality}p';
    return GestureDetector(
      onTap: _showQualityOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: _fieldDecoration(false),
        child: Row(
          children: [
            const Icon(CupertinoIcons.slider_horizontal_3,
                size: 20, color: CupertinoColors.systemGrey),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 16, color: _ink)),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_down,
                size: 18, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _showQualityOptions() {
    FocusScope.of(context).unfocus();
    final t = _t;
    final options = _qualities;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(
            _format == OutputFormat.mp3 ? t.audioQualityLabel : t.resolutionLabel),
        actions: options.map((q) {
          final selected = q == _quality;
          final label = _format == OutputFormat.mp3 ? '$q kbps' : '${q}p';
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _quality = q);
              Navigator.of(popupContext).pop();
            },
            child: selected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: _accent)),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.checkmark,
                          size: 20, color: _accent),
                    ],
                  )
                : Text(label),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(popupContext).pop(),
          child: Text(t.cancel),
        ),
      ),
    );
  }

  Widget _buildIntervalSection(AppStrings t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.intervalTitle,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    t.intervalSubtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: _useInterval,
              activeTrackColor: _accent,
              onChanged: (v) => setState(() {
                _useInterval = v;
                if (!v) {
                  _startError = null;
                  _endError = null;
                }
              }),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: _useInterval
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _timeField(_startController, t.startLabel,
                              '00:30', _startError)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _timeField(
                              _endController, t.endLabel, '01:45', _endError)),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _timeField(TextEditingController controller, String label, String hint,
      _FieldError? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: _inkSoft)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          padding: const EdgeInsets.all(12),
          style: const TextStyle(color: _ink),
          decoration: _fieldDecoration(error != null),
        ),
        _fieldError(error),
      ],
    );
  }

  Widget _buildSubmitButton(AppStrings t) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: _accent,
        disabledColor: const Color(0xFFEF9A9A),
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(vertical: 16),
        onPressed: _submitting ? null : _submit,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _submitting
              ? [
                  const CupertinoActivityIndicator(color: CupertinoColors.white),
                  const SizedBox(width: 10),
                  Text(t.processing,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.white)),
                ]
              : [
                  const Icon(CupertinoIcons.bolt_fill,
                      color: CupertinoColors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(t.convertButton,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.white)),
                ],
        ),
      ),
    );
  }

  Widget _buildResultSection(AppStrings t) {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: _ErrorBanner(message: _errorMessage!),
      );
    }

    final status = _status;
    if (status == null) return const SizedBox.shrink();

    if (status.state == JobState.ready) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: _SuccessCard(
          fileName: status.fileName ?? t.fileFallback,
          onDownload: _download,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _ProgressView(progress: status.progress, accent: _accent),
    );
  }

  Widget _buildFooter(AppStrings t) {
    return Text(
      t.footer,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11.5, color: CupertinoColors.systemGrey),
    );
  }
}

/// Progreso con tres fases: procesando, descargando (con %) y convirtiendo.
/// Cupertino no trae barra lineal, así que se dibuja una determinada custom y
/// se usa el spinner nativo para las fases sin porcentaje.
class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.progress, required this.accent});

  final int progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).strings;
    final bool determinate = progress > 0 && progress < 100;

    final String phase;
    if (progress <= 0) {
      phase = t.phaseProcessing;
    } else if (progress >= 100) {
      phase = t.phaseConverting;
    } else {
      phase = t.phaseDownloading;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (!determinate) ...[
                  const CupertinoActivityIndicator(radius: 8),
                  const SizedBox(width: 8),
                ],
                Text(phase,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            if (determinate)
              Text('$progress%',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: accent, fontSize: 14)),
          ],
        ),
        if (determinate) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    height: 8,
                    width: constraints.maxWidth,
                    color: const Color(0xFFE5E5EA),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress / 100),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Container(
                      height: 8,
                      width: constraints.maxWidth * value,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.fileName, required this.onDownload});

  final String fileName;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).strings;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F6EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: Color(0xFF34C759)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: const Color(0xFF34C759),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: onDownload,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.cloud_download_fill,
                      color: CupertinoColors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(t.downloadButton,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE7E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.exclamationmark_circle_fill,
              color: Color(0xFFFF3B30)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
  }
}
