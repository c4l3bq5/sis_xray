// lib/screens/patient_history_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient_models.dart';
import '../models/medical_history_models.dart';
import '../services/medical_history_service.dart';
import 'medical_history_form_screen.dart';

class PatientHistoryDetailScreen extends StatefulWidget {
  final Paciente patient;
  final List<MedicalHistory> histories;

  const PatientHistoryDetailScreen({
    super.key,
    required this.patient,
    required this.histories,
  });

  @override
  State<PatientHistoryDetailScreen> createState() =>
      _PatientHistoryDetailScreenState();
}

class _PatientHistoryDetailScreenState
    extends State<PatientHistoryDetailScreen> {
  final MedicalHistoryService _medicalHistoryService = MedicalHistoryService();

  late List<MedicalHistory> _histories;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _histories = widget.histories;
  }

  Future<void> _refreshHistories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final histories = await _medicalHistoryService.getHistoryByPatient(
        widget.patient.id!,
      );

      setState(() {
        _histories = histories;
        _histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recargar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial Clínico',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshHistories,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPatientInfo(),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Expanded(child: _buildHistoryList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEntry(),
        backgroundColor: Colors.green[600],
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Registro'),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.patient.nombreCompleto.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paciente',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      widget.patient.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.badge, 'CI', widget.patient.ci),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.cake, 'Edad', '${widget.patient.edad} años'),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.medical_services,
            'Total Registros',
            '${_histories.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_histories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sin Registros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aún no hay registros en el historial clínico',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshHistories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _histories.length,
        itemBuilder: (context, index) {
          final history = _histories[index];
          final isFirst = index == 0;

          return _HistoryCard(
            history: history,
            isLatest: isFirst,
            onEdit: () => _navigateToEdit(history),
          );
        },
      ),
    );
  }

  void _navigateToEdit(MedicalHistory history) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicalHistoryFormScreen(
          patient: widget.patient,
          previousHistory: history,
          isNewEntry: true, // Nuevo registro/avance
        ),
      ),
    );

    if (result == true) {
      _refreshHistories();
    }
  }

  void _navigateToAddEntry() async {
    // Si ya tiene historiales, vamos al último para agregar un avance
    if (_histories.isNotEmpty) {
      final latestHistory = _histories.first;
      _navigateToEdit(latestHistory);
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final MedicalHistory history;
  final bool isLatest;
  final VoidCallback onEdit;

  const _HistoryCard({
    required this.history,
    required this.isLatest,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: isLatest ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLatest
            ? BorderSide(color: Colors.green[400]!, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLatest ? Colors.green[50] : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isLatest ? Colors.green[700] : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(history.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLatest
                              ? Colors.green[700]
                              : Colors.grey[700],
                        ),
                      ),
                      if (isLatest) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Registro más reciente',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isLatest)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACTIVO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Diagnóstico',
                  history.diagnostico,
                  Icons.medical_information,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildSection(
                  'Tratamiento',
                  history.tratamiento,
                  Icons.healing,
                  Colors.purple,
                ),
                if (history.avance != null && history.avance!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSection(
                    'Avance / Notas',
                    history.avance!,
                    Icons.notes,
                    Colors.orange,
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Registrar Nueva Consulta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLatest
                      ? Colors.green[600]
                      : Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
