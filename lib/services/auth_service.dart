// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:3000/api';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Map<String, String> getHeaders({String? token}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    print(' API Response: ${response.statusCode}');
    print(' Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    switch (response.statusCode) {
      case 400:
        throw Exception('Solicitud incorrecta');
      case 401:
        final errorData = json.decode(response.body);
        final message = errorData['message'] ?? 'Credenciales incorrectas';
        throw Exception(message);
      case 403:
        throw Exception('No tiene permisos para esta acción');
      case 404:
        throw Exception('Recurso no encontrado');
      case 409:
        throw Exception('El usuario ya existe');
      case 500:
        throw Exception('Error interno del servidor');
      default:
        throw Exception('Error: ${response.statusCode}');
    }
  }

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            body: json.encode(loginRequest.toJson()),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return LoginResponse.fromJson(responseData);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyToken() async {
    try {
      final String? token = await _secureStorage.read(key: 'auth_token');

      if (token == null) return false;

      final String? userDataString = await _secureStorage.read(
        key: 'user_data',
      );
      if (userDataString != null) {
        final userMap = json.decode(userDataString);
        final user = UserData.fromJson(userMap);
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/verify'),
            headers: getHeaders(token: token),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error verificando token: $e');
      // Si hay error, asumimos que no está autenticado
      await clearSession(); // Limpiar sesión corrupta
      return false;
    }
  }

  Future<void> logout() async {
    print(' Iniciando logout...');

    try {
      final String? token = await _secureStorage.read(key: 'auth_token');

      if (token != null && token.isNotEmpty) {
        print(' Enviando petición de logout al servidor...');

        final response = await http
            .post(
              Uri.parse('$baseUrl/auth/logout'),
              headers: getHeaders(token: token),
            )
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print(' Timeout en logout del servidor');
                return http.Response('{"message": "timeout"}', 408);
              },
            );

        print(' Respuesta del servidor: ${response.statusCode}');
      } else {
        print(' No hay token guardado');
      }
    } catch (e) {
      print(' Error en petición de logout: $e');
    } finally {
      // SIEMPRE limpiar el storage
      try {
        await _secureStorage.deleteAll();
        print(' Storage limpiado completamente');
      } catch (e) {
        print('Error limpiando storage: $e');
        // Intentar borrar keys específicas
        await _secureStorage.delete(key: 'auth_token');
        await _secureStorage.delete(key: 'user_data');
        print(' Keys específicas borradas');
      }
    }
  }

  Future<void> saveSession(LoginResponse loginResponse) async {
    if (loginResponse.data != null) {
      await _secureStorage.write(
        key: 'auth_token',
        value: loginResponse.data!.token,
      );
      await _secureStorage.write(
        key: 'user_data',
        value: json.encode(loginResponse.data!.user.toJson()),
      );
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<UserData?> getUserData() async {
    try {
      final String? userDataString = await _secureStorage.read(
        key: 'user_data',
      );
      if (userDataString != null) {
        final Map<String, dynamic> userMap = json.decode(userDataString);
        return UserData.fromJson(userMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _secureStorage.deleteAll();
  }
}
