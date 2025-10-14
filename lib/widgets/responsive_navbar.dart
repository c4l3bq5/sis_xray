// widgets/responsive_navbar.dart
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header del drawer con información del usuario - CORREGIDO
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, // Alinea al fondo
              children: [
                Row(
                  children: [
                    // Avatar más pequeño y mejor posicionado
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          currentUser.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Espacio adecuado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
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
                          // Rol
                          Text(
                            userRole,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Estado de turno
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

          // Items del menú (se mantienen igual)
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Inicio',
            onTap: () {
              Navigator.popAndPushNamed(context, '/home');
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Usuarios',
            onTap: () {
              Navigator.popAndPushNamed(context, '/usuarios');
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.personal_injury,
            title: 'Pacientes',
            onTap: () {
              Navigator.popAndPushNamed(context, '/pacientes');
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.monitor_heart,
            title: 'Monitoreo',
            onTap: () {
              Navigator.popAndPushNamed(context, '/monitoreo');
            },
          ),

          const Divider(),

          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blueAccent,
        size: 22,
      ), // Iconos un poco más pequeños
      title: Text(
        title,
        style: const TextStyle(fontSize: 14), // Texto un poco más pequeño
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
      ), // Padding consistente
      minLeadingWidth: 0, // Reduce el espacio mínimo del leading
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar dialog
                Navigator.popAndPushNamed(context, '/login');
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
