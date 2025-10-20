// services/api_service.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart'; // ¡IMPORTANTE! Agregar este import

class ApiService {
  static const String _ngrokUrl =
      'https://sheet-armor-jeans-info.trycloudflare.com';

  /// Analiza una imagen de radiografía
  /// [imageBytes] - Bytes de la imagen en formato JPG/PNG
  /// [useOriginalQuality] - Si es true, no aplica compresión adicional
  static Future<Map<String, dynamic>> analyzeImage(
    Uint8List imageBytes, {
    bool useOriginalQuality = true,
  }) async {
    final uri = Uri.parse('$_ngrokUrl/analyze');

    try {
      print(' Enviando imagen a: $_ngrokUrl/analyze');
      print(' Tamaño: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB');

      final request = http.MultipartRequest('POST', uri);

      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'xray_analysis.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Headers adicionales
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning':
            'true', // Para evitar advertencias de ngrok
      });

      print(' Tipo de contenido: image/jpeg');
      print(' Nombre de archivo: xray_analysis.jpg');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception(' Timeout: El servidor tardó más de 90 segundos');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print(' Respuesta recibida: ${response.statusCode}');
      print(' Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        print(' Análisis exitoso');
        print(' Status: ${jsonResponse['status']}');

        return jsonResponse;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(
          ' Error de validación: ${errorData['detail'] ?? errorData['message'] ?? response.body}',
        );
      } else if (response.statusCode == 500) {
        throw Exception(' Error del servidor: ${response.body}');
      } else {
        throw Exception(
          ' Error desconocido (${response.statusCode}): ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception(
        ' Error de conexión: No se pudo conectar al servidor. ¿Ngrok/Colab está corriendo? ($e)',
      );
    } on FormatException catch (e) {
      throw Exception(
        ' Error de formato: Respuesta inválida del servidor ($e)',
      );
    } catch (e) {
      throw Exception(' Error inesperado: ${e.toString()}');
    }
  }

  /// Verifica que la API esté activa
  static Future<bool> checkHealth() async {
    final uri = Uri.parse('$_ngrokUrl/health');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final modelsLoaded = data['models_loaded'] as bool? ?? false;

        print(' API saludable - Modelos cargados: $modelsLoaded');
        return modelsLoaded;
      }
      return false;
    } catch (e) {
      print(' Health check falló: $e');
      return false;
    }
  }

  /// Obtiene información básica de la API
  static Future<Map<String, dynamic>> getApiInfo() async {
    final uri = Uri.parse(_ngrokUrl);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Error obteniendo info: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }
}
