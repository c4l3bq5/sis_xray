// lib/screens/login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/mfa_service.dart';
import '../models/auth_models.dart';
import '../theme/app_colors.dart';
import 'mfa_verification_screen.dart';
import 'first_login_change_password_screen.dart';
import 'mfa_setup_screen.dart';
import 'password_recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final MFAService _mfaService = MFAService();
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _usuarioFocusNode = FocusNode();
  final _contrasenaFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  // Bloqueo temporal por demasiados intentos
  bool _isBlocked = false;
  int _blockSecondsRemaining = 0;
  Timer? _blockTimer;

  void _startBlockCountdown(int minutes) {
    _blockTimer?.cancel();
    setState(() {
      _isBlocked = true;
      _blockSecondsRemaining = minutes * 60;
      _errorMessage = '';
    });
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _blockSecondsRemaining--;
      });
      if (_blockSecondsRemaining <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isBlocked = false;
            _blockSecondsRemaining = 0;
          });
        }
      }
    });
  }

  String get _blockCountdownText {
    final mins = _blockSecondsRemaining ~/ 60;
    final secs = _blockSecondsRemaining % 60;
    if (mins > 0) {
      return '$mins min ${secs.toString().padLeft(2, '0')} seg';
    }
    return '${secs} seg';
  }

  @override
  void dispose() {
    _blockTimer?.cancel();
    _usuarioController.dispose();
    _contrasenaController.dispose();
    _usuarioFocusNode.dispose();
    _contrasenaFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.azulOscuroLogo, AppColors.tealTurquesaSanitario],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.tealTurquesaSanitario, AppColors.azulOscuroLogo],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.azulOscuroLogo.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Título
                          const Text(
                            'Radilens',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.azulOscuroLogo,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bienvenido de nuevo',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Banner de error / bloqueo
                          if (_isBlocked) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_clock,
                                      color: Colors.orange[800], size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Demasiados intentos fallidos',
                                          style: TextStyle(
                                            color: Colors.orange[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cuenta bloqueada. Intenta de nuevo en:',
                                          style: TextStyle(
                                            color: Colors.orange[800],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _blockCountdownText,
                                          style: TextStyle(
                                            color: Colors.orange[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ] else if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                    size: 20,
                                  ),
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

                          TextFormField(
                            controller: _usuarioController,
                            focusNode: _usuarioFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColors.azulOscuroLogo,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.azulOscuroLogo,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su usuario';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              _contrasenaFocusNode.requestFocus();
                            },
                            enabled: !_isLoading && !_isBlocked,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _contrasenaController,
                            focusNode: _contrasenaFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.azulOscuroLogo,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.azulOscuroLogo,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su contraseña';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            enabled: !_isLoading && !_isBlocked,
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading || _isBlocked
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PasswordRecoveryScreen(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.azulOscuroLogo,
                              ),
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading || _isBlocked ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.naranjaCalido,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _isBlocked
                                          ? 'BLOQUEADO'
                                          : 'INICIAR SESIÓN',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            '¿Necesitas ayuda? Contacta al administrador',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    _usuarioFocusNode.unfocus();
    _contrasenaFocusNode.unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final loginRequest = LoginRequest(
        usuario: _usuarioController.text.trim(),
        contrasena: _contrasenaController.text,
      );

      print(' Intentando login...');
      final response = await _authService.login(loginRequest);

      if (response.success && response.data != null) {
        final data = response.data!;

        if (data.requiresPasswordChange == true) {
          print(' Usuario tiene contraseña temporal, redirigiendo...');
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FirstLoginChangePasswordScreen(
                userId: data.userId ?? data.user.id,
                username: data.user.usuario,
                tempToken: data.token,
              ),
            ),
          );
          return;
        }

        if (data.requiresMFA == true) {
          print(' Usuario requiere MFA, redirigiendo...');
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MFAVerificationScreen(
                userId: data.userId ?? data.user.id,
                username: data.user.usuario,
                tempToken: data.token,
              ),
            ),
          );
          return;
        }

        print(' Login exitoso, guardando sesión...');
        await _authService.saveSession(response);

        print(' Verificando estado de MFA...');
        final hasMFAEnabled = await _mfaService.checkMFAStatus(data.user.id);

        print(' MFA Status: $hasMFAEnabled');

        if (!mounted) return;

        if (!hasMFAEnabled) {
          print(' Usuario sin MFA, mostrando prompt de configuración...');
          
          final userData = await _authService.getUserData(forceRefresh: true);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MFASetupScreen(
                userId: data.user.id,
                username: data.user.usuario,
                userName: userData?.nombreCompleto ?? data.user.usuario,
                userRole: userData?.rolFormateado ?? 'Usuario',
              ),
            ),
          );
        } else {
          print(' Usuario con MFA, navegando al home...');
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(' Error en login: $e');
      final msg = e.toString().replaceAll('Exception: ', '');

      // Detectar bloqueo temporal: "Usuario bloqueado temporalmente. Intenta en X minuto(s)"
      final blockMatch =
          RegExp(r'Intenta en (\d+) minuto').firstMatch(msg);
      if (blockMatch != null) {
        final minutes = int.tryParse(blockMatch.group(1) ?? '10') ?? 10;
        _startBlockCountdown(minutes);
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    }
  }
}