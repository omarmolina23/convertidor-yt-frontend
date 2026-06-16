import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../models/conversion_models.dart';
import '../services/conversion_service.dart';
import '../services/file_downloader.dart';

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
  String? _urlError;
  String? _startError;
  String? _endError;

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

  List<String> get _qualities =>
      _format == OutputFormat.mp3 ? _audioQualities : _videoQualities;

  bool _validate() {
    String? urlErr;
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      urlErr = 'Ingresa un enlace';
    } else if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
      urlErr = 'Debe ser un enlace de YouTube';
    }

    String? startErr;
    String? endErr;
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

  String? _timeError(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Requerido';
    final regex = RegExp(r'^([0-9]{1,2}:)?[0-5]?[0-9]:[0-5][0-9]$');
    if (!regex.hasMatch(v)) return 'MM:SS o HH:MM:SS';
    return null;
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
              _errorMessage = status.error ?? 'La conversión falló';
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
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildCard(),
                  const SizedBox(height: 18),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
        const Text(
          'Convertidor YouTube',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Convierte cualquier video a MP3 o MP4',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
        ),
      ],
    );
  }

  Widget _buildCard() {
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
          _label('Enlace'),
          const SizedBox(height: 8),
          _buildUrlField(),
          const SizedBox(height: 20),
          _label('Formato'),
          const SizedBox(height: 10),
          _buildFormatSelector(),
          const SizedBox(height: 20),
          _label(_format == OutputFormat.mp3 ? 'Calidad de audio' : 'Resolución'),
          const SizedBox(height: 10),
          _buildQualitySelector(),
          const SizedBox(height: 14),
          _buildIntervalSection(),
          const SizedBox(height: 22),
          _buildSubmitButton(),
          _buildResultSection(),
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

  Widget _fieldError(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        error,
        style: const TextStyle(fontSize: 12.5, color: CupertinoColors.systemRed),
      ),
    );
  }

  Widget _buildUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          placeholder: 'Pega el enlace de YouTube',
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
    final options = _qualities;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        title: Text(
            _format == OutputFormat.mp3 ? 'Calidad de audio' : 'Resolución'),
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
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  Widget _buildIntervalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recortar por intervalo',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text(
                    'Descarga solo un tramo (MM:SS o HH:MM:SS)',
                    style: TextStyle(
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
                          child: _timeField(_startController, 'Inicio', '00:30',
                              _startError)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _timeField(
                              _endController, 'Fin', '01:45', _endError)),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _timeField(
      TextEditingController controller, String label, String hint, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: _inkSoft)),
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

  Widget _buildSubmitButton() {
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
              ? const [
                  CupertinoActivityIndicator(color: CupertinoColors.white),
                  SizedBox(width: 10),
                  Text('Procesando…',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.white)),
                ]
              : const [
                  Icon(CupertinoIcons.bolt_fill,
                      color: CupertinoColors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Convertir',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.white)),
                ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
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
          fileName: status.fileName ?? 'archivo',
          onDownload: _download,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _ProgressView(progress: status.progress, accent: _accent),
    );
  }

  Widget _buildFooter() {
    return const Text(
      'Solo para contenido propio, de dominio público o con licencia.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11.5, color: CupertinoColors.systemGrey),
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
    final bool determinate = progress > 0 && progress < 100;

    final String phase;
    if (progress <= 0) {
      phase = 'Procesando…';
    } else if (progress >= 100) {
      phase = 'Convirtiendo…';
    } else {
      phase = 'Descargando…';
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.cloud_download_fill,
                      color: CupertinoColors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Descargar archivo',
                      style: TextStyle(
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
