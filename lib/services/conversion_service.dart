import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/conversion_models.dart';

/// Cliente HTTP que habla con el backend de conversión usando dio.
class ConversionService {
  ConversionService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ));

  final Dio _dio;

  /// Crea un trabajo de conversión y devuelve su id.
  Future<String> createJob(ConversionRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.conversionsPath,
        data: request.toJson(),
      );
      return response.data['jobId'] as String;
    } on DioException catch (e) {
      throw ConversionApiException(_messageFrom(e));
    }
  }

  /// Consulta el estado actual de un trabajo.
  Future<JobStatus> fetchStatus(String jobId) async {
    try {
      final response = await _dio.get('${ApiConfig.conversionsPath}/$jobId');
      return JobStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ConversionApiException(_messageFrom(e));
    }
  }

  /// URL absoluta para descargar el archivo listo.
  String downloadUrl(JobStatus status) {
    final path = status.downloadUrl ??
        '${ApiConfig.conversionsPath}/${status.jobId}/download';
    return '${ApiConfig.baseUrl}$path';
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Error de red desconocido';
  }
}

/// Excepción de capa de servicio con un mensaje listo para mostrar al usuario.
class ConversionApiException implements Exception {
  ConversionApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
