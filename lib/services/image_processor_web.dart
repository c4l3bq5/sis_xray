import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class ImageProcessor {
  /// Método para web usando Canvas (más rápido)
  static Future<Uint8List> applyInfinixFilters(Uint8List imageBytes) async {
    try {
      final html.Blob blob = html.Blob([imageBytes]);
      final String url = html.Url.createObjectUrlFromBlob(blob);

      final completer = Completer<Uint8List>();
      final html.ImageElement image = html.ImageElement();

      image.onLoad.listen((_) async {
        try {
          final html.CanvasElement canvas = html.CanvasElement(
            width: image.width!,
            height: image.height!,
          );

          final html.CanvasRenderingContext2D ctx = canvas.context2D;

          // Dibujar imagen original
          ctx.drawImage(image, 0, 0);

          // Aplicar filtros CSS que simulan los efectos
          // grayscale(100%) = escala de grises
          // contrast(120%) = +20% contraste
          // brightness(70%) = -30% brillo
          ctx.filter = 'grayscale(100%) contrast(120%) brightness(70%)';
          ctx.drawImage(image, 0, 0);
          ctx.filter = 'none';

          // Convertir canvas a Blob y luego a Uint8List
          final resultBlob = await canvas.toBlob('image/jpeg', 0.85);

          if (resultBlob != null) {
            final reader = html.FileReader();

            reader.onLoadEnd.listen((e) {
              final result = reader.result;
              if (result != null) {
                completer.complete(
                  Uint8List.fromList(List<int>.from(result as List<dynamic>)),
                );
              } else {
                debugPrint('FileReader result es null, usando imagen original');
                completer.complete(imageBytes);
              }
            });

            reader.onError.listen((e) {
              debugPrint('Error en FileReader: $e');
              completer.complete(imageBytes);
            });

            reader.readAsArrayBuffer(resultBlob);
          } else {
            debugPrint('toBlob retornó null, usando imagen original');
            completer.complete(imageBytes);
          }
        } catch (e) {
          debugPrint('Error en procesamiento de canvas: $e');
          completer.complete(imageBytes);
        }
      });

      image.onError.listen((e) {
        debugPrint('Error cargando imagen: $e');
        completer.complete(imageBytes);
      });

      image.src = url;

      final result = await completer.future;
      html.Url.revokeObjectUrl(url);

      return result;
    } catch (e) {
      debugPrint('Error aplicando filtros web: $e');
      return imageBytes;
    }
  }
}
