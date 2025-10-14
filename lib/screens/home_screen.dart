// screens/home_screen.dart
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

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Traumatología'),
        backgroundColor: Colors.blueAccent,
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
                Icon(Icons.circle, color: Colors.white, size: 8),
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
            _buildQuickStats(),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildNextAppointments(),
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

  Widget _buildQuickStats() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatCard(
          title: 'Pacientes Hoy',
          value: '12',
          icon: Icons.people,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Citas Pendientes',
          value: '5',
          icon: Icons.event,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Radiografías',
          value: '8',
          icon: Icons.photo,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
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
          crossAxisCount: 3, // Más columnas para botones más pequeños
          crossAxisSpacing: 10, // Menos espacio entre botones
          mainAxisSpacing: 8,
          childAspectRatio: 1.0, // Más compactos
          children: [
            _ActionCard(
              title: 'Analizar\nRadiografía',
              icon: Icons.upload_file,
              iconSize: 24, // Icono mucho más pequeño
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => XRayScreen()),
                );
              },
            ),
            _ActionCard(
              title: 'Nuevo\nPaciente',
              icon: Icons.person_add,
              iconSize: 24,
              color: Colors.green,
              onTap: () {
                // Navegar a pantalla de nuevo paciente
              },
            ),
            _ActionCard(
              title: 'Ver\nHistoriales',
              icon: Icons.medical_services,
              iconSize: 24,
              color: Colors.orange,
              onTap: () {
                // Navegar a historiales
              },
            ),
            _ActionCard(
              title: 'Agendar\nCita',
              icon: Icons.calendar_today,
              iconSize: 24,
              color: Colors.purple,
              onTap: () {
                // Navegar a agendar cita
              },
            ),
            _ActionCard(
              title: 'Radiografías',
              icon: Icons.photo_library,
              iconSize: 24,
              color: Colors.red,
              onTap: () {
                // Navegar a radiografías
              },
            ),
            _ActionCard(
              title: 'Monitoreo',
              icon: Icons.monitor_heart,
              iconSize: 24,
              color: Colors.teal,
              onTap: () {
                // Navegar a monitoreo
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximas Citas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    radius: 16, // Avatar más pequeño
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  title: const Text(
                    'Juan Pérez',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Consulta de seguimiento',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: const Text(
                      '10:30 AM',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: Colors.blueAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  dense: true, // Hace el ListTile más compacto
                ),
                const Divider(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                  title: const Text(
                    'María García',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Evaluación post-operatoria',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: const Text(
                      '11:45 AM',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  dense: true,
                ),
              ],
            ),
          ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 8, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6), // Padding mínimo
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10, // Texto muy pequeño
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
