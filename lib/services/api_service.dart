// services/api_service.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String _baseUrl =
      'https://full-tries-sweet-african.trycloudflare.com';

  /// Analiza una imagen de radiografía
  ///
  /// [imageBytes] - Bytes de la imagen en formato JPG/PNG
  ///
  /// Retorna JSON con:
  /// - status: 'success' | 'rejected' | 'error'
  /// - region_analysis: clasificación upper/lower/other
  /// - segmentation: huesos detectados
  /// - fracture_analysis: fracturas encontradas
  /// - annotated_image_base64: imagen con marcas (si hay fracturas)
  /// - clinical_recommendation: recomendación médica
  static Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes) async {
    final uri = Uri.parse('$_baseUrl/analyze');

    try {
      print(' Enviando imagen a: $_baseUrl/analyze');
      print(' Tamaño: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB');

      // Crear request multipart
      final request = http.MultipartRequest('POST', uri);

      // Agregar imagen con tipo MIME correcto
      final multipartFile = http.MultipartFile.fromBytes(
        'image', // ← Nombre del campo (debe coincidir con la API)
        imageBytes,
        filename: 'xray_analysis.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Headers adicionales
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      });

      print(' Request preparado');
      print('   Campo: image');
      print('   Tipo: image/jpeg');

      // Enviar con timeout (análisis puede tomar 30-90s)
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception(' Timeout: El servidor tardó más de 120 segundos');
        },
      );

      // Convertir a Response
      final response = await http.Response.fromStream(streamedResponse);

      print(' Respuesta recibida: ${response.statusCode}');

      // Manejar respuestas
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        print(' Análisis exitoso');
        print(' Status: ${jsonResponse['status']}');

        // Verificar si hay imagen anotada
        if (jsonResponse.containsKey('annotated_image_base64')) {
          final base64Length =
              (jsonResponse['annotated_image_base64'] as String).length;
          print(' Imagen anotada incluida: $base64Length caracteres');
        } else {
          print(' Sin imagen anotada (no hay fracturas)');
        }

        return jsonResponse;
      } else if (response.statusCode == 400) {
        // Error de validación
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            ' Error de validación: ${errorData['detail'] ?? errorData['message'] ?? response.body}',
          );
        } catch (e) {
          throw Exception(' Error 400: ${response.body}');
        }
      } else if (response.statusCode == 500) {
        // Error interno del servidor
        throw Exception(' Error del servidor (500): ${response.body}');
      } else if (response.statusCode == 503) {
        throw Exception(' Servicio no disponible: Modelos aún cargando');
      } else {
        throw Exception(
          ' Error desconocido (${response.statusCode}): ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception(
        ' Error de conexión: No se pudo conectar al servidor.\n'
        '¿El túnel de Cloudflare está activo?\n'
        'Error: $e',
      );
    } on FormatException catch (e) {
      throw Exception(
        ' Error de formato: Respuesta inválida del servidor.\n'
        'Error: $e',
      );
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        throw Exception(' Timeout: El análisis tardó demasiado');
      }
      throw Exception(' Error inesperado: ${e.toString()}');
    }
  }

  /// Verifica que la API esté activa y los modelos cargados
  static Future<bool> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/health');

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
    final uri = Uri.parse(_baseUrl);

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
