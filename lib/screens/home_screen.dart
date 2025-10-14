import 'package:flutter/material.dart';
import 'xray_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Fracturas Óseas'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 100, color: Colors.blue),
            SizedBox(height: 30),
            Text(
              'Análisis de Radiografías',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 15),
            Text(
              'Detecta fracturas óseas usando IA',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a la pantalla X-Ray
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => XRayScreen()),
                );
              },
              icon: Icon(Icons.upload_file, size: 24),
              label: Text('Comenzar Análisis', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Selecciona una radiografía para analizar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
