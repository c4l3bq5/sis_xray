// lib/screens/medical_history_form_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/medical_history_models.dart';
import '../models/patient_models.dart';
import '../services/medical_history_service.dart';
import '../services/graphql_service.dart';
import 'xray_screen.dart';

class MedicalHistoryFormScreen extends StatefulWidget {
  final Paciente patient;
  final MedicalHistory? existingHistory;
  
  // Datos de imágenes (opcionales)
  final Uint8List? originalImageBytes;
  final Uint8List? annotatedImageBytes;
  final Map<String, dynamic>? analysisResult;

  const MedicalHistoryFormScreen({
    super.key,
    required this.patient,
    this.existingHistory,
    this.originalImageBytes,
    this.annotatedImageBytes,
    this.analysisResult,
  });

  @override
  State<MedicalHistoryFormScreen> createState() =>
      _MedicalHistoryFormScreenState();
}

class _MedicalHistoryFormScreenState extends State<MedicalHistoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _diagnosticoController;
  late TextEditingController _tratamientoController;
  late TextEditingController _avanceController;

  final MedicalHistoryService _medicalHistoryService = MedicalHistoryService();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasChanges = false;
  
  // Datos de imágenes
  Uint8List? _originalImageBytes;
  Uint8List? _annotatedImageBytes;
  Map<String, dynamic>? _analysisResult;
  
  bool get _isEditing => widget.existingHistory != null;
  bool get _hasImages => _originalImageBytes != null && _annotatedImageBytes != null;

  @override
  void initState() {
    super.initState();
    
    // Copiar imágenes del widget
    _originalImageBytes = widget.originalImageBytes;
    _annotatedImageBytes = widget.annotatedImageBytes;
    _analysisResult = widget.analysisResult;

    if (_isEditing) {
      _diagnosticoController = TextEditingController(
        text: widget.existingHistory!.diagnostico,
      );
      _tratamientoController = TextEditingController(
        text: widget.existingHistory!.tratamiento,
      );
      _avanceController = TextEditingController(
        text: widget.existingHistory!.avance ?? '',
      );
    } else {
      _diagnosticoController = TextEditingController();
      _tratamientoController = TextEditingController();
      _avanceController = TextEditingController();
    }

    _diagnosticoController.addListener(_onFieldChanged);
    _tratamientoController.addListener(_onFieldChanged);
    _avanceController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _tratamientoController.dispose();
    _avanceController.dispose();
    super.dispose();
  }

  // Helpers para obtener info del análisis
  String get _area {
    if (_analysisResult == null) return 'upper'; // default
    final regionAnalysis = _analysisResult!['region_analysis'] as Map<String, dynamic>?;
    final region = regionAnalysis?['region']?.toString().toLowerCase() ?? 'upper';
    return region.contains('lower') ? 'lower' : 'upper';
  }

  String get _annotationsText {
    if (_analysisResult == null) return 'Análisis pendiente';
    
    final fractureAnalysis = _analysisResult!['fracture_analysis'] as Map<String, dynamic>?;
    if (fractureAnalysis == null) return 'Sin hallazgos';
    
    final totalFractures = fractureAnalysis['total_fractures'] as int? ?? 0;
    if (totalFractures == 0) return 'No se detectaron fracturas';
    
    return 'Fracturas detectadas: $totalFractures';
  }

  bool get _hasFractures {
    if (_analysisResult == null) return false;
    final fractureAnalysis = _analysisResult!['fracture_analysis'] as Map<String, dynamic>?;
    final totalFractures = fractureAnalysis?['total_fractures'] as int? ?? 0;
    return totalFractures > 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _showDiscardDialog();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Editar Historial' : 'Crear Historial Clínico',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.blueAccent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 2,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildPatientInfo(),
              
              if (_hasImages) _buildImagesSection(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildSectionHeader(
                        'Diagnóstico',
                        Icons.medical_information,
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _diagnosticoController,
                        maxLines: 4,
                        decoration: _buildInputDecoration(
                          'Ingrese el diagnóstico del paciente...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El diagnóstico es requerido';
                          }
                          if (value.trim().length < 10) {
                            return 'El diagnóstico debe tener al menos 10 caracteres';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 20),

                      _buildSectionHeader(
                        'Tratamiento',
                        Icons.healing,
                        Colors.purple,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tratamientoController,
                        maxLines: 4,
                        decoration: _buildInputDecoration(
                          'Ingrese el tratamiento recomendado...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El tratamiento es requerido';
                          }
                          if (value.trim().length < 10) {
                            return 'El tratamiento debe tener al menos 10 caracteres';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[50]!, Colors.green[100]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green[300]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[600],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notas / Observaciones',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Observaciones adicionales del caso',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _avanceController,
                              maxLines: 5,
                              decoration:
                                  _buildInputDecoration(
                                    'Ejemplo:\n• Mejoría en los síntomas\n• Reducción del dolor\n• Buena respuesta al tratamiento',
                                  ).copyWith(
                                    fillColor: Colors.white,
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                              enabled: !_isLoading,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () => _handleCancel(),
                              icon: const Icon(Icons.close),
                              label: const Text('Cancelar'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
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
                              onPressed: _isLoading ? null : _handleSave,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isLoading
                                    ? 'Guardando...'
                                    : _isEditing
                                    ? 'Actualizar Historial'
                                    : 'Crear Historial',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[900]!],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                widget.patient.nombreCompleto.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Editando historial de:'
                      : 'Creando historial para:',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                Text(
                  widget.patient.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'CI: ${widget.patient.ci}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                ' Imágenes Radiológicas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: _handleChangeImages,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Cambiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          const Text(
            'Imagen Original:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _originalImageBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Imagen Analizada (con marcas):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _annotatedImageBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hasFractures ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _hasFractures ? Icons.warning : Icons.check_circle,
                  color: _hasFractures ? Colors.red : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _annotationsText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasFractures ? Colors.red[900] : Colors.green[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleChangeImages() async {
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cambiar imágenes?'),
        content: const Text(
          '¿Estás seguro de que quieres volver a analizar una nueva radiografía? '
          'Los datos actuales se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Sí, cambiar'),
          ),
        ],
      ),
    );

    if (shouldChange == true && mounted) {
      // Regresar a XRayScreen y esperar resultado
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const XRayScreen(),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _originalImageBytes = result['originalImage'] as Uint8List?;
          _annotatedImageBytes = result['annotatedImage'] as Uint8List?;
          _analysisResult = result['analysisResult'] as Map<String, dynamic>?;
          _hasChanges = true;
        });
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleCancel() async {
    if (_hasChanges) {
      final shouldPop = await _showDiscardDialog();
      if (shouldPop && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.patient.id == null) {
      setState(() {
        _errorMessage = 'Error: El paciente no tiene un ID válido';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final request = CreateMedicalHistoryRequest(
        pacienteId: widget.patient.id!,
        diagnostico: _diagnosticoController.text.trim(),
        tratamiento: _tratamientoController.text.trim(),
        avance: _avanceController.text.trim().isNotEmpty
            ? _avanceController.text.trim()
            : null,
      );

      MedicalHistory savedHistory;
      
      if (_isEditing) {
        savedHistory = await _medicalHistoryService.updateMedicalHistory(
          widget.existingHistory!.id,
          request,
        );
      } else {
        savedHistory = await _medicalHistoryService.createMedicalHistory(request);
        
        if (_hasImages) {
          await _uploadAndLinkImages(savedHistory.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? ' Historial actualizado exitosamente'
                  : ' Historial clínico creado exitosamente',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _uploadAndLinkImages(String clinicHistoryId) async {
    try {
      print('Subiendo imágenes a MongoDB...');
      
      final uploadResult = await GraphQLService.uploadRadImage(
        fileName: 'xray_${widget.patient.ci}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        imageBytes: _originalImageBytes!,
        maskBytes: _annotatedImageBytes!,
        mimetype: 'image/jpeg',
        area: _area,
        annotations: _annotationsText,
      );
      
      if (uploadResult['success'] == true) {
        final imageId = uploadResult['radImage']['id'] as String;
        print(' Imagen subida con ID: $imageId');
        
        await GraphQLService.linkImageToClinicHistory(
          imageId: imageId,
          clinicHistoryId: clinicHistoryId,
        );
        
        print(' Imagen vinculada al historial: $clinicHistoryId');
      }
    } catch (e) {
      print(' Error subiendo imágenes: $e');
    }
  }
}