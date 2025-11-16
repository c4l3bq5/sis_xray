// lib/screens/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/responsive_navbar.dart';
import '../services/auth_service.dart';
import '../services/log_service.dart';
import '../services/graphql_service.dart';
import '../models/log_models.dart';
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
  final LogService _logService = LogService();

  LogStats? _stats;
  Map<String, int>? _actionsSummary;
  List<Log>? _recentLogs;
  List<Map<String, dynamic>>? _recentXRayImages;
  bool _isLoading = true;
  bool _isLoadingImages = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
    _currentUserRole = widget.userRole;
    _loadDashboardData();
    
    // Cargar imágenes SOLO si es médico Y NO es administrador
    if (_esMedico && !_esAdministrador()) {
      _loadRecentXRayImages();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  Future<void> _loadDashboardData() async {
    if (!_esAdministrador()) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Cargando datos del dashboard...');
      
      final results = await Future.wait([
        _logService.getStats(),
        _logService.getActionsSummary(),
        _logService.getRecentActivity(limit: 10),
      ]);

      print('Datos cargados exitosamente');

      if (mounted) {
        setState(() {
          _stats = results[0] as LogStats;
          _actionsSummary = results[1] as Map<String, int>;
          _recentLogs = (results[2] as LogsResponse).logs;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error cargando datos del dashboard: $e');
      print('Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar los datos: ${e.toString()}';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadDashboardData,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadRecentXRayImages() async {
    setState(() => _isLoadingImages = true);

    try {
      print('🔍 Cargando últimas 10 imágenes de RadImages...');
      
      List<Map<String, dynamic>> images;
      
      try {
        images = await GraphQLService.getRecentRadImages(limit: 10);
      } catch (e) {
        print('⚠️ recentRadImages no disponible, usando getAllRadImages...');
        final allImages = await GraphQLService.getAllRadImages();
        images = allImages.take(10).toList();
      }
      
      if (mounted) {
        setState(() {
          _recentXRayImages = images;
          _isLoadingImages = false;
        });
      }
      
      print('✅ Total imágenes cargadas: ${images.length}');
    } catch (e) {
      print('❌ Error cargando imágenes de RadImages: $e');
      if (mounted) {
        setState(() {
          _recentXRayImages = [];
          _isLoadingImages = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron cargar las imágenes: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

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
      body: _isLoading && _esAdministrador()
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de bienvenida
                  _buildWelcomeHeader(greeting),
                  const SizedBox(height: 24),
                  
                  // 🔥 NUEVO ORDEN: Imágenes PRIMERO (solo médicos NO administradores)
                  if (_esMedico && !_esAdministrador()) ...[
                    _buildRecentXRaySection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Acciones rápidas para todos
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  
                  // Dashboard SOLO para administradores (al final)
                  if (_esAdministrador()) ...[
                    if (_errorMessage != null) ...[
                      _buildErrorCard(),
                      const SizedBox(height: 24),
                    ]
                    else if (_stats != null) ...[
                      _buildStatsCards(),
                      const SizedBox(height: 24),
                      if (isWideScreen)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildRecentActivity(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionsSummary(),
                            ),
                          ],
                        )
                      else ...[
                        _buildRecentActivity(),
                        const SizedBox(height: 16),
                        _buildActionsSummary(),
                      ],
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.dashboard,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Cargando estadísticas...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error al cargar datos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage ?? 'Error desconocido',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              color: Colors.red[700],
              tooltip: 'Reintentar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String greeting) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueAccent, Colors.blue[700]!],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $_currentUserName!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUserRole,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM y', 'es_ES').format(DateTime.now()),
                    style: const TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _esAdministrador()
                    ? Icons.admin_panel_settings
                    : _esMedico
                        ? Icons.medical_services
                        : Icons.person,
                size: 48,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel de Control',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _CompactStatItem(
              title: 'Total Logs',
              value: _stats!.totalLogs.toString(),
              subtitle: 'Registros totales',
              icon: Icons.description,
              color: Colors.blue,
            ),
            const Divider(height: 24),
            _CompactStatItem(
              title: 'Usuarios Activos',
              value: _stats!.usuariosActivos.toString(),
              subtitle: 'Con actividad',
              icon: Icons.people,
              color: Colors.purple,
            ),
            const Divider(height: 24),
            _CompactStatItem(
              title: 'Acciones Hoy',
              value: _stats!.logsHoy.toString(),
              subtitle: 'Registradas hoy',
              icon: Icons.today,
              color: Colors.green,
              badge: _stats!.logsHoy > 10 ? 'Alta' : null,
            ),
            const Divider(height: 24),
            _CompactStatItem(
              title: 'Inserciones',
              value: _stats!.inserciones.toString(),
              subtitle: 'Nuevos registros',
              icon: Icons.add_circle,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_recentLogs == null || _recentLogs!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Actividad Reciente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('No hay actividad reciente'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actividad Reciente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/logs'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Ver todo'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Últimas acciones en el sistema',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentLogs!.length > 5 ? 5 : _recentLogs!.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final log = _recentLogs![index];
                return _ActivityItem(log: log);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSummary() {
    if (_actionsSummary == null || _actionsSummary!.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedActions = _actionsSummary!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Frecuentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Top operaciones',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...sortedActions.take(5).map((entry) {
              final maxValue = sortedActions.first.value.toDouble();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatActionName(entry.key),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getActionColor(entry.key).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getActionColor(entry.key),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: entry.value / maxValue,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getActionColor(entry.key),
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final List<_QuickAction> actions = [];

    // Usuarios - Solo administradores
    if (_esAdministrador()) {
      actions.add(_QuickAction(
        title: 'Usuarios',
        subtitle: 'Administrar usuarios',
        icon: Icons.people,
        color: Colors.purple,
        route: '/users',
      ));
    }

    // Pacientes - Todos
    actions.add(_QuickAction(
      title: 'Pacientes',
      subtitle: 'Gestionar pacientes',
      icon: Icons.personal_injury,
      color: Colors.green,
      route: '/patients',
    ));

    // Radiografías - Solo médicos
    if (_esMedico) {
      actions.add(_QuickAction(
        title: 'Radiografías',
        subtitle: 'Analizar imágenes',
        icon: Icons.upload_file,
        color: Colors.blueAccent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const XRayScreen()),
        ),
      ));
    }

    // Reportes - Solo administradores
    if (_esAdministrador()) {
      actions.add(_QuickAction(
        title: 'Reportes',
        subtitle: 'Ver logs del sistema',
        icon: Icons.assessment,
        color: Colors.teal,
        route: '/logs',
      ));
    }

    // Historiales - Solo médicos (NO administradores)
    if (_esMedico && !_esAdministrador()) {
      actions.add(_QuickAction(
        title: 'Historiales',
        subtitle: 'Consultar registros',
        icon: Icons.medical_services,
        color: Colors.orange,
        route: '/medical-history',
      ));
    }

    // Para administradores: botones compactos
    if (_esAdministrador()) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acceso Rápido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map((action) => _CompactActionButton(action: action)).toList(),
          ),
        ],
      );
    }

    // Para otros roles: tarjetas normales
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _QuickActionCard(action: action);
              },
            );
          },
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

  String _formatActionName(String action) {
    return action.replaceAll('_', ' ').split(' ').map((word) {
      return word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Color _getActionColor(String action) {
    if (action.contains('crear') || action.contains('INSERT')) return Colors.green;
    if (action.contains('actualizar') || action.contains('editar') || action.contains('UPDATE')) return Colors.blue;
    if (action.contains('eliminar') || action.contains('borrar') || action.contains('DELETE')) return Colors.red;
    if (action.contains('login') || action.contains('logout') || action.contains('sesion')) return Colors.purple;
    return Colors.orange;
  }

  Widget _buildRecentXRaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Radiografías Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isLoadingImages && _recentXRayImages != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_recentXRayImages!.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: _loadRecentXRayImages,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Recargar imágenes',
              color: Colors.blueAccent,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Últimas imágenes analizadas de la colección RadImages',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingImages)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando imágenes desde MongoDB...'),
                  ],
                ),
              ),
            ),
          )
        else if (_recentXRayImages == null || _recentXRayImages!.isEmpty)
          _buildEmptyXRayCard()
        else
          _buildXRayGrid(),
      ],
    );
  }

  Widget _buildEmptyXRayCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay imágenes analizadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las radiografías analizadas aparecerán aquí',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const XRayScreen()),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Analizar Radiografía'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXRayGrid() {
    final itemsToShow = _recentXRayImages!.length > 10 
        ? 10 
        : _recentXRayImages!.length;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: itemsToShow,
      itemBuilder: (context, index) {
        final image = _recentXRayImages![index];
        return _XRayImageCard(imageData: image);
      },
    );
  }
}

// Widget compacto para estadísticas
class _CompactStatItem extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;

  const _CompactStatItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Widget para mostrar una tarjeta de imagen radiológica
class _XRayImageCard extends StatelessWidget {
  final Map<String, dynamic> imageData;

  const _XRayImageCard({required this.imageData});

  @override
  Widget build(BuildContext context) {
    final fileName = imageData['fileName'] as String? ?? 'Sin nombre';
    final uploadDate = imageData['uploadDate'] != null
        ? DateTime.parse(imageData['uploadDate'] as String)
        : DateTime.now();
    final annotations = imageData['annotations'] as String? ?? '';
    final hasFractures = annotations.toLowerCase().contains('fractura');
    final area = imageData['area'] as String? ?? 'unknown';
    
    final imageBase64 = imageData['mask'] as String? ?? imageData['image'] as String? ?? '';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showImageDetails(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[900],
                child: imageBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(imageBase64),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[600],
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                          size: 32,
                        ),
                      ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName.length > 15
                        ? '${fileName.substring(0, 15)}...'
                        : fileName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatImageDate(uploadDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: area == 'upper' ? Colors.blue[50] : Colors.purple[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          area == 'upper' ? 'SUP' : 'INF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: area == 'upper' ? Colors.blue[700] : Colors.purple[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasFractures ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasFractures ? Icons.warning : Icons.check_circle,
                          size: 10,
                          color: hasFractures ? Colors.red[700] : Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasFractures ? 'Fractura' : 'Normal',
                          style: TextStyle(
                            fontSize: 10,
                            color: hasFractures ? Colors.red[700] : Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatImageDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return DateFormat('dd/MM/yy').format(date);
  }

  void _showImageDetails(BuildContext context) {
    final imageBase64 = imageData['mask'] as String? ?? imageData['image'] as String? ?? '';
    final annotations = imageData['annotations'] as String? ?? 'Sin análisis disponible';
    final fileName = imageData['fileName'] as String? ?? 'Sin nombre';
    final clinicHistoryId = imageData['clinicHistoryId'] as String?;
    final area = imageData['area'] as String? ?? 'unknown';
    final uploadDate = imageData['uploadDate'] != null
        ? DateTime.parse(imageData['uploadDate'] as String)
        : DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Subida: ${DateFormat('dd/MM/yyyy HH:mm').format(uploadDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[900],
                  child: imageBase64.isNotEmpty
                      ? InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.memory(
                            base64Decode(imageBase64),
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.layers,
                            label: 'Área',
                            value: area == 'upper' ? 'Superior' : 'Inferior',
                            color: area == 'upper' ? Colors.blue : Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (clinicHistoryId != null)
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.link,
                              label: 'Historial',
                              value: 'Vinculada',
                              color: Colors.green,
                            ),
                          )
                        else
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.link_off,
                              label: 'Historial',
                              value: 'Sin vincular',
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    const Text(
                      'Análisis de la radiografía:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        annotations,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Log log;

  const _ActivityItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForAction(log.accion);
    final color = _getColorForAction(log.accion);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.nombreUsuario ?? log.usuario ?? 'Usuario desconocido',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  log.accion,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(log.timestamp),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAction(String action) {
    if (action.contains('INSERT') || action.contains('crear')) return Icons.add_circle_outline;
    if (action.contains('UPDATE') || action.contains('actualizar') || action.contains('editar')) {
      return Icons.edit_outlined;
    }
    if (action.contains('DELETE') || action.contains('eliminar')) return Icons.delete_outline;
    if (action.contains('login') || action.contains('sesion')) return Icons.login;
    if (action.contains('logout')) return Icons.logout;
    return Icons.info_outline;
  }

  Color _getColorForAction(String action) {
    if (action.contains('INSERT') || action.contains('crear')) return Colors.green;
    if (action.contains('UPDATE') || action.contains('actualizar') || action.contains('editar')) {
      return Colors.blue;
    }
    if (action.contains('DELETE') || action.contains('eliminar')) return Colors.red;
    if (action.contains('login') || action.contains('logout') || action.contains('sesion')) {
      return Colors.purple;
    }
    return Colors.orange;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return DateFormat('dd/MM').format(dateTime);
  }
}

class _CompactActionButton extends StatelessWidget {
  final _QuickAction action;

  const _CompactActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap ?? () {
          if (action.route != null) {
            Navigator.pushNamed(context, action.route!);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: action.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: action.color, size: 20),
              const SizedBox(width: 8),
              Text(
                action.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: action.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
  final VoidCallback? onTap;

  _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
    this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: action.onTap ?? () {
          if (action.route != null) {
            Navigator.pushNamed(context, action.route!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}