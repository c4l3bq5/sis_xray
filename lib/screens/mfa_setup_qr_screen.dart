// lib/screens/mfa_setup_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/mfa_service.dart';
import 'dart:convert';

/// Pantalla que muestra el QR para configurar Google Authenticator
class MFASetupQRScreen extends StatefulWidget {
  final int userId;
  final String username;

  const MFASetupQRScreen({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  _MFASetupQRScreenState createState() => _MFASetupQRScreenState();
}

class _MFASetupQRScreenState extends State<MFASetupQRScreen> {
  final MFAService _mfaService = MFAService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoadingSetup = true;
  bool _isVerifying = false;
  String _errorMessage = '';
  
  // Datos del setup MFA
  String? _qrCodeBase64;
  String? _secret;
  List<String>? _backupCodes;
  String? _otpauthUrl;

  @override
  void initState() {
    super.initState();
    _generateMFASetup();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _generateMFASetup() async {
    setState(() {
      _isLoadingSetup = true;
      _errorMessage = '';
    });

    try {
      print('🔐 Generando setup MFA para usuario ${widget.username}...');
      
      final setupData = await _mfaService.generateMFASetup(
        widget.userId,
        widget.username,
      );

      setState(() {
        _qrCodeBase64 = setupData['qrCode'];
        _secret = setupData['secret'];
        _backupCodes = List<String>.from(setupData['backupCodes'] ?? []);
        _otpauthUrl = setupData['otpauthUrl'];
        _isLoadingSetup = false;
      });

      print('✅ Setup MFA generado exitosamente');
    } catch (e) {
      print('❌ Error generando setup: $e');
      setState(() {
        _errorMessage = 'Error al generar configuración MFA: ${e.toString()}';
        _isLoadingSetup = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurar MFA'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: _isLoadingSetup
            ? _buildLoadingState()
            : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : _buildSetupContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green[700]),
          const SizedBox(height: 20),
          Text(
            'Generando código QR...',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _generateMFASetup,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text('Omitir por ahora'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paso 1: Escanear QR
          _buildStepCard(
            step: 1,
            title: 'Escanea el código QR',
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Abre Google Authenticator y escanea este código:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _qrCodeBase64 != null
                      ? Image.memory(
                          base64Decode(_qrCodeBase64!.split(',').last),
                          width: 250,
                          height: 250,
                          fit: BoxFit.contain,
                        )
                      : const SizedBox(
                          width: 250,
                          height: 250,
                          child: Center(child: Text('QR no disponible')),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Código manual (alternativa)
                if (_secret != null) ...[
                  Text(
                    'O ingresa este código manualmente:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _secret!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _secret!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Código copiado'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Paso 2: Verificar código
          _buildStepCard(
            step: 2,
            title: 'Verifica el código',
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Ingresa el código de 6 dígitos de Google Authenticator:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                
                // Mensaje de error
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
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Campos de código
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 60,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.green[700]!,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          // Auto-verificar cuando se complete
                          if (index == 5 && value.isNotEmpty) {
                            _verifyAndActivateMFA();
                          }
                        },
                        enabled: !_isVerifying,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Botón de verificar
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyAndActivateMFA,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'ACTIVAR MFA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Códigos de respaldo
          if (_backupCodes != null && _backupCodes!.isNotEmpty)
            _buildBackupCodesCard(),

          const SizedBox(height: 24),

          // Botón de omitir
          Center(
            child: TextButton(
              onPressed: () {
                _showSkipDialog();
              },
              child: Text(
                'Omitir configuración',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCodesCard() {
    return Card(
      elevation: 2,
      color: Colors.amber[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: Colors.amber[900]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Códigos de respaldo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Guarda estos códigos en un lugar seguro. Puedes usarlos si pierdes acceso a tu teléfono:',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ..._backupCodes!.map((code) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• $code',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyAndActivateMFA() async {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Por favor ingresa los 6 dígitos';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      print('🔐 Verificando y activando MFA...');
      
      final success = await _mfaService.activateMFA(
        widget.userId,
        code,
        _secret!,
      );

      if (success) {
        if (!mounted) return;

        // Mostrar mensaje de éxito
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                const Text('¡MFA Activado!'),
              ],
            ),
            content: const Text(
              'Tu cuenta ahora está protegida con autenticación de dos factores.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error activando MFA: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isVerifying = false;
      });
      
      // Limpiar campos
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('¿Omitir MFA?'),
          ],
        ),
        content: const Text(
          'Tu cuenta estará menos protegida sin MFA. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
            ),
            child: const Text('Continuar sin MFA'),
          ),
        ],
      ),
    );
  }
}