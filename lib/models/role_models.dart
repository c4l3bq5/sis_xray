// lib/models/role_models.dart

class Rol {
  final int id;
  final String nombre;

  Rol({required this.id, required this.nombre});

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(id: json['id'] ?? 0, nombre: json['nombre'] ?? '');
  }
}

class RolesResponse {
  final bool success;
  final String message;
  final List<Rol> roles;

  RolesResponse({
    required this.success,
    required this.message,
    required this.roles,
  });

  factory RolesResponse.fromJson(Map<String, dynamic> json) {
    return RolesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      roles: json['data'] != null
          ? (json['data'] as List).map((r) => Rol.fromJson(r)).toList()
          : [],
    );
  }
}
