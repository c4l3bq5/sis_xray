// lib/services/log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/log_models.dart';
import 'auth_service.dart';

class LogService {
  static const String baseUrl = 'https://api-med-op32.onrender.com/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response, {String? endpoint}) {
    print(' API Response [$endpoint]: ${response.statusCode}');
    print(' Body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return json.decode(response.body);
      } catch (e) {
        print(' Error parseando JSON: $e');
        throw Exception('Error al procesar la respuesta del servidor');
      }
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
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'Error: ${response.statusCode}',
          );
        } catch (e) {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
    }
  }

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

      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (accion != null) queryParams['accion'] = accion;
      if (usuarioId != null) queryParams['usuario_id'] = usuarioId.toString();
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      final uri = Uri.parse('$baseUrl/logs').replace(queryParameters: queryParams);
      print(' GET: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getLogs');
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo logs: $e');
      rethrow;
    }
  }

  Future<LogStats> getStats() async {
    try {
      print(' Obteniendo estadísticas...');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/stats'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getStats');
      
      final statsData = responseData['data'] ?? responseData;
      print(' Datos de estadísticas recibidos: $statsData');
      print(' Tipo de datos: ${statsData.runtimeType}');
      
      return LogStats.fromJson(statsData);
    } catch (e) {
      print(' Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getActionsSummary() async {
    try {
      print(' Obteniendo resumen de acciones...');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/actions-summary'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getActionsSummary');
      
      print(' Respuesta completa: $responseData');
      print(' Tipo de respuesta: ${responseData.runtimeType}');
      
      dynamic summaryData = responseData['data'] ?? responseData;
      print(' Summary data: $summaryData');
      print(' Tipo de summary data: ${summaryData.runtimeType}');
      
      if (summaryData is List) {
        print(' La respuesta es una lista, convirtiéndola a mapa...');
        final Map<String, int> result = {};
        
        for (var item in summaryData) {
          if (item is Map) {
            final accion = item['accion']?.toString() ?? 
                          item['action']?.toString() ?? 
                          item['nombre']?.toString() ??
                          'Desconocido';
            final count = _parseToInt(item['count'] ?? item['total'] ?? item['cantidad'] ?? 0);
            result[accion] = count;
          }
        }
        
        print(' Mapa convertido: $result');
        return result;
      }
      
      if (summaryData is Map) {
        print(' La respuesta es un mapa, procesándolo...');
        return summaryData.map((key, value) => 
          MapEntry(key.toString(), _parseToInt(value))
        );
      }
      
      print(' Formato inesperado, retornando mapa vacío');
      return {};
      
    } catch (e) {
      print(' Error obteniendo resumen: $e');
      print(' Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<LogsResponse> getRecentActivity({int limit = 20}) async {
    try {
      print(' Obteniendo actividad reciente...');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/recent?limit=$limit'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getRecentActivity');
      print(' Respuesta actividad reciente: $responseData');
      print(' Tipo: ${responseData.runtimeType}');
      
      if (responseData is Map) {
        if (responseData.containsKey('data')) {
          print(' Datos en campo "data"');
        } else if (responseData is List) {
          print(' Respuesta es directamente una lista');
        }
      }
      
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo actividad reciente: $e');
      print(' Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<LogsResponse> getLogsByUser(int usuarioId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/user/$usuarioId'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getLogsByUser');
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo logs del usuario: $e');
      rethrow;
    }
  }

  Future<Log> getLogById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/$id'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getLogById');
      return Log.fromJson(responseData['data']);
    } catch (e) {
      print(' Error obteniendo log: $e');
      rethrow;
    }
  }
}