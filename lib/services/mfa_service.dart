// lib/services/mfa_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

class MFAService {
  // 🔥 URL CORREGIDA del microservicio MFA en Render
  static const String mfaBaseUrl = 'https://mfa-api-5155.onrender.com/api/mfa';

  Map<String, String> getHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  dynamic _handleResponse(http.Response response) {
    print('MFA API Response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    switch (response.statusCode) {
      case 400:
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Código MFA inválido');
      case 401:
        throw Exception('Código MFA incorrecto o expirado');
      case 404:
        throw Exception('Usuario no encontrado');
      case 500:
        throw Exception('Error en servidor MFA');
      default:
        throw Exception('Error: ${response.statusCode}');
    }
  }

  /// Verifica el código MFA durante el login
  Future<MFAVerifyResponse> verifyLoginMFA(int userId, String mfaCode) async {
    try {
      final response = await http
          .post(
            Uri.parse('$mfaBaseUrl/verify-login'),
            body: json.encode({'userId': userId, 'mfaCode': mfaCode}),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return MFAVerifyResponse.fromJson(responseData);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica el estado MFA de un usuario
  Future<bool> checkMFAStatus(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$mfaBaseUrl/status/$userId'), headers: getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['mfaEnabled'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking MFA status: $e');
      return false;
    }
  }

  /// Genera un nuevo secreto MFA y QR code para configuración
  Future<Map<String, dynamic>> generateMFASetup(
    int userId,
    String username,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$mfaBaseUrl/generate'),
            body: json.encode({'userId': userId, 'username': username}),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return responseData['data'];
    } catch (e) {
      rethrow;
    }
  }

  /// Activa MFA verificando el código del usuario
  Future<bool> activateMFA(int userId, String mfaCode, String secret) async {
    try {
      final response = await http
          .post(
            Uri.parse('$mfaBaseUrl/verify'),
            body: json.encode({
              'userId': userId,
              'mfaCode': mfaCode,
              'secret': secret,
            }),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return responseData['success'] ?? false;
    } catch (e) {
      rethrow;
    }
  }

  /// Desactiva MFA para un usuario
  Future<bool> disableMFA(int userId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$mfaBaseUrl/disable'),
            body: json.encode({'userId': userId}),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return responseData['success'] ?? false;
    } catch (e) {
      rethrow;
    }
  }
}