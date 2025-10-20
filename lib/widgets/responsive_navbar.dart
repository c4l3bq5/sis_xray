// widgets/responsive_navbar.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResponsiveNavBar extends StatelessWidget {
  final String currentUser;
  final String userRole;
  final bool enTurno;
  final VoidCallback? onLogout;

  const ResponsiveNavBar({
    super.key,
    required this.currentUser,
    required this.userRole,
    required this.enTurno,
    this.onLogout,
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del drawer
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

          // Lista de opciones
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Inicio - Para todos
                ListTile(
                  leading: const Icon(
                    Icons.home,
                    color: Colors.blueAccent,
                    size: 22,
                  ),
                  title: const Text('Inicio', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),

                // Usuarios - Solo admin
                if (_esAdministrador)
                  ListTile(
                    leading: const Icon(
                      Icons.people,
                      color: Colors.blueAccent,
                      size: 22,
                    ),
                    title: const Text(
                      'Usuarios',
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/users');
                    },
                  ),

                // Pacientes - Para todos
                ListTile(
                  leading: const Icon(
                    Icons.personal_injury,
                    color: Colors.blueAccent,
                    size: 22,
                  ),
                  title: const Text(
                    'Pacientes',
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/patients');
                  },
                ),

                // Reportes - Solo admin
                if (_esAdministrador)
                  ListTile(
                    leading: const Icon(
                      Icons.assessment,
                      color: Colors.blueAccent,
                      size: 22,
                    ),
                    title: const Text(
                      'Reportes',
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/logs');
                    },
                  ),

                // Analizar Radiografía - Solo médicos e internos
                if (_esMedico)
                  ListTile(
                    leading: const Icon(
                      Icons.upload_file,
                      color: Colors.blueAccent,
                      size: 22,
                    ),
                    title: const Text(
                      'Analizar Radiografía',
                      style: TextStyle(fontSize: 14),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/xray');
                    },
                  ),

                const Divider(),

                // Cerrar sesión
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 22,
                  ),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    // Guardar el context del scaffold ANTES de abrir el dialog
    final scaffoldContext = context;

    final result = await showDialog<bool>(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );

    if (result == true) {
      _performLogout(scaffoldContext);
    }
  }

  void _performLogout(BuildContext context) {
    print(' Iniciando logout desde ResponsiveNavBar...');

    Navigator.of(context, rootNavigator: false).pop();
    print(' Drawer cerrado');

    Future.microtask(() {
      print(' Ejecutando en microtask...');
      if (onLogout != null) {
        print(' Ejecutando callback onLogout');
        onLogout!();
        print(' Callback ejecutado');
      } else {
        print(' ERROR: No hay callback onLogout');
        _fallbackLogout(context);
      }
    });
  }

  // Fallback solo por seguridad (no debería usarse)
  void _fallbackLogout(BuildContext context) {
    print(' Usando fallback de logout');

    // Intentar logout y navegar de forma síncrona
    AuthService()
        .logout()
        .then((_) {
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        })
        .catchError((e) {
          print('Error en fallback: $e');
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
  }
}
