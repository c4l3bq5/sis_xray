// lib/models/log_models.dart
import 'package:flutter/material.dart';

class Log {
  final int id;
  final int? usuarioId;
  final String accion;
  final String? descripcion;
  final DateTime timestamp;

  // Datos del usuario si existe
  final String? usuario;
  final String? nombreUsuario;

  Log({
    required this.id,
    this.usuarioId,
    required this.accion,
    this.descripcion,
    required this.timestamp,
    this.usuario,
    this.nombreUsuario,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    // Construir nombre completo si viene separado
    String? nombreCompleto;
    if (json['nombre'] != null) {
      nombreCompleto = json['nombre'].toString();
      if (json['a_paterno'] != null) {
        nombreCompleto = '$nombreCompleto ${json['a_paterno']}';
      }
      if (json['a_materno'] != null) {
        nombreCompleto = '$nombreCompleto ${json['a_materno']}';
      }
    }
    
    return Log(
      id: json['id'] ?? 0,
      usuarioId: json['usuario_id'],
      accion: json['accion'] ?? '',
      descripcion: json['descripcion'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      usuario: json['usuario'],
      nombreUsuario: json['nombre_usuario'] ?? nombreCompleto,
    );
  }

  String get accionFormateada {
    // Extraer solo la acción principal
    if (accion.contains(' en ')) {
      return accion.split(' en ')[0];
    }
    return accion;
  }

  String get tablaAfectada {
    // Extraer la tabla afectada
    if (accion.contains(' en ')) {
      return accion.split(' en ')[1];
    }
    return '';
  }

  Color get colorAccion {
    if (accion.contains('INSERT')) {
      return Colors.green;
    } else if (accion.contains('UPDATE')) {
      return Colors.blue;
    } else if (accion.contains('DELETE')) {
      return Colors.red;
    } else if (accion.contains('sesiones') || accion.contains('login')) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  IconData get iconoAccion {
    if (accion.contains('INSERT')) {
      return Icons.add_circle;
    } else if (accion.contains('UPDATE')) {
      return Icons.edit;
    } else if (accion.contains('DELETE')) {
      return Icons.delete;
    } else if (accion.contains('sesiones') || accion.contains('login')) {
      return Icons.login;
    }
    return Icons.info;
  }
}

class LogsResponse {
  final bool success;
  final String message;
  final List<Log> logs;
  final int total;

  LogsResponse({
    required this.success,
    required this.message,
    required this.logs,
    required this.total,
  });

  factory LogsResponse.fromJson(Map<String, dynamic> json) {
    return LogsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      logs: json['data'] != null
          ? (json['data'] as List).map((l) => Log.fromJson(l)).toList()
          : [],
      total: json['count'] ?? json['total'] ?? 0,
    );
  }
}

class LogStats {
  final int totalLogs;
  final int usuariosActivos;
  final int logsHoy;
  final int inserciones;
  final int actualizaciones;
  final int eliminaciones;
  
  // Propiedades para las estadísticas detalladas
  final Map<String, int> porAccion;
  final Map<String, int> porUsuario;

  LogStats({
    required this.totalLogs,
    required this.usuariosActivos,
    required this.logsHoy,
    required this.inserciones,
    required this.actualizaciones,
    required this.eliminaciones,
    this.porAccion = const {},
    this.porUsuario = const {},
  });

  factory LogStats.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    Map<String, int> parseMapStats(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return value.map((key, val) => MapEntry(
          key.toString(),
          safeParseInt(val),
        ));
      }
      return {};
    }

    return LogStats(
      totalLogs: safeParseInt(json['total_logs']),
      usuariosActivos: safeParseInt(json['usuarios_activos']),
      logsHoy: safeParseInt(json['logs_hoy']),
      inserciones: safeParseInt(json['inserciones']),
      actualizaciones: safeParseInt(json['actualizaciones']),
      eliminaciones: safeParseInt(json['eliminaciones']),
      porAccion: parseMapStats(json['por_accion']),
      porUsuario: parseMapStats(json['por_usuario']),
    );
  }
  
  // Propiedades calculadas para mantener compatibilidad
  int get hoy => logsHoy;
  int get estaSemana => totalLogs; // Placeholder
  int get esteMes => totalLogs; // Placeholder
  int get inserts => inserciones;
  int get updates => actualizaciones;
  int get deletes => eliminaciones;
}