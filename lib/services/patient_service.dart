import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_models.dart';
import 'auth_service.dart';

class PatientService {
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

  Future<PacientesResponse> getPacientes({bool includeInactive = false}) async {
    try {
      final headers = await _getHeaders();
      final url = includeInactive
          ? '$baseUrl/patients?includeInactive=true'
          : '$baseUrl/patients';

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return PacientesResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo pacientes: $e');
      rethrow;
    }
  }

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

  Future<Paciente> getPacienteById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/patients/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Paciente.fromJson(responseData['data']);
    } catch (e) {
      print(' Error obteniendo paciente: $e');
      rethrow;
    }
  }

  Future<Paciente> crearPaciente(Paciente paciente) async {
    try {
      final headers = await _getHeaders();

      final personaData = {
        'nombre': paciente.nombre,
        'a_paterno': paciente.aPaterno,
        'a_materno': paciente.aMaterno,
        'fech_nac': paciente.fechNac,
        'telefono': paciente.telefono,
        'mail': paciente.mail,
        'ci': paciente.ci,
        'genero': paciente.genero,
        'domicilio': paciente.domicilio,
      };

      print(' DATOS A ENVIAR: $personaData');

      print(' Creando persona...');
      final personaResponse = await http
          .post(
            Uri.parse('$baseUrl/persons'),
            headers: headers,
            body: json.encode(personaData),
          )
          .timeout(const Duration(seconds: 30));

      final personaResponseData = _handleResponse(personaResponse);
      final personaId = personaResponseData['data']['id'];
      print(' Persona creada con ID: $personaId');

      final pacienteData = {
        'persona_id': personaId,
        'grupo_sanguineo': paciente.grupoSanguineo,
        'alergias': paciente.alergias,
        'antecedentes': paciente.antecedentes,
        'estatura': paciente.estatura,
        'provincia': paciente.provincia,
      };

      print(' DATOS PACIENTE A ENVIAR: $pacienteData');

      print(' Creando paciente...');
      final pacienteResponse = await http
          .post(
            Uri.parse('$baseUrl/patients'),
            headers: headers,
            body: json.encode(pacienteData),
          )
          .timeout(const Duration(seconds: 30));

      final pacienteResponseData = _handleResponse(pacienteResponse);
      print(' Paciente creado exitosamente');

      return Paciente.fromJson(pacienteResponseData['data']);
    } catch (e) {
      print('Error creando paciente: $e');
      rethrow;
    }
  }

  Future<Paciente> actualizarPaciente(int id, Paciente paciente) async {
    try {
      final headers = await _getHeaders();

      final Map<String, dynamic> dataToUpdate = {
        'nombre': paciente.nombre,
        'a_paterno': paciente.aPaterno,
        'a_materno': paciente.aMaterno,
        'fech_nac': paciente.fechNac,
        'telefono': paciente.telefono,
        'mail': paciente.mail,
        'ci': paciente.ci,
        'genero': paciente.genero,
        'domicilio': paciente.domicilio,
        'grupo_sanguineo': paciente.grupoSanguineo,
        'alergias': paciente.alergias,
        'antecedentes': paciente.antecedentes,
        'estatura': paciente.estatura,
        'provincia': paciente.provincia,
        'activo': paciente.activo,
      };

      print(' Enviando actualización: $dataToUpdate');

      final response = await http
          .put(
            Uri.parse('$baseUrl/patients/$id'),
            headers: headers,
            body: json.encode(dataToUpdate),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Paciente.fromJson(responseData['data']);
    } catch (e) {
      print('Error actualizando paciente: $e');
      rethrow;
    }
  }

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
