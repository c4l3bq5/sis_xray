import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import '../services/image_processor.dart';
import '../services/api_service.dart'; // ¡IMPORTANTE! Importar el servicio API

class XRayScreen extends StatefulWidget {
  const XRayScreen({super.key});

  @override
  State<XRayScreen> createState() => _XRayScreenState();
}

class _XRayScreenState extends State<XRayScreen> {
  // Variables de Estado para la Imagen y Procesamiento
  File? _selectedImage;
  Uint8List? _imageBytes;
  Uint8List? _processedImageBytes;
  final ImagePicker _picker = ImagePicker();
  ImageSource? _selectedSource;

  // Variables de Estado para UI y API
  bool _isLoading = false; // Carga de imagen (Picker/Camera)
  bool _isProcessing = false; // Aplicación de filtros local
  bool _isAnalyzing = false; // Llamada a la API
  bool _filtersApplied = false;
  Map<String, dynamic>? _apiResult; // Resultado JSON de la API

  // --- MÉTODOS DE MANEJO DE IMAGEN ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
        _filtersApplied = false;
        _apiResult =
            null; // Limpiar resultado anterior al seleccionar nueva imagen
      });

      if (source == ImageSource.camera) {
        final imageBytes = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );

        if (imageBytes != null && mounted) {
          setState(() {
            _imageBytes = imageBytes;
            _processedImageBytes = null;
            _selectedImage = null;
            _selectedSource = source;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto tomada correctamente con la cámara'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _applyFilters();
        } else {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) return;

        setState(() {
          _imageBytes = bytes;
          _processedImageBytes = null;
          _selectedImage = null;
          _isLoading = false;
          _selectedSource = source;
        });

        if (mounted) {
          final sourceName = source == ImageSource.camera
              ? 'cámara'
              : 'galería';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imagen capturada desde $sourceName'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _applyFilters();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al capturar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilters() async {
    if (_imageBytes == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      // Mostrar indicador
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Aplicando filtros de mejora...'),
              ],
            ),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }

      final processed = await ImageProcessor.applyInfinixFilters(_imageBytes!);

      if (mounted) {
        setState(() {
          _processedImageBytes = processed;
          _filtersApplied = true;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Filtros aplicados correctamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error aplicando filtros: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al aplicar filtros. Usando imagen original.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
      _processedImageBytes = null;
      _isLoading = false;
      _selectedSource = null;
      _filtersApplied = false;
      _apiResult = null; // Limpiar resultado de API
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagen eliminada'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- MÉTODO DE ANÁLISIS (LLAMADA A LA API) ---

  void _analyzeImage() async {
    final imageToAnalyze = _processedImageBytes ?? _imageBytes;

    if (imageToAnalyze == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una imagen primero'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _apiResult = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _filtersApplied
                  ? 'Analizando imagen optimizada...'
                  : 'Analizando imagen original...',
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      // LLAMADA AL API
      final result = await ApiService.analyzeImage(imageToAnalyze);

      if (mounted) {
        setState(() {
          _apiResult = result;
          _isAnalyzing = false;
        });

        // Verificar si requiere atención
        final requiresAttention =
            result['requires_attention'] as bool? ?? false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              requiresAttention
                  ? ' FRACTURAS DETECTADAS - Atención médica requerida'
                  : ' Análisis completado - Sin fracturas evidentes',
            ),
            backgroundColor: requiresAttention ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error en análisis: $e');

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          // Guardar error en el resultado
          _apiResult = {'status': 'error', 'error_message': e.toString()};
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // --- WIDGETS DE VISTA ---

  Widget _buildImagePreview() {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              SizedBox(height: 15),
              Text(
                'Cargando imagen...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final displayBytes = _processedImageBytes ?? _imageBytes;

    if (displayBytes != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _filtersApplied ? Colors.green : Colors.blueAccent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                displayBytes,
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error mostrando imagen: $error');
                  return _buildErrorWidget();
                },
              ),
            ),
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Procesando...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_filtersApplied && !_isProcessing)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Filtros aplicados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 15),
          const Text(
            'Error al cargar imagen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otra imagen',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[400]!,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_size_select_actual,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 15),
          Text(
            'No hay imagen seleccionada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Selecciona o captura una radiografía',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- WIDGET PARA MOSTRAR RESULTADOS DE API ---

  Widget _buildAnalysisResult(Map<String, dynamic> result) {
    final status = result['status'] ?? 'error';
    final isSuccess = status == 'success';
    final isRejected = status == 'rejected';

    // Caso 1: Error
    if (status == 'error') {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              '❌ Error en el Análisis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result['error_message']?.toString() ??
                  result['reason']?.toString() ??
                  'Error desconocido',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Caso 2: Imagen rechazada
    if (isRejected) {
      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.warning_amber, size: 60, color: Colors.orange),
            const SizedBox(height: 12),
            const Text(
              ' Imagen Rechazada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result['reason']?.toString() ?? 'Razón desconocida',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Caso 3: Análisis exitoso
    final region = result['region']?.toString().toUpperCase() ?? 'N/A';
    final confidence = result['confidence'] as double? ?? 0.0;
    final detectedBones = result['detected_bones'] as int? ?? 0;
    final fracturesDetected = result['fractures_detected'] as int? ?? 0;
    final requiresAttention = result['requires_attention'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: requiresAttention ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: requiresAttention ? Colors.red : Colors.green,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Icon(
                requiresAttention ? Icons.warning : Icons.check_circle,
                size: 40,
                color: requiresAttention ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  requiresAttention
                      ? ' FRACTURAS DETECTADAS'
                      : ' Sin Fracturas Evidentes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: requiresAttention ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 30, thickness: 1.5),

          // Región
          _buildInfoRow(
            'Región Analizada',
            region,
            Icons.location_on,
            Colors.blueAccent,
          ),

          // Confianza
          _buildInfoRow(
            'Nivel de Confianza',
            '${(confidence * 100).toStringAsFixed(1)}%',
            Icons.psychology,
            confidence > 0.8 ? Colors.green : Colors.orange,
          ),

          // Huesos detectados
          _buildInfoRow(
            'Estructuras Óseas',
            '$detectedBones huesos identificados',
            Icons.broken_image,
            Colors.deepPurple,
          ),

          // Fracturas
          _buildInfoRow(
            'Fracturas Detectadas',
            fracturesDetected > 0
                ? '$fracturesDetected fractura(s)'
                : 'Ninguna',
            Icons.crisis_alert,
            fracturesDetected > 0 ? Colors.red : Colors.green,
          ),

          // Detalles de fracturas
          if (fracturesDetected > 0 && result['fracture_details'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              ' Detalles de Fracturas:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate((result['fracture_details'] as List).length, (
              index,
            ) {
              final fracture = (result['fracture_details'] as List)[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${fracture['description'] ?? 'Fractura'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    if (fracture['affected_bone'] != null)
                      Text(
                        'Hueso: ${fracture['affected_bone']}',
                        style: TextStyle(fontSize: 13, color: Colors.red[900]),
                      ),
                  ],
                ),
              );
            }),
          ],

          // Recomendación médica
          if (requiresAttention) ...[
            const Divider(height: 30, thickness: 1.5),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Recomendación Médica',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Consulte con un especialista inmediatamente\n'
                    '• Este sistema es de apoyo, no diagnóstico definitivo\n'
                    '• Requiere validación por profesional médico',
                    style: TextStyle(height: 1.5, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 16, color: color)),
          ),
        ],
      ),
    );
  }

  // --- WIDGET PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageBytes != null;
    final isBusy = _isLoading || _isProcessing || _isAnalyzing;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Análisis de Radiografía',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TÍTULO Y DESCRIPCIÓN
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cargar Radiografía',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Selecciona una imagen desde tu galería o toma una foto con la cámara',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // BOTONES DE CÁMARA/GALERÍA
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 24),
                      label: const Text(
                        'Galería',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 24),
                      label: const Text(
                        'Cámara',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // VISTA PREVIA DE IMAGEN
              _buildImagePreview(),

              if (hasImage) ...[
                const SizedBox(height: 20),

                // BOTONES DE ELIMINAR Y ANALIZAR
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : _clearImage,
                        icon: const Icon(Icons.delete_outline, size: 22),
                        label: const Text(
                          'Eliminar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : _analyzeImage,
                        icon: const Icon(Icons.analytics, size: 22),
                        label: const Text(
                          'Analizar Radiografía',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),

                // --- RESULTADOS DE API ---
                if (_isAnalyzing)
                  const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blueAccent,
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Esperando respuesta del servidor (Ngrok/Colab)...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_apiResult != null) _buildAnalysisResult(_apiResult!),

                const SizedBox(height: 20),

                // PANEL DE INFO TÉCNICA
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _filtersApplied
                                  ? '✓ Imagen optimizada para análisis'
                                  : 'Imagen lista para análisis',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tamaño: ${((_processedImageBytes ?? _imageBytes)!.length / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                            if (_filtersApplied)
                              const Text(
                                'Filtros: Escala de grises, contraste +20%, brillo -30%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
