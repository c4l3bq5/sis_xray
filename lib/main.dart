import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/xray_screen.dart';
import 'screens/login_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/users_screen.dart';
import 'services/auth_service.dart';
import 'models/auth_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Traumatología',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/xray': (context) => const XRayScreen(),
        '/users': (context) => const UsersScreen(), // ✅ NUEVO
        '/patients': (context) => const Scaffold(
          body: Center(child: Text('Pacientes - Próximamente')),
        ),
        '/medical-history': (context) => const Scaffold(
          body: Center(child: Text('Historial Médico - Próximamente')),
        ),
        '/logs': (context) => const LogsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  UserData? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final bool isValid = await _authService.verifyToken();

      if (isValid) {
        final UserData? user = await _authService.getUserData();
        setState(() {
          _isAuthenticated = true;
          _currentUser = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error en verificación: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[700]!, Colors.blue[900]!],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(height: 20),
                Text(
                  'Verificando sesión...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isAuthenticated && _currentUser != null) {
      return HomeScreen(
        userName: _currentUser!.nombreCompleto,
        userRole: _currentUser!.rolFormateado,
        enTurno: true,
      );
    }

    return const LoginScreen();
  }
}
