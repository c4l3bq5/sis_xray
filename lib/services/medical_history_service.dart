// lib/services/medical_history_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medical_history_models.dart';
import '../models/patient_models.dart'; // ← Usar tu modelo existente
import 'auth_service.dart';

class MedicalHistoryService {
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
    print('API Response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    switch (response.statusCode) {
      case 400:
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Solicitud incorrecta');
      case 401:
        throw Exception('No autorizado - Sesión expirada');
      case 403:
        throw Exception('No tiene permisos para esta acción');
      case 404:
        throw Exception('Recurso no encontrado');
      case 500:
        throw Exception('Error interno del servidor');
      default:
        throw Exception('Error: ${response.statusCode}');
    }
  }

  /// Obtener todos los pacientes (usando tu servicio existente)
  Future<List<Paciente>> getAllPatients() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/patients'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);

      if (responseData['data'] != null) {
        final List<dynamic> patientsJson = responseData['data'];
        return patientsJson.map((json) => Paciente.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error obteniendo pacientes: $e');
      rethrow;
    }
  }

  /// Obtener pacientes SIN historial clínico
  Future<List<Paciente>> getPatientsWithoutHistory() async {
    try {
      // Obtener todos los pacientes
      final allPatients = await getAllPatients();

      // Obtener todos los historiales
      final allHistories = await getAllMedicalHistories();

      // Obtener IDs de pacientes que YA tienen historial
      final patientIdsWithHistory = allHistories
          .map((history) => history.pacienteId)
          .toSet();

      // Filtrar pacientes sin historial y que estén activos
      final patientsWithoutHistory = allPatients.where((patient) {
        return patient.estaActivo &&
            patient.id != null &&
            !patientIdsWithHistory.contains(patient.id);
      }).toList();

      print('  Total pacientes: ${allPatients.length}');
      print(' Pacientes con historial: ${patientIdsWithHistory.length}');
      print('  Pacientes SIN historial: ${patientsWithoutHistory.length}');

      return patientsWithoutHistory;
    } catch (e) {
      print('Error obteniendo pacientes sin historial: $e');
      rethrow;
    }
  }

  /// Obtener todos los historiales clínicos
  Future<List<MedicalHistory>> getAllMedicalHistories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/medical-history'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);

      if (responseData['data'] != null) {
        final List<dynamic> historiesJson = responseData['data'];
        return historiesJson
            .map((json) => MedicalHistory.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error obteniendo historiales: $e');
      rethrow;
    }
  }

  /// Obtener historial clínico por ID de paciente
  Future<List<MedicalHistory>> getHistoryByPatient(int patientId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/medical-history/patient/$patientId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);

      if (responseData['data'] != null) {
        final List<dynamic> historiesJson = responseData['data'];
        return historiesJson
            .map((json) => MedicalHistory.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error obteniendo historial del paciente: $e');
      rethrow;
    }
  }

  /// Crear historial clínico
  Future<MedicalHistory> createMedicalHistory(
    CreateMedicalHistoryRequest request,
  ) async {
    try {
      print(' Creando historial clínico...');
      print('Datos: ${request.toJson()}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/medical-history'),
            headers: await _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);

      if (responseData['data'] != null) {
        print('  Historial clínico creado exitosamente');
        return MedicalHistory.fromJson(responseData['data']);
      }

      throw Exception('No se recibieron datos del historial creado');
    } catch (e) {
      print('  Error creando historial clínico: $e');
      rethrow;
    }
  }

  /// Actualizar historial clínico
  Future<MedicalHistory> updateMedicalHistory(
    int id,
    CreateMedicalHistoryRequest request,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/medical-history/$id'),
            headers: await _getHeaders(),
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);

      if (responseData['data'] != null) {
        return MedicalHistory.fromJson(responseData['data']);
      }

      throw Exception('No se recibieron datos del historial actualizado');
    } catch (e) {
      print('Error actualizando historial clínico: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/medical-history/stats'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return responseData['data'] ?? {};
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      rethrow;
    }
  }
}
