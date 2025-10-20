// lib/models/medical_history_models.dart

/// Modelo de historial clínico
class MedicalHistory {
  final int id;
  final int pacienteId;
  final int usuarioId;
  final String diagnostico;
  final String tratamiento;
  final String? fotoAnalizada;
  final String? avance;
  final String estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos adicionales de relaciones
  final String? nombrePaciente;
  final String? nombreDoctor;

  MedicalHistory({
    required this.id,
    required this.pacienteId,
    required this.usuarioId,
    required this.diagnostico,
    required this.tratamiento,
    this.fotoAnalizada,
    this.avance,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    this.nombrePaciente,
    this.nombreDoctor,
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      id: json['id'] ?? 0,
      pacienteId: json['paciente_id'] ?? 0,
      usuarioId: json['usuario_id'] ?? 0,
      diagnostico: json['diagnostico'] ?? '',
      tratamiento: json['tratamiento'] ?? '',
      fotoAnalizada: json['foto_analizada'],
      avance: json['avance'],
      estado: json['estado'] ?? 'activo',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      nombrePaciente: json['nombre_paciente'],
      nombreDoctor: json['nombre_doctor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paciente_id': pacienteId,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'foto_analizada': fotoAnalizada,
      'avance': avance,
    };
  }
}

/// Request para crear historial clínico
class CreateMedicalHistoryRequest {
  final int pacienteId;
  final String diagnostico;
  final String tratamiento;
  final String? fotoAnalizada;
  final String? avance;

  CreateMedicalHistoryRequest({
    required this.pacienteId,
    required this.diagnostico,
    required this.tratamiento,
    this.fotoAnalizada,
    this.avance,
  });

  Map<String, dynamic> toJson() {
    return {
      'paciente_id': pacienteId,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      if (fotoAnalizada != null) 'foto_analizada': fotoAnalizada,
      if (avance != null) 'avance': avance,
    };
  }
}

/// Response genérico de la API
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }
}
