/// Formato de salida soportado.
enum OutputFormat {
  mp3('MP3'),
  mp4('MP4');

  const OutputFormat(this.apiValue);

  /// Valor que espera el backend.
  final String apiValue;
}

/// Estado posible de un trabajo en el backend.
enum JobState { pending, processing, ready, failed, unknown }

JobState parseState(String? raw) {
  switch (raw) {
    case 'PENDING':
      return JobState.pending;
    case 'PROCESSING':
      return JobState.processing;
    case 'READY':
      return JobState.ready;
    case 'FAILED':
      return JobState.failed;
    default:
      return JobState.unknown;
  }
}

/// Petición de conversión que se envía al backend.
class ConversionRequest {
  ConversionRequest({
    required this.url,
    required this.format,
    this.quality,
    this.startTime,
    this.endTime,
  });

  final String url;
  final OutputFormat format;
  final String? quality;
  final String? startTime;
  final String? endTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'url': url,
      'format': format.apiValue,
    };
    if (quality != null && quality!.isNotEmpty) {
      map['quality'] = quality;
    }
    if (startTime != null && startTime!.isNotEmpty) {
      map['startTime'] = startTime;
    }
    if (endTime != null && endTime!.isNotEmpty) {
      map['endTime'] = endTime;
    }
    return map;
  }
}

/// Estado de un trabajo devuelto por el backend.
class JobStatus {
  JobStatus({
    required this.jobId,
    required this.state,
    required this.progress,
    this.fileName,
    this.downloadUrl,
    this.error,
  });

  final String jobId;
  final JobState state;
  final int progress;
  final String? fileName;
  final String? downloadUrl;
  final String? error;

  factory JobStatus.fromJson(Map<String, dynamic> json) {
    return JobStatus(
      jobId: json['jobId'] as String,
      state: parseState(json['status'] as String?),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      fileName: json['fileName'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      error: json['error'] as String?,
    );
  }
}
