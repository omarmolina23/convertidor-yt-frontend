import 'package:flutter_test/flutter_test.dart';

import 'package:convertidor_yt_frontend/models/conversion_models.dart';

void main() {
  group('ConversionRequest.toJson', () {
    test('incluye solo los campos presentes', () {
      final req = ConversionRequest(
        url: 'https://youtu.be/abc123',
        format: OutputFormat.mp3,
        quality: '192',
      );

      final json = req.toJson();

      expect(json['url'], 'https://youtu.be/abc123');
      expect(json['format'], 'MP3');
      expect(json['quality'], '192');
      expect(json.containsKey('startTime'), isFalse);
    });

    test('incluye el intervalo cuando se especifica', () {
      final req = ConversionRequest(
        url: 'https://youtu.be/abc123',
        format: OutputFormat.mp4,
        startTime: '00:30',
        endTime: '01:45',
      );

      final json = req.toJson();

      expect(json['startTime'], '00:30');
      expect(json['endTime'], '01:45');
    });
  });

  group('JobStatus.fromJson', () {
    test('parsea un estado READY', () {
      final status = JobStatus.fromJson({
        'jobId': 'job-1',
        'status': 'READY',
        'progress': 100,
        'fileName': 'video.mp3',
        'downloadUrl': '/api/v1/conversions/job-1/download',
      });

      expect(status.state, JobState.ready);
      expect(status.progress, 100);
      expect(status.fileName, 'video.mp3');
    });
  });
}
