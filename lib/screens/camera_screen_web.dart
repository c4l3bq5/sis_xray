import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui_web;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  html.MediaStream? _webStream;
  html.VideoElement? _webVideoElement;
  bool _isLoading = false;
  String? _error;
  bool _isCameraActive = false;
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'camera-video-${DateTime.now().millisecondsSinceEpoch}';
    _initializeWebCamera();
  }

  Future<void> _initializeWebCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('Tu navegador no soporta acceso a cámara.');
      }

      _webStream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _webVideoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..controls = false
        ..srcObject = _webStream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      await _webVideoElement!.onCanPlay.first;

      try {
        ui_web.platformViewRegistry.registerViewFactory(
          _viewId,
          (int viewId) => _webVideoElement!,
        );
      } catch (e) {
        debugPrint('ViewFactory ya registrado: $e');
      }

      setState(() {
        _isLoading = false;
        _isCameraActive = true;
      });
    } catch (e) {
      debugPrint('Error inicializando cámara web: $e');
      setState(() {
        _error = 'No se pudo acceder a la cámara: $e';
        _isLoading = false;
        _isCameraActive = false;
      });
    }
  }

  Future<Uint8List?> _capturePhotoWeb() async {
    if (_webVideoElement == null || !_isCameraActive) return null;

    try {
      final canvas = html.CanvasElement(
        width: _webVideoElement!.videoWidth,
        height: _webVideoElement!.videoHeight,
      );

      final context = canvas.context2D;
      context.drawImage(_webVideoElement!, 0, 0);

      final blob = await canvas.toBlob('image/jpeg', 0.9);

      if (blob == null) return null;

      final completer = Completer<Uint8List?>();
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result != null) {
          completer.complete(
            Uint8List.fromList(List<int>.from(result as List<dynamic>)),
          );
        } else {
          completer.complete(null);
        }
      });

      reader.onError.listen((e) {
        debugPrint('Error leyendo blob: $e');
        completer.complete(null);
      });

      reader.readAsArrayBuffer(blob);

      return await completer.future;
    } catch (e) {
      debugPrint('Error capturando foto: $e');
      return null;
    }
  }

  void _stopCamera() {
    try {
      _webStream?.getTracks().forEach((track) {
        track.stop();
      });
      _webVideoElement?.srcObject = null;
      _webVideoElement?.remove();
      _webStream = null;
      _webVideoElement = null;
      setState(() {
        _isCameraActive = false;
      });
    } catch (e) {
      debugPrint('Error deteniendo cámara: $e');
    }
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Tomar Foto con Cámara',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _stopCamera();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Column(
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.blueAccent),
                  SizedBox(height: 10),
                  Text(
                    'Captura una radiografía',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Asegúrate de que la imagen esté bien enfocada y centrada',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.blueAccent,
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Inicializando cámara...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 50,
                                  color: Colors.blue[300],
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.blue[100],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            HtmlElementView(viewType: _viewId),

                            if (_isCameraActive)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 8,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Cámara activa',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 30),

              if (_isCameraActive) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final imageBytes = await _capturePhotoWeb();

                    if (imageBytes != null && mounted) {
                      _stopCamera();
                      Navigator.pop(context, imageBytes);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Error al capturar la foto'),
                            backgroundColor: Colors.red[400],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: const Text(
                    'CAPTURAR FOTO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () {
                    _stopCamera();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('CANCELAR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    foregroundColor: Colors.blueAccent,
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else if (_error != null) ...[
                ElevatedButton.icon(
                  onPressed: _initializeWebCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, size: 16, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'Consejos para una buena captura:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Coloca la radiografía sobre una superficie plana\n• Asegura buena iluminación\n• Mantén la cámara estable al capturar',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
