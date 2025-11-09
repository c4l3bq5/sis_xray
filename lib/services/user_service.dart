// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_models.dart';
import 'auth_service.dart';

class UserService {
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

  // Headers públicos (sin token) para recuperación de contraseña
  Map<String, String> _getPublicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _handleResponse(http.Response response) {
    print('🔵 API Response: ${response.statusCode}');
    print('📄 Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    switch (response.statusCode) {
      case 401:
        throw Exception('No autorizado. Por favor inicie sesión nuevamente');
      case 403:
        throw Exception('No tiene permisos para realizar esta acción');
      case 404:
        throw Exception('Usuario no encontrado');
      case 500:
        throw Exception('Error interno del servidor');
      default:
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Error: ${response.statusCode}');
        } catch (e) {
          throw Exception('Error: ${response.statusCode}');
        }
    }
  }

  // 🆕 NUEVO: Buscar usuario por CI o username (para recuperación de contraseña)
  // Este endpoint es público y no requiere autenticación
  Future<Map<String, dynamic>> getUserByIdentifier(String identifier) async {
    try {
      print('🔍 Buscando usuario por CI o username: $identifier');
      
      // Usar el endpoint que busca por CI o username
      final encodedIdentifier = Uri.encodeComponent(identifier);
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/by-identifier/internal/$encodedIdentifier'),
            headers: _getPublicHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      
      // Extraer datos del usuario y su persona
      final userData = responseData['data'];
      final personaData = userData['persona'];
      
      print('✅ Usuario encontrado: ${userData['usuario']}');
      print('📱 Teléfono: ${personaData['telefono']}');
      
      return {
        'id': userData['id'],
        'usuario': userData['usuario'],
        'ci': personaData['ci'],
        'telefono': personaData['telefono'],
        'email': personaData['mail'],
        'nombre': personaData['nombre'],
        'a_paterno': personaData['a_paterno'],
        'a_materno': personaData['a_materno'],
      };
    } catch (e) {
      print('❌ Error buscando usuario: $e');
      rethrow;
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
      print('❌ Error obteniendo usuarios: $e');
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
      print('❌ Error obteniendo usuario: $e');
      rethrow;
    }
  }

  // Actualizar datos PERSONALES del usuario (tabla persona)
  Future<bool> actualizarDatosPersona(
    int personaId,
    Map<String, dynamic> data,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/persons/$personaId'),
            headers: headers,
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print('❌ Error actualizando datos personales: $e');
      rethrow;
    }
  }

  // Actualizar usuario (rol, username, etc)
  Future<bool> actualizarUsuario(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$id'),
            headers: headers,
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      _handleResponse(response);
      return true;
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      rethrow;
    }
  }

  // El backend genera automáticamente la contraseña temporal
  Future<Map<String, dynamic>> crearUsuario({
    required String nombre,
    required String aPaterno,
    required String? aMaterno,
    required String ci,
    required String mail,
    required String usuario,
    required int rolId,
    required DateTime fechaNac,
    required String genero,
    required String? telefono,
    required String? domicilio,
  }) async {
    try {
      final headers = await _getHeaders();

      // PASO 1: Crear persona
      final personaData = {
        'nombre': nombre,
        'a_paterno': aPaterno,
        'a_materno': aMaterno,
        'fech_nac': fechaNac.toIso8601String().split('T')[0],
        'mail': mail,
        'ci': ci,
        'genero': genero,
        'telefono': telefono,
        'domicilio': domicilio,
      };

      print('📝 Creando persona...');
      final personaResponse = await http
          .post(
            Uri.parse('$baseUrl/persons'),
            headers: headers,
            body: json.encode(personaData),
          )
          .timeout(const Duration(seconds: 30));

      final personaResponseData = _handleResponse(personaResponse);
      final personaId = personaResponseData['data']['id'];
      print('✅ Persona creada con ID: $personaId');

      // PASO 2: Crear usuario SIN enviar contraseña
      final usuarioData = {
        'persona_id': personaId,
        'rol_id': rolId,
        'usuario': usuario,
      };

      print('📝 Creando usuario...');
      final usuarioResponse = await http
          .post(
            Uri.parse('$baseUrl/users'),
            headers: headers,
            body: json.encode(usuarioData),
          )
          .timeout(const Duration(seconds: 30));

      final usuarioResponseData = _handleResponse(usuarioResponse);
      final passwordGenerada = usuarioResponseData['data']['temporaryPassword'];

      print('✅ Usuario creado exitosamente');
      print('🔑 Contraseña temporal del backend: $passwordGenerada');

      return {
        'usuario': usuarioResponseData['data'],
        'passwordGenerada': passwordGenerada,
      };
    } catch (e) {
      print('❌ Error creando usuario: $e');
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
      print('❌ Error activando usuario: $e');
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
      print('❌ Error desactivando usuario: $e');
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
      print('❌ Error habilitando MFA: $e');
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
      print('❌ Error deshabilitando MFA: $e');
      rethrow;
    }
  }
}