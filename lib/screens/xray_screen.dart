import 'dart:io';
import 'dart:typed_data';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'dart:convert';
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

  Uint8List? _annotatedImageBytes;

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
        _apiResult = null;
      });

      //    LÓGICA DE CÁMARA - DEL PRIMER CÓDIGO QUE FUNCIONABA
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
          _applyFilters(); // Aplicar filtros automáticamente
        } else {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      //    LÓGICA DE GALERÍA - DEL SEGUNDO CÓDIGO
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final originalBytes = await pickedFile.readAsBytes();

        // Aplicar escala de grises también a imágenes de galería
        final processedBytes = await ImageProcessor.applyGrayscale(
          originalBytes,
        );

        if (!mounted) return;
        setState(() {
          _imageBytes = processedBytes;
          _selectedImage = File(pickedFile.path);
          _selectedSource = source;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imagen procesada ${source == ImageSource.camera ? 'desde cámara' : 'desde galería'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
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

      final processed = await ImageProcessor.applyGrayscale(_imageBytes!);

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
      _annotatedImageBytes = null;
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
    final imageToAnalyze = _imageBytes;

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

    debugPrint(' Enviando imagen ORIGINAL para análisis');
    debugPrint(
      ' Tamaño: ${(imageToAnalyze.length / 1024).toStringAsFixed(1)} KB',
    );

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
            Text('Analizando imagen original (calidad completa)...'),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final result = await ApiService.analyzeImage(imageToAnalyze);

      debugPrint(' Respuesta de la API:');
      debugPrint(result.toString());

      if (mounted) {
        setState(() {
          _apiResult = result;
          _isAnalyzing = false;

          if (result.containsKey('annotated_image_base64')) {
            final base64String = result['annotated_image_base64'] as String;
            _annotatedImageBytes = base64Decode(base64String);
            debugPrint(' Imagen anotada recibida');
          } else {
            _annotatedImageBytes = null;
            debugPrint(' No hay fracturas, sin imagen anotada');
          }
        });

        bool requiresAttention = false;

        // Opción 1: Si está en el root
        if (result.containsKey('requires_attention')) {
          requiresAttention = result['requires_attention'] as bool? ?? false;
        }
        // Opción 2: Si está dentro de fracture_analysis
        else if (result.containsKey('fracture_analysis')) {
          final fractureAnalysis =
              result['fracture_analysis'] as Map<String, dynamic>?;
          requiresAttention =
              fractureAnalysis?['requires_immediate_attention'] as bool? ??
              false;
        }

        // Contar fracturas
        int totalFractures = 0;

        if (result.containsKey('total_fractures')) {
          totalFractures = result['total_fractures'] as int? ?? 0;
        } else if (result.containsKey('fracture_analysis')) {
          final fractureAnalysis =
              result['fracture_analysis'] as Map<String, dynamic>?;
          totalFractures = fractureAnalysis?['total_fractures'] as int? ?? 0;
        }

        debugPrint(' Análisis completado:');
        debugPrint('  - Total fracturas: $totalFractures');
        debugPrint('  - Requiere atención: $requiresAttention');

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
      debugPrint(' Error en análisis: $e');

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
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

  Widget _buildImageComparison() {
    if (_annotatedImageBytes == null || _imageBytes == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            ' Comparación de Imágenes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),

          // Imagen Original
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Imagen Original',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _imageBytes!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Imagen Analizada
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Imagen Analizada',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Con Marcas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _annotatedImageBytes!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),

          // Leyenda
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '  Leyenda de Marcas:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildLegendItem(
                  Colors.red,
                  'Recuadro Rojo',
                  'Fractura confirmada',
                ),
                _buildLegendItem(
                  Colors.yellow,
                  'Recuadro Amarillo',
                  'Luxación',
                ),
                _buildLegendItem(
                  Colors.orange,
                  'Recuadro Naranja',
                  'Sospecha de microfractura',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
              ' Error en el Análisis',
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

    // ============ EXTRAER DATOS DE LA API ============
    String region = 'N/A';
    double confidence = 0.0;
    int detectedBones = 0;
    int totalFractures = 0;
    int alertCount = 0;
    int sicknessCount = 0;
    int majorFractures = 0;
    int microfractures = 0;
    int luxationCount = 0;
    bool requiresAttention = false;
    List<dynamic> fractureDetails = [];

    // Leer region_analysis
    if (result.containsKey('region_analysis')) {
      final regionAnalysis = result['region_analysis'] as Map<String, dynamic>?;
      region = regionAnalysis?['region']?.toString().toUpperCase() ?? 'N/A';
      confidence = regionAnalysis?['confidence'] as double? ?? 0.0;
    }

    // Leer segmentation
    if (result.containsKey('segmentation')) {
      final segmentation = result['segmentation'] as Map<String, dynamic>?;
      final detectedBonesList = segmentation?['detected_bones'] as List?;
      detectedBones = detectedBonesList?.length ?? 0;
    }

    if (result.containsKey('fracture_analysis')) {
      final fractureAnalysis =
          result['fracture_analysis'] as Map<String, dynamic>?;
      totalFractures = fractureAnalysis?['total_fractures'] as int? ?? 0;
      alertCount = fractureAnalysis?['alert_count'] as int? ?? 0;
      sicknessCount = fractureAnalysis?['sickness_count'] as int? ?? 0;
      majorFractures = fractureAnalysis?['major_fractures'] as int? ?? 0;
      microfractures = fractureAnalysis?['microfractures'] as int? ?? 0;
      luxationCount = fractureAnalysis?['luxation_count'] as int? ?? 0;
      requiresAttention =
          fractureAnalysis?['requires_immediate_attention'] as bool? ?? false;
      fractureDetails = fractureAnalysis?['fractures'] as List? ?? [];
    }

    // ============ DETERMINAR COLOR Y MENSAJE ============
    Color mainColor = Colors.green;
    String mainMessage = ' Sin Fracturas Evidentes';
    IconData mainIcon = Icons.check_circle;

    if (alertCount > 0) {
      mainColor = Colors.purple;
      mainMessage = ' ALERTA CRÍTICA';
      mainIcon = Icons.emergency;
    } else if (majorFractures > 0) {
      mainColor = Colors.red;
      mainMessage = ' FRACTURAS DETECTADAS';
      mainIcon = Icons.warning;
    } else if (luxationCount > 0) {
      mainColor = Colors.orange;
      mainMessage = ' LUXACIÓN DETECTADA';
      mainIcon = Icons.broken_image;
    } else if (sicknessCount > 0) {
      mainColor = Colors.blue;
      mainMessage = ' ENFERMEDAD DETECTADA';
      mainIcon = Icons.medical_services;
    } else if (microfractures > 0) {
      mainColor = Colors.amber;
      mainMessage = ' SOSPECHA DE MICROFRACTURA';
      mainIcon = Icons.visibility;
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: mainColor, width: 2),
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
          // ============ ENCABEZADO ============
          Row(
            children: [
              Icon(mainIcon, size: 40, color: mainColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mainMessage,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 30, thickness: 1.5),

          // ============ INFORMACIÓN BÁSICA ============
          _buildInfoRow(
            'Región Analizada',
            region,
            Icons.location_on,
            Colors.blueAccent,
          ),
          _buildInfoRow(
            'Nivel de Confianza',
            '${(confidence * 100).toStringAsFixed(1)}%',
            Icons.psychology,
            confidence > 0.8 ? Colors.green : Colors.orange,
          ),
          _buildInfoRow(
            'Estructuras Óseas',
            '$detectedBones huesos identificados',
            Icons.healing,
            Colors.deepPurple,
          ),

          const Divider(height: 24, thickness: 1),

          // ============ RESUMEN DE HALLAZGOS ============
          const Text(
            ' Resumen de Hallazgos:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          if (alertCount > 0)
            _buildHallazgoChip(' Alertas Críticas', alertCount, Colors.purple),

          if (sicknessCount > 0)
            _buildHallazgoChip(' Enfermedades', sicknessCount, Colors.blue),

          if (majorFractures > 0)
            _buildHallazgoChip(
              ' Fracturas Mayores',
              majorFractures,
              Colors.red,
            ),

          if (luxationCount > 0)
            _buildHallazgoChip(' Luxaciones', luxationCount, Colors.orange),

          if (microfractures > 0)
            _buildHallazgoChip(' Microfracturas', microfractures, Colors.amber),

          if (totalFractures == 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'No se detectaron hallazgos patológicos',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // ============ DETALLES POR CATEGORÍA ============
          if (fractureDetails.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              ' Detalles de Hallazgos:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Agrupar por tipo
            ...fractureDetails.map((item) {
              final fracture = item as Map<String, dynamic>;
              final type = fracture['type']?.toString() ?? 'FRACTURE';

              return _buildFractureCard(fracture, type);
            }).toList(),
          ],

          // ============ RECOMENDACIÓN CLÍNICA ============
          if (result.containsKey('clinical_recommendation')) ...[
            const Divider(height: 30, thickness: 1.5),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: requiresAttention ? Colors.orange[100] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: requiresAttention ? Colors.orange : Colors.blue,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information,
                        color: requiresAttention ? Colors.orange : Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recomendación Clínica',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result['clinical_recommendation'].toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (requiresAttention) ...[
                    const SizedBox(height: 12),
                    const Text(
                      ' Este sistema es de apoyo diagnóstico. Requiere validación por un profesional médico calificado.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ WIDGETS AUXILIARES ============

  Widget _buildHallazgoChip(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFractureCard(Map<String, dynamic> fracture, String type) {
    // Determinar color y emoji según tipo
    Color cardColor;
    String typeLabel;

    switch (type) {
      case 'ALERT':
        cardColor = Colors.purple;
        typeLabel = 'ALERTA CRÍTICA';
        break;
      case 'SICKNESS':
        cardColor = Colors.blue;
        typeLabel = 'ENFERMEDAD';
        break;
      case 'LUXATION':
        cardColor = Colors.orange;
        typeLabel = 'LUXACIÓN';
        break;
      default:
        cardColor = Colors.red;
        typeLabel = 'FRACTURA';
    }

    final affectedBone = fracture['affected_bone']?.toString() ?? 'Desconocido';
    final description = fracture['description']?.toString() ?? '';
    final fractureType = fracture['fracture_type'] as Map<String, dynamic>?;
    final management = fractureType?['management']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Descripción
          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cardColor.withOpacity(0.9),
              ),
            ),

          const SizedBox(height: 8),

          // Hueso afectado
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: cardColor),
              const SizedBox(width: 4),
              Text(
                'Hueso afectado: ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  affectedBone,
                  style: TextStyle(fontSize: 13, color: cardColor),
                ),
              ),
            ],
          ),

          // Manejo
          if (management.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cardColor.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.medical_services, size: 16, color: cardColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      management,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
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
                            'Esperando respuesta del servidor (cloudflare tunnel - colab)...',
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

                if (_apiResult != null && 
    _apiResult!['status'] == 'success' && 
    _annotatedImageBytes != null)
  Container(
    margin: const EdgeInsets.only(top: 20),
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        // Devolver datos al formulario
        Navigator.pop(context, {
          'originalImage': _imageBytes,
          'annotatedImage': _annotatedImageBytes,
          'analysisResult': _apiResult,
        });
      },
      icon: const Icon(Icons.arrow_forward, size: 24),
      label: const Text(
        'Continuar al Formulario',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    ),
  ),

                if (_annotatedImageBytes != null) _buildImageComparison(),

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
                                  ? ' Imagen optimizada para análisis'
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
                                'Filtros: Escala de grises aplicada',
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
