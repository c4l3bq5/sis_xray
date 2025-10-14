import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class ImageProcessor {
  /// Aplica los filtros específicos del dispositivo Infinix X6531B
  static Future<Uint8List> applyInfinixFilters(Uint8List imageBytes) async {
    // Ejecutar en un isolate separado para evitar bloquear el UI
    return await compute(_processImage, imageBytes);
  }

  // Esta función se ejecutará en un isolate separado
  static Uint8List _processImage(Uint8List imageBytes) {
    try {
      debugPrint('Iniciando procesamiento de imagen...');

      // Decodificar la imagen
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      debugPrint(
        'Imagen decodificada: ${originalImage.width}x${originalImage.height}',
      );

      // Redimensionar si es muy grande (optimización)
      img.Image workingImage = originalImage;
      const maxDimension = 2048;

      if (originalImage.width > maxDimension ||
          originalImage.height > maxDimension) {
        debugPrint('Redimensionando imagen grande...');
        workingImage = img.copyResize(
          originalImage,
          width: originalImage.width > originalImage.height
              ? maxDimension
              : null,
          height: originalImage.height > originalImage.width
              ? maxDimension
              : null,
        );
        debugPrint(
          'Nueva dimensión: ${workingImage.width}x${workingImage.height}',
        );
      }

      // Calcular brillo promedio de la imagen original
      final avgBrightness = _calculateAverageBrightness(workingImage);
      debugPrint('Brillo promedio: ${avgBrightness.toStringAsFixed(2)}');

      // 1. Escala de grises
      debugPrint('Aplicando escala de grises...');
      workingImage = img.grayscale(workingImage);

      // 2. Ajustar contraste (adaptativo según el brillo)
      debugPrint('Ajustando contraste...');
      final contrastFactor = avgBrightness < 100
          ? 1.15
          : 1.25; // Menos contraste si es oscura
      workingImage = img.adjustColor(workingImage, contrast: contrastFactor);

      // 3. Ajustar brillo (adaptativo)
      debugPrint('Ajustando brillo...');
      final brightnessFactor = avgBrightness < 100
          ? 0.85
          : 0.75; // Menos reducción si es oscura
      workingImage = img.adjustColor(
        workingImage,
        brightness: brightnessFactor,
      );

      // 4. Ajustar sombras suavemente
      debugPrint('Ajustando sombras...');
      workingImage = _adjustShadowsSmooth(workingImage, -20); // Menos agresivo

      // 5. Punto negro ajustado (más suave)
      debugPrint('Aplicando punto negro...');
      workingImage = _adjustBlackPointSmooth(
        workingImage,
        60,
      ); // Menos agresivo

      // 6. Aumentar nitidez levemente
      debugPrint('Aumentando nitidez...');
      workingImage = img.convolution(
        workingImage,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        div: 1,
      );

      // Verificar que la imagen no quedó demasiado oscura
      final finalBrightness = _calculateAverageBrightness(workingImage);
      debugPrint('Brillo final: ${finalBrightness.toStringAsFixed(2)}');

      if (finalBrightness < 30) {
        debugPrint('Imagen muy oscura, ajustando...');
        workingImage = img.adjustColor(workingImage, brightness: 1.2);
      }

      // Codificar a JPEG con buena calidad
      debugPrint('Codificando imagen final...');
      final processedBytes = img.encodeJpg(workingImage, quality: 90);

      debugPrint(
        'Procesamiento completado. Tamaño: ${processedBytes.length} bytes',
      );
      return Uint8List.fromList(processedBytes);
    } catch (e) {
      debugPrint('Error en procesamiento: $e');
      return imageBytes; // Retornar imagen original en caso de error
    }
  }

  // Calcular brillo promedio de la imagen
  static double _calculateAverageBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = 0;

    // Muestrear cada 10 píxeles para optimizar
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Fórmula de luminosidad perceptual
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    return totalBrightness / pixelCount;
  }

  // Versión suave: solo ajusta sombras muy oscuras
  static img.Image _adjustShadowsSmooth(img.Image image, int amount) {
    for (final pixel in image) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // Solo ajustar píxeles muy oscuros (umbral más bajo)
      if (r < 80 && g < 80 && b < 80) {
        final factor = 1.0 - (r / 80.0); // Ajuste gradual
        final adjustment = (amount * factor).toInt();

        pixel
          ..r = _clamp(r + adjustment)
          ..g = _clamp(g + adjustment)
          ..b = _clamp(b + adjustment);
      }
    }

    return image;
  }

  // Versión suave: punto negro menos agresivo
  static img.Image _adjustBlackPointSmooth(img.Image image, int blackPoint) {
    final normalizedBlackPoint = (blackPoint / 100 * 255).toInt();

    for (final pixel in image) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      pixel
        ..r = _applyBlackPointSmooth(r, normalizedBlackPoint)
        ..g = _applyBlackPointSmooth(g, normalizedBlackPoint)
        ..b = _applyBlackPointSmooth(b, normalizedBlackPoint);
    }

    return image;
  }

  static int _applyBlackPointSmooth(int value, int blackPoint) {
    if (value < blackPoint) {
      // Transición suave en lugar de negro absoluto
      return (value * 0.3).toInt().clamp(0, 255);
    } else {
      final range = 255 - blackPoint;
      final newValue = ((value - blackPoint) * 255 / range).toInt();
      return newValue.clamp(0, 255);
    }
  }

  static int _clamp(int value) {
    return value.clamp(0, 255);
  }
}
