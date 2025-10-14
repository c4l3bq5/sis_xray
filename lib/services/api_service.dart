import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _ngrokUrl =
      'https://sacha-blossomless-swelteringly.ngrok-free.dev/analyze';

  static Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes) async {
    final uri = Uri.parse(_ngrokUrl);

    final request = http.MultipartRequest('POST', uri);

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: 'xray_image.jpg',
    );

    request.files.add(multipartFile);

    try {
      // 3. Enviar la petición
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 4. Manejar la respuesta
      if (response.statusCode == 200) {
        // La API de FastAPI/Colab retorna JSON
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Manejar errores del servidor (e.g., 500 Internal Server Error)
        throw Exception(
          'Fallo de API: Código ${response.statusCode}. Respuesta: ${response.body}',
        );
      }
    } catch (e) {
      // Manejar errores de conexión o parsing
      throw Exception('Error de conexión o datos: ${e.toString()}');
    }
  }
}
