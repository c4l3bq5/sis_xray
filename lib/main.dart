// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/xray_screen.dart';

void main() async {
  // IMPORTANTE: Inicializar binding antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar datos de localización para intl
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
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomeScreen(
          userName: 'Dr. Julio Torrejón',
          userRole: 'Traumatólogo',
          enTurno: true,
        ),
        '/xray': (context) => const XRayScreen(),
      },
    );
  }
}
