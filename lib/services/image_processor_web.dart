import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart';

class ImageProcessor {
  /// Aplica solo escala de grises para web
  static Future<Uint8List> applyGrayscale(Uint8List imageBytes) async {
    try {
      // En web, no aplicamos filtros, devolvemos la imagen original
      // O si quieres escala de grises en web también:
      return _applyGrayscaleWeb(imageBytes);
    } catch (e) {
      debugPrint('Error aplicando escala de grises web: $e');
      return imageBytes;
    }
  }

  static Future<Uint8List> _applyGrayscaleWeb(Uint8List imageBytes) async {
    final html.Blob blob = html.Blob([imageBytes]);
    final String url = html.Url.createObjectUrlFromBlob(blob);

    final completer = Completer<Uint8List>();
    final html.ImageElement image = html.ImageElement();

    image.onLoad.listen((_) async {
      final html.CanvasElement canvas = html.CanvasElement(
        width: image.width!,
        height: image.height!,
      );

      final html.CanvasRenderingContext2D ctx = canvas.context2D;

      // Dibujar imagen original
      ctx.drawImage(image, 0, 0);

      // Aplicar filtro de escala de grises
      final imageData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);
      final data = imageData.data;

      for (int i = 0; i < data.length; i += 4) {
        final gray =
            (data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114)
                .round();
        data[i] = gray; // R
        data[i + 1] = gray; // G
        data[i + 2] = gray; // B
      }

      ctx.putImageData(imageData, 0, 0);

      // Convertir a Blob
      canvas.toBlob('image/jpeg', 0.9).then((blob) {
        if (blob != null) {
          final reader = html.FileReader();
          reader.onLoadEnd.listen((e) {
            final result = reader.result;
            if (result != null) {
              completer.complete(
                Uint8List.fromList(List<int>.from(result as List<dynamic>)),
              );
            } else {
              completer.complete(imageBytes);
            }
          });
          reader.readAsArrayBuffer(blob);
        } else {
          completer.complete(imageBytes);
        }
      });
    });

    image.onError.listen((_) {
      completer.complete(imageBytes);
    });

    image.src = url;

    final result = await completer.future;
    html.Url.revokeObjectUrl(url);

    return result;
  }
}
