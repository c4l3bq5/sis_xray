// screens/home_screen.dart - CON RESTRICCIONES DE ROL
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/responsive_navbar.dart';
import 'xray_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  final String userRole;
  final bool enTurno;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.enTurno,
  });

  bool get _esMedico {
    return userRole.toLowerCase().contains('médico') ||
        userRole.toLowerCase().contains('medico') ||
        userRole.toLowerCase().contains('interno');
  }

  bool _esAdministrador() {
    return userRole.toLowerCase().contains('administrador');
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistema de Traumatología',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: enTurno ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.white, size: 8),
                const SizedBox(width: 6),
                Text(
                  enTurno ? 'En turno' : 'Fuera',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: ResponsiveNavBar(
        currentUser: userName,
        userRole: userRole,
        enTurno: enTurno,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(greeting, context),
            const SizedBox(height: 20),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String greeting, BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueAccent, Colors.blue[700]!],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userRole,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, d MMMM y', 'es_ES').format(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    // Lista de acciones según el rol
    final List<Widget> actions = [];

    // Solo administradores pueden gestionar usuarios
    if (_esAdministrador()) {
      actions.add(
        _ActionCard(
          title: 'Gestión de Usuarios',
          icon: Icons.people,
          iconSize: 32,
          color: Colors.purple,
          onTap: () {
            Navigator.pushNamed(context, '/users');
          },
        ),
      );
    }

    // Todos pueden gestionar pacientes
    actions.add(
      _ActionCard(
        title: 'Gestión de Pacientes',
        icon: Icons.personal_injury,
        iconSize: 32,
        color: Colors.green,
        onTap: () {
          Navigator.pushNamed(context, '/patients');
        },
      ),
    );

    // Solo médicos e internos pueden analizar radiografías
    if (_esMedico) {
      actions.add(
        _ActionCard(
          title: 'Analizar Radiografía',
          icon: Icons.upload_file,
          iconSize: 32,
          color: Colors.blueAccent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const XRayScreen()),
            );
          },
        ),
      );
    }

    // Solo admin puede ver reportes (logs)
    if (_esAdministrador()) {
      actions.add(
        _ActionCard(
          title: 'Reportes',
          icon: Icons.assessment,
          iconSize: 32,
          color: Colors.teal,
          onTap: () {
            Navigator.pushNamed(context, '/logs');
          },
        ),
      );
    }

    // Historial médico para todos (próximamente)
    actions.add(
      _ActionCard(
        title: 'Historial Médico',
        icon: Icons.medical_services,
        iconSize: 32,
        color: Colors.orange,
        onTap: () {
          Navigator.pushNamed(context, '/medical-history');
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: actions,
        ),
      ],
    );
  }

  String _getGreeting(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double iconSize;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    this.iconSize = 24,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
