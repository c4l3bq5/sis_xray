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
    try {
      return Paciente(
        id: json['id'],
        personaId: int.tryParse(json['persona_id']?.toString() ?? '0') ?? 0,
        grupoSanguineo: (json['grupo_sanguineo'] ?? '').toString(),
        alergias: json['alergias']?.toString(),
        antecedentes: json['antecedentes']?.toString(),
        estatura: json['estatura'] != null
            ? double.tryParse(json['estatura'].toString())
            : null,
        provincia: json['provincia']?.toString(),
        activo: (json['activo'] ?? 'inactivo').toString(),
        nombre: (json['nombre'] ?? '').toString(),
        aPaterno: (json['a_paterno'] ?? '').toString(),
        aMaterno: json['a_materno']?.toString(),
        fechNac: (json['fech_nac'] ?? '').toString(),
        // Convertir telefono a string (viene como int de la API)
        telefono: json['telefono'] != null ? json['telefono'].toString() : null,
        mail: json['mail']?.toString(),
        // Convertir CI a string (viene como int de la API)
        ci: (json['ci'] ?? '').toString(),
        genero: json['genero']?.toString(),
        domicilio: json['domicilio']?.toString(),
      );
    } catch (e) {
      print('Error parsing Paciente: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    if (id == null) {
      // Para CREAR nuevo paciente
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
    } else {
      // Para ACTUALIZAR paciente existente - enviar TODOS los datos
      return {
        // Datos de persona
        'nombre': nombre,
        'a_paterno': aPaterno,
        'a_materno': aMaterno,
        'fech_nac': fechNac,
        'telefono': telefono,
        'mail': mail,
        'ci': ci,
        'genero': genero,
        'domicilio': domicilio,
        // Datos de paciente
        'grupo_sanguineo': grupoSanguineo,
        'alergias': alergias,
        'antecedentes': antecedentes,
        'estatura': estatura,
        'provincia': provincia,
        'activo': activo,
      };
    }
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

  PacienteStats({
    required this.total,
    required this.activos,
    required this.inactivos,
  });

  factory PacienteStats.fromJson(Map<String, dynamic> json) {
    try {
      // Convertir strings a int
      final total =
          int.tryParse(json['total_pacientes']?.toString() ?? '0') ?? 0;
      final activos = int.tryParse(json['activos']?.toString() ?? '0') ?? 0;
      final inactivos = int.tryParse(json['inactivos']?.toString() ?? '0') ?? 0;

      return PacienteStats(
        total: total,
        activos: activos,
        inactivos: inactivos,
      );
    } catch (e) {
      print('Error parsing PacienteStats: $e');
      return PacienteStats(total: 0, activos: 0, inactivos: 0);
    }
  }
}
