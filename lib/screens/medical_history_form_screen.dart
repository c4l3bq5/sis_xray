// lib/screens/medical_history_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medical_history_models.dart';
import '../models/patient_models.dart';
import '../services/medical_history_service.dart';

class MedicalHistoryFormScreen extends StatefulWidget {
  final Paciente patient;
  final MedicalHistory? previousHistory; // Historial anterior para referencia
  final bool
  isNewEntry; // true = nuevo registro/avance, false = primer historial

  const MedicalHistoryFormScreen({
    super.key,
    required this.patient,
    this.previousHistory,
    this.isNewEntry = false,
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

  @override
  void initState() {
    super.initState();

    // Si es un nuevo registro/avance, pre-llenar con datos del historial anterior
    if (widget.isNewEntry && widget.previousHistory != null) {
      _diagnosticoController = TextEditingController(
        text: widget.previousHistory!.diagnostico,
      );
      _tratamientoController = TextEditingController(
        text: widget.previousHistory!.tratamiento,
      );
      _avanceController = TextEditingController();
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
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _diagnosticoController.dispose();
    _tratamientoController.dispose();
    _avanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isNewEntry = widget.isNewEntry;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
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
            isNewEntry ? 'Nuevo Registro / Avance' : 'Crear Primer Historial',
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

              if (isNewEntry && widget.previousHistory != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registro Anterior:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(
                                    widget.previousHistory!.createdAt,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diagnóstico previo:',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.previousHistory!.diagnostico,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.previousHistory!.avance != null &&
                                widget.previousHistory!.avance!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Último avance:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.previousHistory!.avance!,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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

                      if (isNewEntry)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Puedes actualizar el diagnóstico y tratamiento, y agregar notas sobre el progreso del paciente',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

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
                          isNewEntry
                              ? 'Actualizar o mantener el diagnóstico...'
                              : 'Ingrese el diagnóstico del paciente...',
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
                          isNewEntry
                              ? 'Actualizar o mantener el tratamiento...'
                              : 'Ingrese el tratamiento recomendado...',
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isNewEntry
                                            ? '¿Qué avances observaste hoy?'
                                            : 'Notas / Observaciones (Opcional)',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        isNewEntry
                                            ? 'Registra la evolución del paciente en esta consulta'
                                            : 'Observaciones iniciales del caso',
                                        style: const TextStyle(
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
                                    'Ejemplo:\n• Mejoría en los síntomas\n• Reducción del dolor\n• Buena respuesta al tratamiento\n• Próxima cita en...',
                                  ).copyWith(
                                    fillColor: Colors.white,
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                              validator: isNewEntry
                                  ? (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Por favor registra el avance de esta consulta';
                                      }
                                      return null;
                                    }
                                  : null,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isNewEntry
                                        ? 'Se creará un nuevo registro con la fecha y hora actual'
                                        : 'Se guardará como el primer registro del historial',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
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
                                    : isNewEntry
                                    ? 'Guardar Nuevo Registro'
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
                  widget.isNewEntry
                      ? 'Nueva consulta de:'
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

      await _medicalHistoryService.createMedicalHistory(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isNewEntry
                  ? '  Nuevo registro agregado al historial'
                  : '  Historial clínico creado exitosamente',
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
}
