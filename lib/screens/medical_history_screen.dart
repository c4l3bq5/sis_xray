// lib/screens/medical_history_screen.dart
import 'package:flutter/material.dart';
import '../models/patient_models.dart';
import '../models/medical_history_models.dart';
import '../services/medical_history_service.dart';
import 'medical_history_form_screen.dart';
import 'patient_history_detail_screen.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final MedicalHistoryService _medicalHistoryService = MedicalHistoryService();

  List<Paciente> _allPatients = [];
  Map<int, List<MedicalHistory>> _patientHistories = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cargar todos los pacientes
      final patients = await _medicalHistoryService.getAllPatients();

      // Cargar todos los historiales
      final allHistories = await _medicalHistoryService
          .getAllMedicalHistories();

      // Organizar historiales por paciente
      final Map<int, List<MedicalHistory>> historiesMap = {};
      for (var history in allHistories) {
        if (!historiesMap.containsKey(history.pacienteId)) {
          historiesMap[history.pacienteId] = [];
        }
        historiesMap[history.pacienteId]!.add(history);
      }

      // Ordenar historiales por fecha (más reciente primero)
      historiesMap.forEach((key, histories) {
        histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

      if (mounted) {
        setState(() {
          _allPatients = patients.where((p) => p.estaActivo).toList();
          _patientHistories = historiesMap;
          _isLoading = false;
        });
      }

      print('  Total pacientes activos: ${_allPatients.length}');
      print('📋 Pacientes con historial: ${historiesMap.length}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<Paciente> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _allPatients;
    }

    final query = _searchQuery.toLowerCase();
    return _allPatients.where((patient) {
      return patient.nombreCompleto.toLowerCase().contains(query) ||
          patient.ci.toLowerCase().contains(query);
    }).toList();
  }

  bool _hasHistory(int? patientId) {
    if (patientId == null) return false;
    return _patientHistories.containsKey(patientId) &&
        _patientHistories[patientId]!.isNotEmpty;
  }

  int _getHistoryCount(int? patientId) {
    if (patientId == null) return 0;
    return _patientHistories[patientId]?.length ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historiales Clínicos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final patientsWithHistory = _allPatients
        .where((p) => _hasHistory(p.id))
        .length;
    final patientsWithoutHistory = _allPatients.length - patientsWithHistory;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[700]!, Colors.blue[900]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Historiales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Administra los historiales clínicos de todos los pacientes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.people,
                  'Total',
                  _allPatients.length.toString(),
                  Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  Icons.check_circle,
                  'Con Historial',
                  patientsWithHistory.toString(),
                  Colors.green[300]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  Icons.add_circle,
                  'Sin Historial',
                  patientsWithoutHistory.toString(),
                  Colors.orange[300]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o CI...',
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando pacientes...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                onPressed: _loadAllData,
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

    if (_filteredPatients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No se encontraron pacientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Intenta con otro término de búsqueda',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredPatients.length,
        itemBuilder: (context, index) {
          final patient = _filteredPatients[index];
          final hasHistory = _hasHistory(patient.id);
          final historyCount = _getHistoryCount(patient.id);

          return _PatientCard(
            patient: patient,
            hasHistory: hasHistory,
            historyCount: historyCount,
            onTap: () => _handlePatientTap(patient, hasHistory),
          );
        },
      ),
    );
  }

  void _handlePatientTap(Paciente patient, bool hasHistory) async {
    if (hasHistory) {
      // Navegar a ver el historial completo
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientHistoryDetailScreen(
            patient: patient,
            histories: _patientHistories[patient.id!] ?? [],
          ),
        ),
      );

      if (result == true) {
        _loadAllData();
      }
    } else {
      // Navegar al formulario para crear
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicalHistoryFormScreen(
            patient: patient,
            isNewEntry: false, // Primer historial
          ),
        ),
      );

      if (result == true) {
        _loadAllData();
      }
    }
  }
}

class _PatientCard extends StatelessWidget {
  final Paciente patient;
  final bool hasHistory;
  final int historyCount;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.hasHistory,
    required this.historyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasHistory
                        ? [Colors.green[400]!, Colors.green[700]!]
                        : [Colors.orange[400]!, Colors.orange[700]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    patient.nombreCompleto.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información del paciente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'CI: ${patient.ci}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.edad} años',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasHistory
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasHistory
                              ? Colors.green[200]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasHistory ? Icons.check_circle : Icons.add_circle,
                            size: 12,
                            color: hasHistory
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasHistory
                                ? '$historyCount registro${historyCount > 1 ? 's' : ''}'
                                : 'Sin historial',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasHistory
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Icono de acción
              Icon(
                hasHistory ? Icons.visibility : Icons.add,
                color: hasHistory ? Colors.green[600] : Colors.orange[600],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
