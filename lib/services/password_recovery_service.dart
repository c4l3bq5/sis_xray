// lib/services/password_recovery_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordRecoveryService {
  // URL del microservicio de recovery en Render
  static const String baseUrl = 'https://wha-recovery-hxg2.onrender.com/api/recovery';
  
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _handleResponse(http.Response response) {
    print('Recovery API Response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }

    // Manejar errores
    try {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 'Error desconocido';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error: ${response.statusCode}');
    }
  }

  /// Paso 1: Solicitar código de verificación
  /// Envía un código de 6 dígitos al WhatsApp del usuario
  Future<RequestCodeResponse> requestCode(String identifier) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/request-code'),
            body: json.encode({'identifier': identifier}),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return RequestCodeResponse.fromJson(responseData);
    } catch (e) {
      print('Error en requestCode: $e');
      rethrow;
    }
  }

  /// Paso 2: Verificar código de 6 dígitos
  /// Retorna un resetToken si el código es correcto
  Future<VerifyCodeResponse> verifyCode(String identifier, String code) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify-code'),
            body: json.encode({
              'identifier': identifier,
              'code': code,
            }),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return VerifyCodeResponse.fromJson(responseData);
    } catch (e) {
      print('Error en verifyCode: $e');
      rethrow;
    }
  }

  /// Paso 3: Restablecer contraseña
  /// Cambia la contraseña usando el resetToken
  Future<ResetPasswordResponse> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reset-password'),
            body: json.encode({
              'identifier': identifier,
              'resetToken': resetToken,
              'newPassword': newPassword,
            }),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final responseData = _handleResponse(response);
      return ResetPasswordResponse.fromJson(responseData);
    } catch (e) {
      print('Error en resetPassword: $e');
      rethrow;
    }
  }

  /// Health check del microservicio
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://wha-recovery-hxg2.onrender.com/health'),
            headers: getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error en health check: $e');
      return false;
    }
  }
}

// ============================================================================
// MODELOS DE RESPUESTA
// ============================================================================

class RequestCodeResponse {
  final String message;
  final bool sent;
  final int? expiresIn;

  RequestCodeResponse({
    required this.message,
    required this.sent,
    this.expiresIn,
  });

  factory RequestCodeResponse.fromJson(Map<String, dynamic> json) {
    return RequestCodeResponse(
      message: json['message'] ?? '',
      sent: json['sent'] ?? false,
      expiresIn: json['expiresIn'],
    );
  }
}

class VerifyCodeResponse {
  final String message;
  final String resetToken;
  final int expiresIn;
  final int? attemptsLeft;

  VerifyCodeResponse({
    required this.message,
    required this.resetToken,
    required this.expiresIn,
    this.attemptsLeft,
  });

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResponse(
      message: json['message'] ?? '',
      resetToken: json['resetToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      attemptsLeft: json['attemptsLeft'],
    );
  }
}

class ResetPasswordResponse {
  final String message;
  final bool success;

  ResetPasswordResponse({
    required this.message,
    required this.success,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
}