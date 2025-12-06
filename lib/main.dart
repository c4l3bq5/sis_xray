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
    print('🔍 Verificando autenticación...');

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
          print('  Usuario autenticado: ${user?.nombreCompleto}');
        }
      } else {
        print('   Token inválido o expirado');
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _currentUser = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('   Error en verificación: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
  }

  //   LOGOUT DEFINITIVO - Usa el navigatorKey global para forzar navegación
  void _handleLogoutSync() {
    print(' Iniciando proceso de logout...');

    try {
      // 1. Actualizar estado local PRIMERO
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _currentUser = null;
          _isLoading = false;
        });
        print('  Estado local limpiado');
      }

      // 2. Navegar usando el navigatorKey GLOBAL (esto es crucial para móvil)
      // Usar un delay mínimo para asegurar que el setState se complete
      Future.delayed(const Duration(milliseconds: 50), () {
        widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        print('  Navegación al login completada');
      });

      // 3. Limpiar sesión en el servidor en segundo plano
      _performAsyncLogout();
    } catch (e) {
      print('   Error en logout: $e');

      // Forzar navegación incluso si hay error
      widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  // Limpieza asíncrona en segundo plano
  Future<void> _performAsyncLogout() async {
    try {
      await _authService.logout();
      print('  Sesión cerrada en el servidor');
    } catch (e) {
      print('   Error cerrando sesión en servidor: $e');
      // No es crítico, la sesión local ya se limpió
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
                  'Verificando sesión...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    //   Usuario autenticado - Renderizar HomeScreen DIRECTAMENTE
    // NO navegar, solo renderizar - esto evita el problema del F5
    if (_isAuthenticated && _currentUser != null) {
      print(' Renderizando HomeScreen para: ${_currentUser!.nombreCompleto}');
      return HomeScreen(
        userName: _currentUser!.nombreCompleto,
        userRole: _currentUser!.rolFormateado,
        enTurno: true,
        onLogout: _handleLogoutSync,
      );
    }

    //  No autenticado - Mostrar LoginScreen
    print(' Usuario no autenticado - Mostrando LoginScreen');
    return const LoginScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
