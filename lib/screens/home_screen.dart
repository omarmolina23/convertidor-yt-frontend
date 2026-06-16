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

  // Calidades disponibles según el formato.
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
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
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
      appBar: AppBar(
        title: const Text('Convertidor YouTube → MP3/MP4'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildUrlField(),
                      const SizedBox(height: 20),
                      _buildFormatSelector(),
                      const SizedBox(height: 20),
                      _buildQualitySelector(),
                      const SizedBox(height: 8),
                      _buildIntervalSection(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildResultSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      decoration: const InputDecoration(
        labelText: 'Enlace de YouTube',
        hintText: 'https://www.youtube.com/watch?v=...',
        prefixIcon: Icon(Icons.link),
        border: OutlineInputBorder(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Formato', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<OutputFormat>(
          segments: const [
            ButtonSegment(
              value: OutputFormat.mp3,
              label: Text('MP3'),
              icon: Icon(Icons.music_note),
            ),
            ButtonSegment(
              value: OutputFormat.mp4,
              label: Text('MP4'),
              icon: Icon(Icons.movie),
            ),
          ],
          selected: {_format},
          onSelectionChanged: (selection) {
            setState(() {
              _format = selection.first;
              _quality = _qualities.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQualitySelector() {
    final label =
        _format == OutputFormat.mp3 ? 'Bitrate (kbps)' : 'Resolución (p)';
    return DropdownButtonFormField<String>(
      // La key ligada al formato fuerza recrear el campo al cambiar MP3<->MP4,
      // así el valor inicial concuerda con la nueva lista de calidades.
      key: ValueKey(_format),
      initialValue: _quality,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.tune),
        border: const OutlineInputBorder(),
      ),
      items: _qualities
          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
          .toList(),
      onChanged: (value) => setState(() => _quality = value ?? _quality),
    );
  }

  Widget _buildIntervalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Descargar solo un intervalo'),
          subtitle: const Text('Recorta por tiempo (formato MM:SS o HH:MM:SS)'),
          value: _useInterval,
          onChanged: (v) => setState(() => _useInterval = v),
        ),
        if (_useInterval)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    labelText: 'Inicio',
                    hintText: '00:30',
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateTime,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String? _validateTime(String? value) {
    if (!_useInterval) return null;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Requerido';
    final regex = RegExp(r'^([0-9]{1,2}:)?[0-5]?[0-9]:[0-5][0-9]$');
    if (!regex.hasMatch(v)) return 'Formato MM:SS o HH:MM:SS';
    return null;
  }

  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: _submitting ? null : _submit,
      icon: _submitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      label: Text(_submitting ? 'Procesando...' : 'Convertir'),
    );
  }

  Widget _buildResultSection() {
    if (_errorMessage != null) {
      return _MessageBanner(
        icon: Icons.error_outline,
        color: Colors.red,
        text: _errorMessage!,
      );
    }

    final status = _status;
    if (status == null) return const SizedBox.shrink();

    if (status.state == JobState.ready) {
      return Column(
        children: [
          _MessageBanner(
            icon: Icons.check_circle_outline,
            color: Colors.green,
            text: '¡Listo! ${status.fileName ?? ''}',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.save_alt),
            label: const Text('Descargar archivo'),
          ),
        ],
      );
    }

    // PENDING o PROCESSING.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progreso: ${status.progress}%'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: status.progress > 0 ? status.progress / 100 : null,
        ),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
