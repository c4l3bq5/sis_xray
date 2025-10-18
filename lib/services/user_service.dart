// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_models.dart';
import 'auth_service.dart';

class UserService {
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
        throw Exception('Recurso no encontrado');
      case 500:
        throw Exception('Error interno del servidor');
      default:
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Error: ${response.statusCode}',
        );
    }
  }

  // Obtener lista de usuarios (solo admin)
  Future<UsuariosResponse> getUsuarios() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/users'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return UsuariosResponse.fromJson(responseData);
    } catch (e) {
      print(' Error obteniendo usuarios: $e');
      rethrow;
    }
  }

  // Obtener usuario por ID
  Future<Usuario> getUsuarioById(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/users/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return Usuario.fromJson(responseData['data']);
    } catch (e) {
      print(' Error obteniendo usuario: $e');
      rethrow;
    }
  }

  // Activar usuario
  Future<bool> activarUsuario(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(Uri.parse('$baseUrl/users/$id/activate'), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print(' Error activando usuario: $e');
      rethrow;
    }
  }

  // Desactivar usuario
  Future<bool> desactivarUsuario(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/users/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print(' Error desactivando usuario: $e');
      rethrow;
    }
  }

  // Habilitar MFA
  Future<bool> habilitarMFA(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(Uri.parse('$baseUrl/users/$id/enable-mfa'), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print(' Error habilitando MFA: $e');
      rethrow;
    }
  }

  // Deshabilitar MFA
  Future<bool> deshabilitarMFA(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(Uri.parse('$baseUrl/users/$id/disable-mfa'), headers: headers)
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print(' Error deshabilitando MFA: $e');
      rethrow;
    }
  }
}
