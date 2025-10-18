// widgets/responsive_navbar.dart - VERSIÓN DEFINITIVA CON RESTRICCIONES
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class ResponsiveNavBar extends StatelessWidget {
  final String currentUser;
  final String userRole;
  final bool enTurno;

  const ResponsiveNavBar({
    super.key,
    required this.currentUser,
    required this.userRole,
    required this.enTurno,
  });

  bool get _esMedico {
    final roleLower = userRole.toLowerCase();
    return roleLower.contains('médico') ||
        roleLower.contains('medico') ||
        roleLower.contains('interno');
  }

  bool get _esAdministrador {
    return userRole.toLowerCase().contains('administrador');
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    navigator.pop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => PopScope(
        canPop: false,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      ),
    );

    try {
      await authService.logout().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Timeout en logout, forzando cierre de sesión');
        },
      );

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('❌ Error en logout: $e');
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () => _handleLogout(context),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          currentUser.isNotEmpty
                              ? currentUser.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userRole,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: enTurno ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                enTurno ? 'En turno' : 'Fuera de turno',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items del menú
          _buildDrawerItem(
            icon: Icons.home,
            title: 'Inicio',
            onTap: () => Navigator.pop(context),
          ),

          _buildDrawerItem(
            icon: Icons.people,
            title: 'Usuarios',
            onTap: () => Navigator.pop(context),
          ),

          _buildDrawerItem(
            icon: Icons.personal_injury,
            title: 'Pacientes',
            onTap: () => Navigator.pop(context),
          ),

          _buildDrawerItem(
            icon: Icons.monitor_heart,
            title: 'Monitoreo',
            onTap: () => Navigator.pop(context),
          ),

          // ✅ SOLO MOSTRAR SI ES MÉDICO O INTERNO
          if (_esMedico)
            _buildDrawerItem(
              icon: Icons.upload_file,
              title: 'Analizar Radiografía',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/xray');
              },
            ),

          const Divider(),

          // Item de logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 22),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}
