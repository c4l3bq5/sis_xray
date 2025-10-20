// lib/screens/patients_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient_models.dart';
import '../services/patient_service.dart';
import '../services/auth_service.dart';
import 'patient_screen_form.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];
  PacienteStats? _stats;
  bool _isLoading = true;
  bool _isSearching = false;
  String _errorMessage = '';
  String _userRole = '';

  // Variables para filtros de estado
  bool _mostrarActivos = true;
  bool _mostrarInactivos = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _userRole = userData.rolFormateado;
        });
      }
    } catch (e) {
      print('Error cargando rol: $e');
    }
  }

  bool get _esMedico {
    return _userRole.toLowerCase().contains('médico') ||
        _userRole.toLowerCase().contains('medico') ||
        _userRole.toLowerCase().contains('interno');
  }

  bool get _esAdmin {
    return _userRole.toLowerCase().contains('administrador');
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // INCLUIR PACIENTES INACTIVOS
      final response = await _patientService.getPacientes(
        includeInactive: true,
      );
      final stats = await _patientService.getStats();

      setState(() {
        _pacientes = response.pacientes;
        _pacientesFiltrados = response.pacientes;
        _stats = stats;
        _isLoading = false;
      });

      // Aplicar filtros después de cargar los datos
      _filterPacientes(_searchController.text);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _filterPacientes(String query) {
    setState(() {
      List<Paciente> baseList = _pacientes;

      // Aplicar filtro por estado
      List<Paciente> filteredByStatus = [];
      if (_mostrarActivos) {
        filteredByStatus.addAll(baseList.where((p) => p.estaActivo));
      }
      if (_mostrarInactivos) {
        filteredByStatus.addAll(baseList.where((p) => !p.estaActivo));
      }

      // Aplicar filtro de búsqueda
      if (query.isEmpty) {
        _pacientesFiltrados = filteredByStatus;
      } else {
        _pacientesFiltrados = filteredByStatus.where((p) {
          final nombreCompleto = p.nombreCompleto.toLowerCase();
          final ci = p.ci.toLowerCase();
          final searchLower = query.toLowerCase();
          return nombreCompleto.contains(searchLower) ||
              ci.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _togglePacienteEstado(Paciente paciente) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          paciente.estaActivo ? 'Desactivar Paciente' : 'Activar Paciente',
        ),
        content: Text(
          paciente.estaActivo
              ? '¿Desactivar a ${paciente.nombreCompleto}?'
              : '¿Activar a ${paciente.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              paciente.estaActivo ? 'Desactivar' : 'Activar',
              style: TextStyle(
                color: paciente.estaActivo ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (paciente.estaActivo) {
          await _patientService.desactivarPaciente(paciente.id!);
        } else {
          await _patientService.activarPaciente(paciente.id!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                paciente.estaActivo
                    ? 'Paciente desactivado correctamente'
                    : 'Paciente activado correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
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

  void _showPacienteDetails(Paciente paciente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _buildPacienteDetails(paciente, scrollController),
      ),
    );
  }

  Widget _buildPacienteDetails(
    Paciente paciente,
    ScrollController scrollController,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: scrollController,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[100],
                child: Text(
                  paciente.nombre.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paciente.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'CI: ${paciente.ci}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoSection('Información Personal', [
            _buildInfoRow(Icons.cake, 'Edad', '${paciente.edad} años'),
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha de Nacimiento',
              DateFormat('dd/MM/yyyy').format(DateTime.parse(paciente.fechNac)),
            ),
            _buildInfoRow(Icons.person, 'Sexo', paciente.sexoFormatado),
            _buildInfoRow(
              Icons.bloodtype,
              'Grupo Sanguíneo',
              paciente.grupoSanguineo,
            ),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Contacto', [
            if (paciente.telefono != null)
              _buildInfoRow(Icons.phone, 'Teléfono', paciente.telefono!),
            if (paciente.domicilio != null)
              _buildInfoRow(
                Icons.location_on,
                'Dirección',
                paciente.domicilio!,
              ),
            if (paciente.mail != null)
              _buildInfoRow(Icons.email, 'Correo', paciente.mail!),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Información Médica Adicional', [
            if (paciente.alergias != null)
              _buildInfoRow(Icons.warning, 'Alergias', paciente.alergias!),
            if (paciente.antecedentes != null)
              _buildInfoRow(
                Icons.history,
                'Antecedentes',
                paciente.antecedentes!,
              ),
            if (paciente.estatura != null)
              _buildInfoRow(Icons.height, 'Estatura', '${paciente.estatura} m'),
            if (paciente.provincia != null)
              _buildInfoRow(
                Icons.location_city,
                'Provincia',
                paciente.provincia!,
              ),
          ]),
          const SizedBox(height: 24),
          Row(
            children: [
              // Botón Editar - Solo médicos e internos
              if (_esMedico) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PatientFormScreen(paciente: paciente),
                        ),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Botón Ver Historial - Solo médicos e internos
              if (_esMedico)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navegar a historial médico
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Ver Historial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              // Botón Cambiar Estado - Solo admin
              if (_esAdmin)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _togglePacienteEstado(paciente);
                    },
                    icon: Icon(
                      paciente.estaActivo ? Icons.block : Icons.check_circle,
                    ),
                    label: Text(paciente.estaActivo ? 'Desactivar' : 'Activar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: paciente.estaActivo
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o CI...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterPacientes,
              )
            : const Text(
                'Gestión de Pacientes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          // Botón de filtros - NUEVO
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
              _filterPacientes(_searchController.text); // Re-aplicar filtros
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
          // Botón de búsqueda existente
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterPacientes('');
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildError()
          : Column(
              children: [
                if (_stats != null) _buildStatsCard(),
                Expanded(
                  child: _pacientesFiltrados.isEmpty
                      ? _buildEmpty()
                      : _buildPacientesList(),
                ),
              ],
            ),
      // FAB solo para médicos e internos
      floatingActionButton: _esMedico
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientFormScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Paciente'),
              backgroundColor: Colors.blueAccent,
            )
          : null,
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                _stats!.total.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatItem(
                'Activos',
                _stats!.activos.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatItem(
                'Inactivos',
                _stats!.inactivos.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
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
              onPressed: _loadData,
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
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ||
                    (!_mostrarActivos && !_mostrarInactivos)
                ? 'No se encontraron pacientes con los filtros seleccionados'
                : 'No hay pacientes registrados',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPacientesList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pacientesFiltrados.length,
        itemBuilder: (context, index) {
          final paciente = _pacientesFiltrados[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            color: paciente.estaActivo ? Colors.white : Colors.grey[100],
            child: Opacity(
              opacity: paciente.estaActivo ? 1.0 : 0.6,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: paciente.estaActivo
                      ? Colors.blue[100]
                      : Colors.grey[300],
                  child: Text(
                    paciente.nombre.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: paciente.estaActivo
                          ? Colors.blue[700]
                          : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  paciente.nombreCompleto,
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
                        Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('CI: ${paciente.ci}'),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${paciente.edad} años'),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.bloodtype,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(paciente.grupoSanguineo),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: paciente.estaActivo
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: paciente.estaActivo
                              ? Colors.green[200]!
                              : Colors.red[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paciente.estaActivo
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 14,
                            color: paciente.estaActivo
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paciente.estadoFormatado,
                            style: TextStyle(
                              fontSize: 12,
                              color: paciente.estaActivo
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
                onTap: () => _showPacienteDetails(paciente),
              ),
            ),
          );
        },
      ),
    );
  }
}
