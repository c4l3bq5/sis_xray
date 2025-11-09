// lib/services/log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/log_models.dart';
import 'auth_service.dart';

class LogService {
  static const String baseUrl =
      'https://api-med-op32.onrender.com/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response) {
    print(' API Response: ${response.statusCode}');
    print(' Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    switch (response.statusCode) {
      case 401:
        throw Exception('No autorizado. Por favor inicie sesión nuevamente');
      case 403:
        throw Exception('No tiene permisos para ver los logs');
      case 404:
        throw Exception('Logs no encontrados');
      case 500:
        throw Exception('Error interno del servidor');
      default:
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Error: ${response.statusCode}',
        );
    }
  }

  // Obtener logs con filtros opcionales
  Future<LogsResponse> getLogs({
    int? limit,
    int? offset,
    String? accion,
    int? usuarioId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final headers = await _getHeaders();

      // Construir query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (accion != null) queryParams['accion'] = accion;
      if (usuarioId != null) queryParams['usuario_id'] = usuarioId.toString();
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      final uri = Uri.parse(
        '$baseUrl/logs',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo logs: $e');
      rethrow;
    }
  }

  // Obtener estadísticas de logs
  Future<LogStats> getStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/stats'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return LogStats.fromJson(responseData['data']);
    } catch (e) {
      print(' Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  // Obtener resumen de acciones
  Future<Map<String, int>> getActionsSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/actions-summary'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Map<String, int>.from(responseData['data']);
    } catch (e) {
      print(' Error obteniendo resumen: $e');
      rethrow;
    }
  }

  // Obtener actividad reciente
  Future<LogsResponse> getRecentActivity({int limit = 20}) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/recent?limit=$limit'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo actividad reciente: $e');
      rethrow;
    }
  }

  // Obtener logs por usuario
  Future<LogsResponse> getLogsByUser(int usuarioId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/user/$usuarioId'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo logs del usuario: $e');
      rethrow;
    }
  }

  // Obtener log por ID
  Future<Log> getLogById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Log.fromJson(responseData['data']);
    } catch (e) {
      print(' Error obteniendo log: $e');
      rethrow;
    }
  }
}
