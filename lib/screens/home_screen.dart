import 'dart:async';

import 'package:flutter/material.dart';

import '../models/conversion_models.dart';
import '../services/conversion_service.dart';
import '../services/file_downloader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildCard(),
                  const SizedBox(height: 20),
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          'Convertidor YouTube',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Convierte cualquier video a MP3 o MP4',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUrlField(),
            const SizedBox(height: 22),
            _label('Formato'),
            const SizedBox(height: 10),
            _buildFormatSelector(),
            const SizedBox(height: 22),
            _label(_format == OutputFormat.mp3
                ? 'Calidad de audio'
                : 'Resolución'),
            const SizedBox(height: 10),
            _buildQualitySelector(),
            const SizedBox(height: 6),
            _buildIntervalSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        hintText: 'Pega el enlace de YouTube',
        prefixIcon: Icon(Icons.link_rounded),
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'Ingresa un enlace';
        if (!v.contains('youtube.com') && !v.contains('youtu.be')) {
          return 'Debe ser un enlace de YouTube';
        }
        return null;
      },
    );
  }

  Widget _buildFormatSelector() {
    return SegmentedButton<OutputFormat>(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        selectedForegroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      segments: const [
        ButtonSegment(
          value: OutputFormat.mp3,
          label: Text('MP3'),
          icon: Icon(Icons.music_note_rounded),
        ),
        ButtonSegment(
          value: OutputFormat.mp4,
          label: Text('MP4'),
          icon: Icon(Icons.movie_rounded),
        ),
      ],
      selected: {_format},
      onSelectionChanged: (selection) {
        setState(() {
          _format = selection.first;
          _quality = _qualities.first;
        });
      },
    );
  }

  Widget _buildQualitySelector() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_format),
      initialValue: _quality,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.tune_rounded),
      ),
      items: _qualities
          .map((q) => DropdownMenuItem(
                value: q,
                child: Text(_format == OutputFormat.mp3 ? '$q kbps' : '${q}p'),
              ))
          .toList(),
      onChanged: (value) => setState(() => _quality = value ?? _quality),
    );
  }

  Widget _buildIntervalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recortar por intervalo'),
                  Text(
                    'Descarga solo un tramo (MM:SS o HH:MM:SS)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Switch(
              value: _useInterval,
              onChanged: (v) => setState(() => _useInterval = v),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _useInterval
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startController,
                          decoration: const InputDecoration(
                            labelText: 'Inicio',
                            hintText: '00:30',
                          ),
                          validator: _validateTime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _endController,
                          decoration: const InputDecoration(
                            labelText: 'Fin',
                            hintText: '01:45',
                          ),
                          validator: _validateTime,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String? _validateTime(String? value) {
    if (!_useInterval) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Requerido';
    final regex = RegExp(r'^([0-9]{1,2}:)?[0-5]?[0-9]:[0-5][0-9]$');
    if (!regex.hasMatch(v)) return 'MM:SS o HH:MM:SS';
    return null;
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _submitting ? null : _submit,
        style: FilledButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.bolt_rounded),
        label: Text(_submitting ? 'Procesando…' : 'Convertir'),
      ),
    );
  }

  Widget _buildResultSection() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: _ErrorBanner(message: _errorMessage!),
      );
    }

    final status = _status;
    if (status == null) return const SizedBox.shrink();

    if (status.state == JobState.ready) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: _SuccessCard(
          fileName: status.fileName ?? 'archivo',
          onDownload: _download,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _ProgressView(progress: status.progress),
    );
  }

  Widget _buildFooter() {
    return Text(
      'Solo para contenido propio, de dominio público o con licencia.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
    );
  }
}

/// Vista de progreso con tres fases: procesando, descargando (con %) y convirtiendo.
class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            Text(phase, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (determinate)
              Text('$progress%',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: scheme.primary)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: determinate
              // Barra determinada que se anima suave entre lecturas.
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress / 100),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                  ),
                )
              // Indeterminada mientras no hay % (procesando o convirtiendo).
              : LinearProgressIndicator(
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                ),
        ),
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
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
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
            height: 48,
            child: FilledButton.icon(
              onPressed: onDownload,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Descargar archivo'),
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
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828)),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(message, style: const TextStyle(color: Color(0xFFB71C1C))),
          ),
        ],
      ),
    );
  }
}
