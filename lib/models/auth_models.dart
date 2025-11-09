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
  final String token;
  final UserData user;
  final bool? requiresMFA;
  final bool? requiresPasswordChange;
  final int? userId;

  LoginData({
    required this.token,
    required this.user,
    this.requiresMFA,
    this.requiresPasswordChange,
    this.userId,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'] ?? '',
      user: UserData.fromJson(json['user']),
      requiresMFA: json['requiresMFA'],
      requiresPasswordChange: json['requiresPasswordChange'],
      userId: json['userId'],
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
      personaId: json['persona_id'] ?? json['personaId'] ?? 0,
      rolId: json['rol_id'] ?? json['rolId'] ?? 0,
      usuario: json['usuario'] ?? '',
      mfaActivo: json['mfa_activo'] ?? json['mfaActivo'] ?? false,
      activo: json['activo'] ?? 'inactivo',
      nombre: json['nombre'] ?? '',
      aPaterno: json['a_paterno'] ?? json['aPaterno'] ?? '',
      aMaterno: json['a_materno'] ?? json['aMaterno'],
      mail: json['mail'],
      rolNombre: json['rol_nombre'] ?? json['rolNombre'] ?? '',
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

  String get rolFormateado {
    // Capitaliza primera letra
    if (rolNombre.isEmpty) return 'Sin Rol';
    return rolNombre[0].toUpperCase() + rolNombre.substring(1).toLowerCase();
  }
}

// 🔥 NUEVOS MODELOS PARA MFA

class MFAVerifyRequest {
  final int userId;
  final String mfaCode;

  MFAVerifyRequest({required this.userId, required this.mfaCode});

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'mfaCode': mfaCode};
  }
}

class MFAVerifyResponse {
  final bool success;
  final String message;
  final MFAVerifyData? data;

  MFAVerifyResponse({required this.success, required this.message, this.data});

  factory MFAVerifyResponse.fromJson(Map<String, dynamic> json) {
    return MFAVerifyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? MFAVerifyData.fromJson(json['data']) : null,
    );
  }
}

class MFAVerifyData {
  final int userId;
  final bool mfaVerified;

  MFAVerifyData({required this.userId, required this.mfaVerified});

  factory MFAVerifyData.fromJson(Map<String, dynamic> json) {
    return MFAVerifyData(
      userId: json['userId'] ?? 0,
      mfaVerified: json['mfaVerified'] ?? false,
    );
  }
}

class ChangePasswordRequest {
  final int userId;
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.userId,
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
  }
}
