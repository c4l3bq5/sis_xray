// lib/models/rad_image_model.dart
import 'dart:typed_data';
import 'dart:convert';

class RadImage {
  final String id;
  final String fileName;
  final String imageBase64; // Imagen original
  final String maskBase64; // Imagen con anotaciones/boxes
  final String? clinicHistoryId;
  final String? annotations;
  final DateTime uploadDate;
  
  RadImage({
    required this.id,
    required this.fileName,
    required this.imageBase64,
    required this.maskBase64,
    this.clinicHistoryId,
    this.annotations,
    required this.uploadDate,
  });
  
  factory RadImage.fromJson(Map<String, dynamic> json) {
    return RadImage(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      imageBase64: json['image'] ?? '',
      maskBase64: json['mask'] ?? '',
      clinicHistoryId: json['clinicHistoryId'],
      annotations: json['annotations'],
      uploadDate: json['uploadDate'] != null 
        ? DateTime.parse(json['uploadDate'])
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'image': imageBase64,
      'mask': maskBase64,
      'clinicHistoryId': clinicHistoryId,
      'annotations': annotations,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }
  
  // Convertir Base64 a Uint8List para mostrar en Image.memory()
  Uint8List get imageBytes => base64Decode(imageBase64);
  Uint8List get maskBytes => base64Decode(maskBase64);
  
  // Data URLs para navegadores web
  String get imageUrl => 'data:image/jpeg;base64,$imageBase64';
  String get maskUrl => 'data:image/jpeg;base64,$maskBase64';
}