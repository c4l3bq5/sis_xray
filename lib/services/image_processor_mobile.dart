import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class ImageProcessor {
  /// Aplica solo escala de grises para móvil
  static Future<Uint8List> applyGrayscale(Uint8List imageBytes) async {
    try {
      // Decodificar la imagen
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Aplicar solo escala de grises
      final grayscaleImage = img.grayscale(originalImage);

      // Codificar a JPEG con buena calidad
      final processedBytes = img.encodeJpg(grayscaleImage, quality: 90);

      return Uint8List.fromList(processedBytes);
    } catch (e) {
      debugPrint('Error aplicando escala de grises: $e');
      return imageBytes;
    }
  }
}
