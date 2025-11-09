// lib/models/user_models.dart
class Usuario {
  final int id;
  final int personaId;
  final int rolId;
  final String usuario;
  final bool mfaActivo;
  final String activo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Datos de la persona
  final String nombre;
  final String aPaterno;
  final String? aMaterno;
  final String? mail;
  final String? ci;
  final String? telefono;
  final String? domicilio;
  final DateTime? fechaNac;
  final String? genero;

  // Datos del rol
  final String rolNombre;

  Usuario({
    required this.id,
    required this.personaId,
    required this.rolId,
    required this.usuario,
    required this.mfaActivo,
    required this.activo,
    required this.createdAt,
    this.updatedAt,
    required this.nombre,
    required this.aPaterno,
    this.aMaterno,
    this.mail,
    this.ci,
    this.telefono,
    this.domicilio,
    this.fechaNac,
    this.genero,
    required this.rolNombre,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      personaId: json['persona_id'] ?? 0,
      rolId: json['rol_id'] ?? 0,
      usuario: json['usuario'] ?? '',
      mfaActivo: json['mfa_activo'] ?? false,
      activo: json['activo'] ?? 'inactivo',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      nombre: json['nombre'] ?? '',
      aPaterno: json['a_paterno'] ?? '',
      aMaterno: json['a_materno'],
      mail: json['mail'],
      ci: json['ci'],
      telefono: json['telefono'],
      domicilio: json['domicilio'],
      fechaNac: json['fech_nac'] != null
          ? DateTime.parse(json['fech_nac'])
          : null,
      genero: json['genero'],
      rolNombre: json['rol_nombre'] ?? '',
    );
  }

  String get nombreCompleto {
    if (aMaterno != null && aMaterno!.isNotEmpty) {
      return '$nombre $aPaterno $aMaterno';
    }
    return '$nombre $aPaterno';
  }

  bool get estaActivo => activo.toLowerCase() == 'activo';

  String get estadoFormatado => estaActivo ? 'Activo' : 'Inactivo';
}

class UsuariosResponse {
  final bool success;
  final String message;
  final List<Usuario> usuarios;
  final int total;

  UsuariosResponse({
    required this.success,
    required this.message,
    required this.usuarios,
    required this.total,
  });

  factory UsuariosResponse.fromJson(Map<String, dynamic> json) {
    return UsuariosResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      usuarios: json['data'] != null
          ? (json['data'] as List).map((u) => Usuario.fromJson(u)).toList()
          : [],
      total: json['total'] ?? 0,
    );
  }
}
