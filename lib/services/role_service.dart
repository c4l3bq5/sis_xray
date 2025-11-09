// lib/services/role_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/role_models.dart';
import 'auth_service.dart';

class RoleService {
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
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    switch (response.statusCode) {
      case 401:
        throw Exception('No autorizado');
      case 403:
        throw Exception('No tiene permisos');
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

  // Obtener todos los roles
  Future<List<Rol>> obtenerRoles() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/roles'), headers: headers)
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      final rolesResponse = RolesResponse.fromJson(responseData);
      return rolesResponse.roles;
    } catch (e) {
      print('Error obteniendo roles: $e');
      rethrow;
    }
  }
}
