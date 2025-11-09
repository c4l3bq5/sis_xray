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
    return Log(
      id: json['id'] ?? 0,
      usuarioId: json['usuario_id'],
      accion: json['accion'] ?? '',
      descripcion: json['descripcion'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      usuario: json['usuario'],
      nombreUsuario: json['nombre_usuario'],
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
    } else if (accion.contains('sesiones')) {
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
    } else if (accion.contains('sesiones')) {
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
      total: json['total'] ?? 0,
    );
  }
}

class LogStats {
  final int totalLogs;
  final int hoy;
  final int estaSemana;
  final int esteMes;
  final Map<String, int> porAccion;
  final Map<String, int> porUsuario;

  LogStats({
    required this.totalLogs,
    required this.hoy,
    required this.estaSemana,
    required this.esteMes,
    required this.porAccion,
    required this.porUsuario,
  });

  factory LogStats.fromJson(Map<String, dynamic> json) {
    // Convertir los valores a int de forma segura
    Map<String, int> convertToIntMap(dynamic data) {
      final Map<String, int> result = {};
      if (data != null && data is Map) {
        data.forEach((key, value) {
          if (value is int) {
            result[key.toString()] = value;
          } else if (value is String) {
            result[key.toString()] = int.tryParse(value) ?? 0;
          } else {
            result[key.toString()] = 0;
          }
        });
      }
      return result;
    }

    return LogStats(
      totalLogs: json['total_logs'] is int
          ? json['total_logs']
          : int.tryParse(json['total_logs'].toString()) ?? 0,
      hoy: json['hoy'] is int
          ? json['hoy']
          : int.tryParse(json['hoy'].toString()) ?? 0,
      estaSemana: json['esta_semana'] is int
          ? json['esta_semana']
          : int.tryParse(json['esta_semana'].toString()) ?? 0,
      esteMes: json['este_mes'] is int
          ? json['este_mes']
          : int.tryParse(json['este_mes'].toString()) ?? 0,
      porAccion: convertToIntMap(json['por_accion']),
      porUsuario: convertToIntMap(json['por_usuario']),
    );
  }
}
