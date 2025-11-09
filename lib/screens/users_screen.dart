// lib/screens/users_screen.dart
import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../services/user_service.dart';
import 'user_form_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _userService = UserService();
  List<Usuario> _usuarios = [];
  List<Usuario> _usuariosActivos = [];
  List<Usuario> _usuariosInactivos = [];
  bool _isLoading = true;
  bool _mostrarActivos = true; // Solo mostrar activos por defecto
  bool _mostrarInactivos = false; // No mostrar inactivos por defecto
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _userService.getUsuarios();
      setState(() {
        _usuarios = response.usuarios;
        _usuariosActivos = _usuarios.where((u) => u.estaActivo).toList();
        _usuariosInactivos = _usuarios.where((u) => !u.estaActivo).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Usuario> get _usuariosFiltrados {
    print(
      'Debug: _mostrarActivos=$_mostrarActivos, _mostrarInactivos=$_mostrarInactivos',
    );
    print(
      'Debug: activos=${_usuariosActivos.length}, inactivos=${_usuariosInactivos.length}',
    );

    List<Usuario> resultado = [];

    if (_mostrarActivos) {
      resultado.addAll(_usuariosActivos);
    }
    if (_mostrarInactivos) {
      resultado.addAll(_usuariosInactivos);
    }

    print('Debug: resultado=${resultado.length}');
    return resultado;
  }

  Future<void> _toggleUsuarioEstado(Usuario usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          usuario.estaActivo ? 'Desactivar Usuario' : 'Activar Usuario',
        ),
        content: Text(
          usuario.estaActivo
              ? '¿Desactivar a ${usuario.nombreCompleto}?'
              : '¿Activar a ${usuario.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              usuario.estaActivo ? 'Desactivar' : 'Activar',
              style: TextStyle(
                color: usuario.estaActivo ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (usuario.estaActivo) {
          await _userService.desactivarUsuario(usuario.id);
        } else {
          await _userService.activarUsuario(usuario.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                usuario.estaActivo
                    ? 'Usuario desactivado correctamente'
                    : 'Usuario activado correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsuarios();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString().replaceAll('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                if (value == 'activos') {
                  _mostrarActivos = !_mostrarActivos;
                } else if (value == 'inactivos') {
                  _mostrarInactivos = !_mostrarInactivos;
                } else if (value == 'todos') {
                  _mostrarActivos = true;
                  _mostrarInactivos = true;
                } else if (value == 'limpiar') {
                  _mostrarActivos = true;
                  _mostrarInactivos = false;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'activos',
                child: Row(
                  children: [
                    Icon(
                      _mostrarActivos
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    const Text('Activos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'inactivos',
                child: Row(
                  children: [
                    Icon(
                      _mostrarInactivos
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text('Inactivos'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'todos', child: Text('Mostrar todos')),
              const PopupMenuItem(
                value: 'limpiar',
                child: Text('Solo activos'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildError()
          : _usuariosFiltrados.isEmpty
          ? _buildEmpty()
          : _buildUsersList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserFormScreen(usuario: null),
            ),
          ).then((result) {
            if (result == true) {
              _loadUsuarios();
            }
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Usuario'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUsuarios,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios con los filtros seleccionados',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsuarios,
      child: Column(
        children: [
          if (_usuarios.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCounter(
                    'Total',
                    _usuarios.length.toString(),
                    Colors.blue,
                  ),
                  _buildCounter(
                    'Activos',
                    _usuariosActivos.length.toString(),
                    Colors.green,
                  ),
                  _buildCounter(
                    'Inactivos',
                    _usuariosInactivos.length.toString(),
                    Colors.red,
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuariosFiltrados.length,
              itemBuilder: (context, index) {
                final usuario = _usuariosFiltrados[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  color: usuario.estaActivo ? Colors.white : Colors.grey[100],
                  child: Opacity(
                    opacity: usuario.estaActivo ? 1.0 : 0.6,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: usuario.estaActivo
                            ? Colors.blue[100]
                            : Colors.grey[300],
                        child: Text(
                          usuario.nombre.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: usuario.estaActivo
                                ? Colors.blue[700]
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        usuario.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(usuario.usuario),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.badge,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(usuario.rolNombre),
                            ],
                          ),
                          if (usuario.mail != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    usuario.mail!,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: usuario.estaActivo
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: usuario.estaActivo
                                        ? Colors.green[200]!
                                        : Colors.red[200]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      usuario.estaActivo
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 14,
                                      color: usuario.estaActivo
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      usuario.estadoFormatado,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: usuario.estaActivo
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (usuario.mfaActivo)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.security,
                                        size: 14,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'MFA',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserFormScreen(usuario: usuario),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _loadUsuarios();
                              }
                            });
                          } else if (value == 'toggle') {
                            _toggleUsuarioEstado(usuario);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  usuario.estaActivo
                                      ? Icons.block
                                      : Icons.check_circle,
                                  color: usuario.estaActivo
                                      ? Colors.red
                                      : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  usuario.estaActivo ? 'Desactivar' : 'Activar',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
