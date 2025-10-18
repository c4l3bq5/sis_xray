// lib/services/patient_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_models.dart';
import 'auth_service.dart';

class PatientService {
  static const String baseUrl = 'https://apimed-production.up.railway.app/api';
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
    print('🔵 API Response: ${response.statusCode}');
    print('🔵 Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    switch (response.statusCode) {
      case 401:
        throw Exception('No autorizado. Por favor inicie sesión nuevamente');
      case 403:
        throw Exception('No tiene permisos para realizar esta acción');
      case 404:
        throw Exception('Paciente no encontrado');
      case 409:
        throw Exception('Ya existe un paciente con ese CI');
      case 500:
        throw Exception('Error interno del servidor');
      default:
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Error: ${response.statusCode}',
        );
    }
  }

  // Obtener lista de pacientes
  Future<PacientesResponse> getPacientes() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/patients'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return PacientesResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo pacientes: $e');
      rethrow;
    }
  }

  // Obtener estadísticas de pacientes
  Future<PacienteStats> getStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/patients/stats'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return PacienteStats.fromJson(responseData['data']);
    } catch (e) {
      print(' Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  // Buscar pacientes
  Future<PacientesResponse> searchPacientes(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/patients/search?q=$query'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return PacientesResponse.fromJson(responseData);
    } catch (e) {
      print(' Error buscando pacientes: $e');
      rethrow;
    }
  }

  // Obtener paciente por CI
  Future<Paciente> getPacienteByCI(String ci) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/patients/ci/$ci'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Paciente.fromJson(responseData['data']);
    } catch (e) {
      print(' Error obteniendo paciente: $e');
      rethrow;
    }
  }

  // Obtener paciente por ID
  Future<Paciente> getPacienteById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/patients/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Paciente.fromJson(responseData['data']);
    } catch (e) {
      print('❌ Error obteniendo paciente: $e');
      rethrow;
    }
  }

  // Crear paciente
  Future<Paciente> crearPaciente(Paciente paciente) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/patients'),
            headers: headers,
            body: json.encode(paciente.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Paciente.fromJson(responseData['data']);
    } catch (e) {
      print(' Error creando paciente: $e');
      rethrow;
    }
  }

  // Actualizar paciente
  Future<Paciente> actualizarPaciente(int id, Paciente paciente) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/patients/$id'),
            headers: headers,
            body: json.encode(paciente.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Paciente.fromJson(responseData['data']);
    } catch (e) {
      print(' Error actualizando paciente: $e');
      rethrow;
    }
  }

  // Desactivar paciente (solo admin)
  Future<bool> desactivarPaciente(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/patients/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print(' Error desactivando paciente: $e');
      rethrow;
    }
  }

  // Activar paciente (solo admin)
  Future<bool> activarPaciente(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(Uri.parse('$baseUrl/patients/$id/activate'), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print(' Error activando paciente: $e');
      rethrow;
    }
  }
}
