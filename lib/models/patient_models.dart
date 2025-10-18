// lib/models/patient_models.dart
class Paciente {
  final int? id;
  final int personaId;
  final String grupoSanguineo;
  final String? alergias;
  final String? antecedentes;
  final double? estatura;
  final String? provincia;
  final String activo;

  // Datos de la persona relacionada
  final String nombre;
  final String aPaterno;
  final String? aMaterno;
  final String fechNac;
  final String? telefono;
  final String? mail;
  final String ci;
  final String? genero;
  final String? domicilio;

  Paciente({
    this.id,
    required this.personaId,
    required this.grupoSanguineo,
    this.alergias,
    this.antecedentes,
    this.estatura,
    this.provincia,
    required this.activo,
    required this.nombre,
    required this.aPaterno,
    this.aMaterno,
    required this.fechNac,
    this.telefono,
    this.mail,
    required this.ci,
    this.genero,
    this.domicilio,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'],
      personaId: json['persona_id'] ?? 0,
      grupoSanguineo: json['grupo_sanguineo'] ?? '',
      alergias: json['alergias'],
      antecedentes: json['antecedentes'],
      estatura: json['estatura'] != null
          ? double.tryParse(json['estatura'].toString())
          : null,
      provincia: json['provincia'],
      activo: json['activo'] ?? 'inactivo',
      nombre: json['nombre'] ?? '',
      aPaterno: json['a_paterno'] ?? '',
      aMaterno: json['a_materno'],
      fechNac: json['fech_nac'] ?? '',
      telefono: json['telefono'],
      mail: json['mail'],
      ci: json['ci'] ?? '',
      genero: json['genero'],
      domicilio: json['domicilio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'persona': {
        'nombre': nombre,
        'a_paterno': aPaterno,
        'a_materno': aMaterno,
        'fech_nac': fechNac,
        'telefono': telefono,
        'mail': mail,
        'ci': ci,
        'genero': genero,
        'domicilio': domicilio,
      },
      'paciente': {
        'grupo_sanguineo': grupoSanguineo,
        'alergias': alergias,
        'antecedentes': antecedentes,
        'estatura': estatura,
        'provincia': provincia,
      },
    };
  }

  String get nombreCompleto {
    if (aMaterno != null && aMaterno!.isNotEmpty) {
      return '$nombre $aPaterno $aMaterno';
    }
    return '$nombre $aPaterno';
  }

  bool get estaActivo => activo.toLowerCase() == 'activo';

  String get estadoFormatado => estaActivo ? 'Activo' : 'Inactivo';

  String get sexoFormatado {
    if (genero == null) return 'No especificado';
    switch (genero!.toLowerCase()) {
      case 'm':
      case 'masculino':
        return 'Masculino';
      case 'f':
      case 'femenino':
        return 'Femenino';
      default:
        return genero!;
    }
  }

  int get edad {
    try {
      final fechaNac = DateTime.parse(fechNac);
      final hoy = DateTime.now();
      int edad = hoy.year - fechaNac.year;
      if (hoy.month < fechaNac.month ||
          (hoy.month == fechaNac.month && hoy.day < fechaNac.day)) {
        edad--;
      }
      return edad;
    } catch (e) {
      return 0;
    }
  }
}

class PacientesResponse {
  final bool success;
  final String message;
  final List<Paciente> pacientes;
  final int total;

  PacientesResponse({
    required this.success,
    required this.message,
    required this.pacientes,
    required this.total,
  });

  factory PacientesResponse.fromJson(Map<String, dynamic> json) {
    return PacientesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      pacientes: json['data'] != null
          ? (json['data'] as List).map((p) => Paciente.fromJson(p)).toList()
          : [],
      total: json['total'] ?? 0,
    );
  }
}

class PacienteStats {
  final int total;
  final int activos;
  final int inactivos;
  final Map<String, int> porSexo;
  final Map<String, int> porGrupoSanguineo;

  PacienteStats({
    required this.total,
    required this.activos,
    required this.inactivos,
    required this.porSexo,
    required this.porGrupoSanguineo,
  });

  factory PacienteStats.fromJson(Map<String, dynamic> json) {
    return PacienteStats(
      total: json['total'] ?? 0,
      activos: json['activos'] ?? 0,
      inactivos: json['inactivos'] ?? 0,
      porSexo: json['por_sexo'] != null
          ? Map<String, int>.from(json['por_sexo'])
          : {},
      porGrupoSanguineo: json['por_grupo_sanguineo'] != null
          ? Map<String, int>.from(json['por_grupo_sanguineo'])
          : {},
    );
  }
}
