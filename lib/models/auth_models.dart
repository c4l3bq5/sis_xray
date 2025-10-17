// lib/models/auth_models.dart
class LoginRequest {
  final String usuario;
  final String contrasena;

  LoginRequest({required this.usuario, required this.contrasena});

  Map<String, dynamic> toJson() {
    return {'usuario': usuario, 'contrasena': contrasena};
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponse({required this.success, required this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final UserData user;
  final String token;

  LoginData({required this.user, required this.token});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: UserData.fromJson(json['user']),
      token: json['token'] ?? '',
    );
  }
}

class UserData {
  final int id;
  final int personaId;
  final int rolId;
  final String usuario;
  final bool mfaActivo;
  final String activo;
  final String nombre;
  final String aPaterno;
  final String? aMaterno;
  final String? mail;
  final String rolNombre;

  UserData({
    required this.id,
    required this.personaId,
    required this.rolId,
    required this.usuario,
    required this.mfaActivo,
    required this.activo,
    required this.nombre,
    required this.aPaterno,
    this.aMaterno,
    this.mail,
    required this.rolNombre,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      personaId: json['persona_id'] ?? 0,
      rolId: json['rol_id'] ?? 0,
      usuario: json['usuario'] ?? '',
      mfaActivo: json['mfa_activo'] ?? false,
      activo: json['activo'] ?? '',
      nombre: json['nombre'] ?? '',
      aPaterno: json['a_paterno'] ?? '',
      aMaterno: json['a_materno'],
      mail: json['mail'],
      rolNombre: json['rol_nombre'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'persona_id': personaId,
      'rol_id': rolId,
      'usuario': usuario,
      'mfa_activo': mfaActivo,
      'activo': activo,
      'nombre': nombre,
      'a_paterno': aPaterno,
      'a_materno': aMaterno,
      'mail': mail,
      'rol_nombre': rolNombre,
    };
  }

  String get nombreCompleto {
    if (aMaterno != null && aMaterno!.isNotEmpty) {
      return '$nombre $aPaterno $aMaterno';
    }
    return '$nombre $aPaterno';
  }

  bool get estaActivo => activo.toLowerCase() == 'activo';

  String get rolFormateado {
    switch (rolNombre.toLowerCase()) {
      case 'administrador':
        return 'Administrador';
      case 'medico':
        return 'Médico';
      case 'interno':
        return 'Interno';
      default:
        return rolNombre;
    }
  }
}
