// lib/screens/password_recovery_screen.dart
import 'package:flutter/material.dart';
import '../services/password_recovery_service.dart';
import '../services/user_service.dart';
import 'verify_recovery_code_screen.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({Key? key}) : super(key: key);

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _recoveryService = PasswordRecoveryService();
  final _userService = UserService();
  
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleRecovery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _userData = null;
    });

    try {
      final identifier = _usernameController.text.trim();
      
      // PASO 1: Buscar usuario por CI o username en la API REST
      print('🔍 Buscando usuario por CI o username: $identifier');
      final userData = await _userService.getUserByIdentifier(identifier);
      
      if (userData['telefono'] == null || userData['telefono'].toString().isEmpty) {
        throw Exception('Usuario no tiene teléfono registrado');
      }

      setState(() {
        _userData = userData;
      });

      // PASO 2: Usar teléfono como identifier para el microservicio de recovery
      // El microservicio envía el código de WhatsApp a este número
      final phoneNumber = userData['telefono'];
      
      print('📞 Solicitando código de recuperación para: $identifier');
      final response = await _recoveryService.requestCode(identifier);

      if (!mounted) return;

      if (response.sent) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Código enviado a tu WhatsApp\n${_maskIdentifier(identifier)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navegar a la pantalla de verificación
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyRecoveryCodeScreen(
              identifier: identifier,
              expiresIn: response.expiresIn ?? 600,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
      // Mensajes de error amigables
      if (errorMsg.contains('Usuario no encontrado') || errorMsg.contains('404')) {
        errorMsg = 'Usuario no encontrado. Verifica que el nombre de usuario sea correcto.';
      } else if (errorMsg.contains('timeout')) {
        errorMsg = 'Tiempo de espera agotado. Por favor intenta nuevamente.';
      } else if (errorMsg.contains('SocketException') || errorMsg.contains('connection')) {
        errorMsg = 'Error de conexión. Verifica tu conexión a internet.';
      }
      
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _maskIdentifier(String identifier) {
    // Enmascarar CI o email para privacidad
    if (identifier.contains('@')) {
      // Es un email
      final parts = identifier.split('@');
      if (parts[0].length > 3) {
        return '${parts[0].substring(0, 3)}***@${parts[1]}';
      }
      return identifier;
    } else {
      // Es un CI
      if (identifier.length > 4) {
        return '${identifier.substring(0, 2)}***${identifier.substring(identifier.length - 2)}';
      }
      return identifier;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Ícono
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Título
                const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Descripción
                Text(
                  'Ingresa tu nombre de usuario y te enviaremos un código de verificación por WhatsApp.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Campo de username
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    hintText: 'Ej: juan.perez',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre de usuario';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleRecovery(),
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje de error
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Botón enviar código
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRecovery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Enviar código',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Info adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Proceso de recuperación',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Te enviaremos un código de 6 dígitos a tu WhatsApp\n'
                        '2. El código expirará en 10 minutos\n'
                        '3. Ingresa el código para crear una nueva contraseña',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Ayuda
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.help_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Text('Ayuda'),
                            ],
                          ),
                          content: const Text(
                            'Si no recuerdas tu nombre de usuario o no tienes acceso '
                            'a tu WhatsApp registrado, contacta al administrador del sistema.',
                            style: TextStyle(fontSize: 14, height: 1.5),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Entendido'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.help_outline, size: 18, color: Colors.grey.shade600),
                    label: Text(
                      '¿No puedes recuperar tu cuenta?',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}