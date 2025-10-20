// lib/screens/patient_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient_models.dart';
import '../services/patient_service.dart';

class PatientFormScreen extends StatefulWidget {
  final Paciente? paciente; // Si es null, estamos creando uno nuevo

  const PatientFormScreen({super.key, this.paciente});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PatientService _patientService = PatientService();

  // Controladores para datos de persona
  late TextEditingController _ciController;
  late TextEditingController _nombreController;
  late TextEditingController _aPaternoController;
  late TextEditingController _aMaternoController;
  late TextEditingController _telefonoController;
  late TextEditingController _mailController;
  late TextEditingController _domicilioController;

  // Controladores para datos de paciente
  late TextEditingController _alergiasController;
  late TextEditingController _antecedentesController;
  late TextEditingController _estaturaController;
  late TextEditingController _provinciaController;

  DateTime? _selectedDate;
  String? _selectedGenero;
  String? _selectedGrupoSanguineo;
  bool _isLoading = false;

  final List<String> _generos = ['Masculino', 'Femenino'];
  final List<String> _gruposSanguineos = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.paciente != null) {
      final p = widget.paciente!;
      _ciController = TextEditingController(text: p.ci);
      _nombreController = TextEditingController(text: p.nombre);
      _aPaternoController = TextEditingController(text: p.aPaterno);
      _aMaternoController = TextEditingController(text: p.aMaterno ?? '');
      _telefonoController = TextEditingController(text: p.telefono ?? '');
      _mailController = TextEditingController(text: p.mail ?? '');
      _domicilioController = TextEditingController(text: p.domicilio ?? '');
      _alergiasController = TextEditingController(text: p.alergias ?? '');
      _antecedentesController = TextEditingController(
        text: p.antecedentes ?? '',
      );
      _estaturaController = TextEditingController(
        text: p.estatura?.toString() ?? '',
      );
      _provinciaController = TextEditingController(text: p.provincia ?? '');

      _selectedDate = DateTime.parse(p.fechNac);

      // Convertir género de 'M'/'F' a 'Masculino'/'Femenino'
      if (p.genero != null) {
        if (p.genero!.toLowerCase() == 'm' ||
            p.genero!.toLowerCase() == 'masculino') {
          _selectedGenero = 'Masculino';
        } else if (p.genero!.toLowerCase() == 'f' ||
            p.genero!.toLowerCase() == 'femenino') {
          _selectedGenero = 'Femenino';
        }
      }

      _selectedGrupoSanguineo =
          p.grupoSanguineo != null && p.grupoSanguineo!.isNotEmpty
          ? p.grupoSanguineo
          : null;
    } else {
      _ciController = TextEditingController();
      _nombreController = TextEditingController();
      _aPaternoController = TextEditingController();
      _aMaternoController = TextEditingController();
      _telefonoController = TextEditingController();
      _mailController = TextEditingController();
      _domicilioController = TextEditingController();
      _alergiasController = TextEditingController();
      _antecedentesController = TextEditingController();
      _estaturaController = TextEditingController();
      _provinciaController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _ciController.dispose();
    _nombreController.dispose();
    _aPaternoController.dispose();
    _aMaternoController.dispose();
    _telefonoController.dispose();
    _mailController.dispose();
    _domicilioController.dispose();
    _alergiasController.dispose();
    _antecedentesController.dispose();
    _estaturaController.dispose();
    _provinciaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione la fecha de nacimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGenero == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione el género'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedGrupoSanguineo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione el grupo sanguíneo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final paciente = Paciente(
        id: widget.paciente?.id,
        personaId: widget.paciente?.personaId ?? 0,
        ci: _ciController.text.trim(),
        nombre: _nombreController.text.trim(),
        aPaterno: _aPaternoController.text.trim(),
        aMaterno: _aMaternoController.text.trim().isEmpty
            ? null
            : _aMaternoController.text.trim(),
        fechNac: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        mail: _mailController.text.trim().isEmpty
            ? null
            : _mailController.text.trim(),
        genero: _selectedGenero!.toLowerCase() == 'masculino' ? 'M' : 'F',
        domicilio: _domicilioController.text.trim().isEmpty
            ? null
            : _domicilioController.text.trim(),
        grupoSanguineo: _selectedGrupoSanguineo!,
        alergias: _alergiasController.text.trim().isEmpty
            ? null
            : _alergiasController.text.trim(),
        antecedentes: _antecedentesController.text.trim().isEmpty
            ? null
            : _antecedentesController.text.trim(),
        estatura: _estaturaController.text.trim().isEmpty
            ? null
            : double.tryParse(_estaturaController.text.trim()),
        provincia: _provinciaController.text.trim().isEmpty
            ? null
            : _provinciaController.text.trim(),
        activo:
            widget.paciente?.activo ?? 'activo', // Mantener el estado actual
      );

      if (widget.paciente == null) {
        await _patientService.crearPaciente(paciente);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _patientService.actualizarPaciente(
          widget.paciente!.id!,
          paciente,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paciente == null ? 'Nuevo Paciente' : 'Editar Paciente',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // DATOS PERSONALES
            _buildSectionTitle('Datos Personales', Icons.person),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ciController,
              decoration: _inputDecoration(
                'Carnet de Identidad *',
                Icons.badge,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El CI es obligatorio';
                }
                return null;
              },
              enabled: true, // Solo editable al crear
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nombreController,
              decoration: _inputDecoration('Nombre *', Icons.person_outline),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _aPaternoController,
                    decoration: _inputDecoration('Apellido Paterno *', null),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Obligatorio';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _aMaternoController,
                    decoration: _inputDecoration('Apellido Materno', null),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: _inputDecoration(
                  'Fecha de Nacimiento *',
                  Icons.calendar_today,
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Seleccionar fecha'
                      : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedGenero,
              decoration: _inputDecoration('Género *', Icons.wc),
              items: _generos.map((genero) {
                return DropdownMenuItem(value: genero, child: Text(genero));
              }).toList(),
              onChanged: (value) => setState(() => _selectedGenero = value),
              validator: (value) {
                if (value == null) return 'Seleccione el género';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _telefonoController,
              decoration: _inputDecoration('Teléfono', Icons.phone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _mailController,
              decoration: _inputDecoration('Correo Electrónico', Icons.email),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _domicilioController,
              decoration: _inputDecoration('Domicilio', Icons.home),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // DATOS MÉDICOS
            _buildSectionTitle('Datos Médicos', Icons.medical_services),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedGrupoSanguineo,
              decoration: _inputDecoration(
                'Grupo Sanguíneo *',
                Icons.bloodtype,
              ),
              items: _gruposSanguineos.map((grupo) {
                return DropdownMenuItem(value: grupo, child: Text(grupo));
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedGrupoSanguineo = value),
              validator: (value) {
                if (value == null) return 'Seleccione el grupo sanguíneo';
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _estaturaController,
                    decoration: _inputDecoration('Estatura (m)', Icons.height),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _provinciaController,
                    decoration: _inputDecoration(
                      'Provincia',
                      Icons.location_city,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _alergiasController,
              decoration: _inputDecoration('Alergias', Icons.warning_amber),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _antecedentesController,
              decoration: _inputDecoration(
                'Antecedentes Médicos',
                Icons.history,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.paciente == null
                          ? 'CREAR PACIENTE'
                          : 'GUARDAR CAMBIOS',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
