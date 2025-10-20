import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/xray_screen.dart';
import 'screens/login_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/users_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/medical_history_screen.dart';
import 'services/auth_service.dart';
import 'models/auth_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Traumatología',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: _navigatorKey,
      home: AuthWrapper(navigatorKey: _navigatorKey),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/xray': (context) => const XRayScreen(),
        '/users': (context) => const UsersScreen(),
        '/patients': (context) => const PatientsScreen(),
        '/medical-history': (context) => const MedicalHistoryScreen(),
        '/logs': (context) => const LogsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AuthWrapper({super.key, required this.navigatorKey});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
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
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _currentUser = user;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _currentUser = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error en verificación: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
  }

  // Método mejorado para manejar el logout
  Future<void> _handleLogout() async {
    print('🔄 Iniciando proceso de logout desde AuthWrapper...');

    try {
      // Realizar logout en el servicio
      await _authService.logout();

      if (mounted) {
        // Actualizar estado a no autenticado
        setState(() {
          _isAuthenticated = false;
          _currentUser = null;
          _isLoading = false;
        });

        print('✅ Logout completado exitosamente - Estado actualizado');
        print('   _isAuthenticated: $_isAuthenticated');
        print('   _currentUser: $_currentUser');
      }
    } catch (e) {
      print('❌ Error durante logout: $e');

      // Aún si hay error, limpiar sesión localmente
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _currentUser = null;
          _isLoading = false;
        });
        print('⚠️ Sesión limpiada localmente después de error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga
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
                  'Cargando...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Usuario autenticado - mostrar HomeScreen
    if (_isAuthenticated && _currentUser != null) {
      return HomeScreen(
        userName: _currentUser!.nombreCompleto,
        userRole: _currentUser!.rolFormateado,
        enTurno: true,
        onLogout: _handleLogout, // Pasar el callback correcto
      );
    }

    // No autenticado - mostrar LoginScreen
    return const LoginScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
