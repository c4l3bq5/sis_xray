// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/responsive_navbar.dart';
import '../services/auth_service.dart';
import 'xray_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final bool enTurno;
  final VoidCallback? onLogout;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.enTurno,
    this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _currentUserName;
  late String _currentUserRole;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
    _currentUserRole = widget.userRole;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cada vez que volvemos a esta pantalla
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _currentUserName = userData.nombreCompleto;
          _currentUserRole = userData.rolFormateado;
        });
      }
    } catch (e) {
      print('Error cargando datos del usuario: $e');
    }
  }

  bool get _esMedico {
    return _currentUserRole.toLowerCase().contains('médico') ||
        _currentUserRole.toLowerCase().contains('medico') ||
        _currentUserRole.toLowerCase().contains('interno');
  }

  bool _esAdministrador() {
    return _currentUserRole.toLowerCase().contains('administrador');
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
              color: widget.enTurno ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Colors.white, size: 8),
                const SizedBox(width: 6),
                Text(
                  widget.enTurno ? 'En turno' : 'Fuera',
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
        currentUser: _currentUserName,
        userRole: _currentUserRole,
        enTurno: widget.enTurno,
        onLogout: widget.onLogout,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(greeting),
            const SizedBox(height: 20),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String greeting) {
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
              '$greeting, $_currentUserName!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUserRole,
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
    final List<Widget> actions = [];

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
