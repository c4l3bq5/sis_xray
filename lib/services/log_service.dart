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
    print('📡 API Response [$endpoint]: ${response.statusCode}');
    print('📄 Body: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return json.decode(response.body);
      } catch (e) {
        print('❌ Error parseando JSON: $e');
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

      final uri = Uri.parse('$baseUrl/logs').replace(queryParameters: queryParams);
      print('🔍 GET: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getLogs');
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Error obteniendo logs: $e');
      rethrow;
    }
  }

  // Obtener estadísticas de logs
  Future<LogStats> getStats() async {
    try {
      print('🔍 Obteniendo estadísticas...');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/stats'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getStats');
      
      // Verificar si los datos están en 'data' o directamente en la respuesta
      final statsData = responseData['data'] ?? responseData;
      print('📊 Datos de estadísticas recibidos: $statsData');
      print('📊 Tipo de datos: ${statsData.runtimeType}');
      
      return LogStats.fromJson(statsData);
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  // Obtener resumen de acciones
  Future<Map<String, int>> getActionsSummary() async {
    try {
      print('🔍 Obteniendo resumen de acciones...');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/actions-summary'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getActionsSummary');
      
      print('📊 Respuesta completa: $responseData');
      print('📊 Tipo de respuesta: ${responseData.runtimeType}');
      
      // Verificar si los datos están en 'data' o directamente en la respuesta
      dynamic summaryData = responseData['data'] ?? responseData;
      print('📊 Summary data: $summaryData');
      print('📊 Tipo de summary data: ${summaryData.runtimeType}');
      
      // Si summaryData es una lista, convertirla a mapa
      if (summaryData is List) {
        print('⚠️ La respuesta es una lista, convirtiéndola a mapa...');
        final Map<String, int> result = {};
        
        for (var item in summaryData) {
          if (item is Map) {
            // Intentar extraer la acción y el conteo
            final accion = item['accion']?.toString() ?? 
                          item['action']?.toString() ?? 
                          item['nombre']?.toString() ??
                          'Desconocido';
            final count = _parseToInt(item['count'] ?? item['total'] ?? item['cantidad'] ?? 0);
            result[accion] = count;
          }
        }
        
        print('✅ Mapa convertido: $result');
        return result;
      }
      
      // Si es un mapa, convertir los valores a int
      if (summaryData is Map) {
        print('✅ La respuesta es un mapa, procesándolo...');
        return summaryData.map((key, value) => 
          MapEntry(key.toString(), _parseToInt(value))
        );
      }
      
      // Si no es ni lista ni mapa, retornar vacío
      print('⚠️ Formato inesperado, retornando mapa vacío');
      return {};
      
    } catch (e) {
      print('❌ Error obteniendo resumen: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Helper para convertir valores a int de forma segura
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Obtener actividad reciente
  Future<LogsResponse> getRecentActivity({int limit = 20}) async {
    try {
      print('🔍 Obteniendo actividad reciente...');
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/recent?limit=$limit'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getRecentActivity');
      print('📊 Respuesta actividad reciente: $responseData');
      print('📊 Tipo: ${responseData.runtimeType}');
      
      // Verificar estructura de la respuesta
      if (responseData is Map) {
        if (responseData.containsKey('data')) {
          print('✅ Datos en campo "data"');
        } else if (responseData is List) {
          print('⚠️ Respuesta es directamente una lista');
        }
      }
      
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Error obteniendo actividad reciente: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Obtener logs por usuario
  Future<LogsResponse> getLogsByUser(int usuarioId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/user/$usuarioId'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getLogsByUser');
      return LogsResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Error obteniendo logs del usuario: $e');
      rethrow;
    }
  }

  // Obtener log por ID
  Future<Log> getLogById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/logs/$id'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final responseData = _handleResponse(response, endpoint: 'getLogById');
      return Log.fromJson(responseData['data']);
    } catch (e) {
      print('❌ Error obteniendo log: $e');
      rethrow;
    }
  }
}