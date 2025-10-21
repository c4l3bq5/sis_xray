// lib/screens/user_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../services/auth_service.dart';
import '../models/user_models.dart';
import '../models/role_models.dart';
import '../services/user_service.dart';
import '../services/role_service.dart';

class UserFormScreen extends StatefulWidget {
  final Usuario? usuario;

  const UserFormScreen({super.key, this.usuario});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final RoleService _roleService = RoleService();

  late TextEditingController _nombreController;
  late TextEditingController _aPaternoController;
  late TextEditingController _aMaternoController;
  late TextEditingController _mailController;
  late TextEditingController _telefonoController;
  late TextEditingController _domicilioController;
  late TextEditingController _ciController;
  late TextEditingController _usuarioController;

  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  Rol? _rolSeleccionado;
  List<Rol> _roles = [];

  bool _isLoading = false;
  bool _cargandoRoles = true;
  bool get _isEditing => widget.usuario != null;

  final List<String> _generos = ['Masculino', 'Femenino', 'Otro'];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _cargarRoles();
  }

  void _initControllers() {
    if (_isEditing) {
      _nombreController = TextEditingController(text: widget.usuario!.nombre);
      _aPaternoController = TextEditingController(
        text: widget.usuario!.aPaterno,
      );
      _aMaternoController = TextEditingController(
        text: widget.usuario!.aMaterno ?? '',
      );
      _mailController = TextEditingController(text: widget.usuario!.mail ?? '');
      _usuarioController = TextEditingController(text: widget.usuario!.usuario);
      _telefonoController = TextEditingController();
      _domicilioController = TextEditingController();
      _ciController = TextEditingController();
    } else {
      _nombreController = TextEditingController();
      _aPaternoController = TextEditingController();
      _aMaternoController = TextEditingController();
      _mailController = TextEditingController();
      _usuarioController = TextEditingController();
      _telefonoController = TextEditingController();
      _domicilioController = TextEditingController();
      _ciController = TextEditingController();
    }

    // 🔥 Listener para generar usuario automáticamente
    if (!_isEditing) {
      _nombreController.addListener(_generarUsuario);
      _aPaternoController.addListener(_generarUsuario);
    }
  }

  // 🔥 Generar username automáticamente
  void _generarUsuario() {
    final nombre = _nombreController.text.trim();
    final apellido = _aPaternoController.text.trim();

    if (nombre.isNotEmpty && apellido.isNotEmpty) {
      final primeraLetra = nombre[0].toLowerCase();
      final apellidoClean = apellido.toLowerCase().replaceAll(' ', '');
      final random = Random().nextInt(99999).toString().padLeft(5, '0');

      final usuario = '$primeraLetra$apellidoClean$random';
      _usuarioController.text = usuario;
    }
  }

  Future<void> _cargarRoles() async {
    try {
      final roles = await _roleService.obtenerRoles();
      setState(() {
        _roles = roles;
        _cargandoRoles = false;
        if (_isEditing) {
          _rolSeleccionado = _roles.firstWhere(
            (r) => r.nombre == widget.usuario!.rolNombre,
            orElse: () =>
                _roles.isNotEmpty ? _roles[0] : Rol(id: 0, nombre: ''),
          );
        }
      });
    } catch (e) {
      setState(() => _cargandoRoles = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar roles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _aPaternoController.dispose();
    _aMaternoController.dispose();
    _mailController.dispose();
    _telefonoController.dispose();
    _domicilioController.dispose();
    _ciController.dispose();
    _usuarioController.dispose();
    super.dispose();
  }

  Future<void> _selectFecha(BuildContext context) async {
    // 🔥 Calcular fechas límite (18-70 años)
    final now = DateTime.now();
    final minDate = DateTime(now.year - 70, now.month, now.day);
    final maxDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona fecha de nacimiento (18-70 años)',
    );

    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  // 🔥 Validar CI único en el backend
  Future<bool> _validarCIUnico(String ci) async {
    try {
      final usuarios = await _userService.getUsuarios();
      return !usuarios.usuarios.any(
        (u) => u.ci == ci && (_isEditing ? u.id != widget.usuario!.id : true),
      );
    } catch (e) {
      return true; // Si falla la validación, permitir continuar
    }
  }

  // 🔥 Validar username único en el backend
  Future<bool> _validarUsuarioUnico(String usuario) async {
    try {
      final usuarios = await _userService.getUsuarios();
      return !usuarios.usuarios.any(
        (u) =>
            u.usuario.toLowerCase() == usuario.toLowerCase() &&
            (_isEditing ? u.id != widget.usuario!.id : true),
      );
    } catch (e) {
      return true;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha de nacimiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_generoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un género'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isEditing && _rolSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un rol'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🔥 Validar CI único
    if (!await _validarCIUnico(_ciController.text.trim())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El CI ya está registrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 🔥 Validar usuario único
    if (!await _validarUsuarioUnico(_usuarioController.text.trim())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre de usuario ya existe'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // ACTUALIZAR
        final dataPersona = {
          'nombre': _nombreController.text.trim(),
          'a_paterno': _aPaternoController.text.trim(),
          'a_materno': _aMaternoController.text.trim().isEmpty
              ? null
              : _aMaternoController.text.trim(),
          'fech_nac': _fechaNacimiento!.toIso8601String().split('T')[0],
          'telefono': _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          'mail': _mailController.text.trim().isEmpty
              ? null
              : _mailController.text.trim(),
          'ci': _ciController.text.trim(),
          'genero': _generoSeleccionado,
          'domicilio': _domicilioController.text.trim().isEmpty
              ? null
              : _domicilioController.text.trim(),
        };

        await _userService.actualizarDatosPersona(
          widget.usuario!.personaId,
          dataPersona,
        );

        final dataUsuario = {
          'usuario': _usuarioController.text.trim(),
          'rol_id': _rolSeleccionado!.id,
        };

        await _userService.actualizarUsuario(widget.usuario!.id, dataUsuario);

        final authService = AuthService();
        final currentUser = await authService.getUserData();

        if (currentUser != null && currentUser.id == widget.usuario!.id) {
          final usuarioActualizado = await _userService.getUsuarioById(
            widget.usuario!.id,
          );
          await authService.updateUserDataFromUsuario(usuarioActualizado);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Datos actualizados.'),
                backgroundColor: Color.fromARGB(255, 0, 156, 21),
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario actualizado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // CREAR
        final result = await _userService.crearUsuario(
          nombre: _nombreController.text.trim(),
          aPaterno: _aPaternoController.text.trim(),
          aMaterno: _aMaternoController.text.trim().isEmpty
              ? null
              : _aMaternoController.text.trim(),
          ci: _ciController.text.trim(),
          mail: _mailController.text.trim().isEmpty
              ? ''
              : _mailController.text.trim(),
          usuario: _usuarioController.text.trim(),
          rolId: _rolSeleccionado!.id,
          fechaNac: _fechaNacimiento!,
          genero: _generoSeleccionado!,
          telefono: _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          domicilio: _domicilioController.text.trim().isEmpty
              ? null
              : _domicilioController.text.trim(),
        );

        final passwordGenerada = result['passwordGenerada'] ?? 'N/A';
        print('🔑 Contraseña temporal recibida: $passwordGenerada');

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('✅ Usuario Creado Exitosamente'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'El usuario ha sido creado. Comparte esta contraseña temporal:',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      passwordGenerada,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '⚠️ El usuario debe cambiar esta contraseña en el primer inicio de sesión.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
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
          _isEditing ? 'Editar Usuario' : 'Crear Usuario',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _cargandoRoles && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isEditing) ...[
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              widget.usuario!.nombre
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.usuario!.usuario,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  _buildSectionTitle('Datos Personales', Icons.person),
                  const SizedBox(height: 16),

                  // 🔥 NOMBRE - Solo letras
                  TextFormField(
                    controller: _nombreController,
                    decoration: _inputDecoration(
                      'Nombre *',
                      Icons.person_outline,
                    ),
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                      ),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (value.length < 2) {
                        return 'Mínimo 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // 🔥 APELLIDO PATERNO - Solo letras
                      Expanded(
                        child: TextFormField(
                          controller: _aPaternoController,
                          decoration: _inputDecoration(
                            'Apellido Paterno *',
                            null,
                          ),
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                            ),
                            LengthLimitingTextInputFormatter(50),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obligatorio';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 🔥 APELLIDO MATERNO - Solo letras
                      Expanded(
                        child: TextFormField(
                          controller: _aMaternoController,
                          decoration: _inputDecoration(
                            'Apellido Materno',
                            null,
                          ),
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                            ),
                            LengthLimitingTextInputFormatter(50),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 🔥 CI - Solo números, exactamente 7 dígitos
                  TextFormField(
                    controller: _ciController,
                    decoration: _inputDecoration(
                      'CI * (7 dígitos)',
                      Icons.card_travel,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El CI es obligatorio';
                      }
                      if (value.length != 7) {
                        return 'El CI debe tener exactamente 7 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🔥 FECHA - 18-70 años
                  GestureDetector(
                    onTap: () => _selectFecha(context),
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        'Fecha de Nacimiento * (18-70 años)',
                        Icons.calendar_today,
                      ),
                      child: Text(
                        _fechaNacimiento == null
                            ? 'Selecciona una fecha'
                            : DateFormat(
                                'dd/MM/yyyy',
                              ).format(_fechaNacimiento!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _fechaNacimiento == null
                              ? Colors.grey[600]
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GÉNERO
                  DropdownButtonFormField<String>(
                    value: _generoSeleccionado,
                    decoration: _inputDecoration('Género *', Icons.wc),
                    items: _generos.map((genero) {
                      return DropdownMenuItem(
                        value: genero,
                        child: Text(genero),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _generoSeleccionado = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un género';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🔥 EMAIL - Validación estricta
                  TextFormField(
                    controller: _mailController,
                    decoration: _inputDecoration(
                      'Correo Electrónico *',
                      Icons.email,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 🔥 TELÉFONO - Solo números, exactamente 8 dígitos
                  TextFormField(
                    controller: _telefonoController,
                    decoration: _inputDecoration(
                      'Teléfono (8 dígitos)',
                      Icons.phone,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length != 8) {
                        return 'El teléfono debe tener exactamente 8 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // DOMICILIO
                  TextFormField(
                    controller: _domicilioController,
                    decoration: _inputDecoration(
                      'Domicilio',
                      Icons.location_on,
                    ),
                    maxLines: 2,
                    inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Información de Cuenta', Icons.lock),
                  const SizedBox(height: 16),

                  // 🔥 USUARIO - Generado automáticamente
                  TextFormField(
                    controller: _usuarioController,
                    decoration: _inputDecoration(
                      _isEditing
                          ? 'Usuario *'
                          : 'Usuario * (generado automáticamente)',
                      Icons.account_circle,
                    ),
                    enabled: _isEditing, // Solo editable al editar
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El usuario es obligatorio';
                      }
                      if (value.length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ROL
                  DropdownButtonFormField<Rol>(
                    value: _rolSeleccionado,
                    decoration: _inputDecoration('Rol *', Icons.badge),
                    items: _roles.map((rol) {
                      return DropdownMenuItem(
                        value: rol,
                        child: Text(rol.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _rolSeleccionado = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un rol';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // BOTÓN
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR USUARIO',
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
