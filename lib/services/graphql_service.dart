// lib/services/graphql_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GraphQLService {
  static const String baseUrl = 'https://api-graph.onrender.com/graphql';
  
  // Subir imagen a RadImages (MongoDB)
  static Future<Map<String, dynamic>> uploadRadImage({
    required String fileName,
    required Uint8List imageBytes,
    required Uint8List maskBytes,
    required String mimetype,
    required String area, // 'upper' o 'lower'
    String? annotations,
  }) async {
    try {
      // Convertir a Base64
      final imageBase64 = base64Encode(imageBytes);
      final maskBase64 = base64Encode(maskBytes);
      
      final mutation = '''
        mutation UploadRadImage(
          \$fileName: String!
          \$imageBase64: String!
          \$maskBase64: String!
          \$mimetype: String!
          \$area: String!
          \$annotations: String
        ) {
          uploadRadImage(
            fileName: \$fileName
            imageBase64: \$imageBase64
            maskBase64: \$maskBase64
            mimetype: \$mimetype
            area: \$area
            annotations: \$annotations
          ) {
            success
            message
            radImage {
              id
              fileName
              image
              mask
              clinicHistoryId
              uploadDate
            }
          }
        }
      ''';
      
      final variables = {
        'fileName': fileName,
        'imageBase64': imageBase64,
        'maskBase64': maskBase64,
        'mimetype': mimetype,
        'area': area,
        'annotations': annotations,
      };
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': mutation,
          'variables': variables,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['errors'] != null) {
          throw Exception(result['errors'][0]['message']);
        }
        return result['data']['uploadRadImage'];
      } else {
        throw Exception('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en uploadRadImage: $e');
      rethrow;
    }
  }
  
  // Vincular imagen con historial clínico
  static Future<Map<String, dynamic>> linkImageToClinicHistory({
    required String imageId,
    required String clinicHistoryId,
  }) async {
    try {
      final mutation = '''
        mutation LinkImageToClinicHistory(
          \$imageId: ID!
          \$clinicHistoryId: String!
        ) {
          linkImageToClinicHistory(
            imageId: \$imageId
            clinicHistoryId: \$clinicHistoryId
          ) {
            id
            clinicHistoryId
            imageUrl
          }
        }
      ''';
      
      final variables = {
        'imageId': imageId,
        'clinicHistoryId': clinicHistoryId,
      };
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': mutation,
          'variables': variables,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['errors'] != null) {
          throw Exception(result['errors'][0]['message']);
        }
        return result['data']['linkImageToClinicHistory'];
      } else {
        throw Exception('Error al vincular imagen: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en linkImageToClinicHistory: $e');
      rethrow;
    }
  }
  
  // Obtener imágenes por clinic_history_id
  static Future<List<Map<String, dynamic>>> getImagesByClinicHistory(
    String clinicHistoryId,
  ) async {
    try {
      final query = '''
        query GetImagesByClinicHistory(\$clinicHistoryId: String!) {
          radImagesByClinicHistory(clinicHistoryId: \$clinicHistoryId) {
            id
            fileName
            image
            imageUrl
            mask
            clinicHistoryId
            annotations
            uploadDate
          }
        }
      ''';
      
      final variables = {'clinicHistoryId': clinicHistoryId};
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'variables': variables,
        }),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['errors'] != null) {
          throw Exception(result['errors'][0]['message']);
        }
        
        final images = result['data']['radImagesByClinicHistory'] as List;
        return images.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener imágenes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getImagesByClinicHistory: $e');
      rethrow;
    }
  }
  
  // NUEVO: Obtener las imágenes más recientes (todas)
  static Future<List<Map<String, dynamic>>> getRecentRadImages({
    int limit = 10,
  }) async {
    try {
      print('🔍 Obteniendo imágenes recientes (limit: $limit)...');
      
      final query = '''
        query GetRecentRadImages(\$limit: Int) {
          recentRadImages(limit: \$limit) {
            id
            fileName
            image
            mask
            clinicHistoryId
            annotations
            uploadDate
            area
          }
        }
      ''';
      
      final variables = {'limit': limit};
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'variables': variables,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['errors'] != null) {
          print('⚠️ GraphQL errors: ${result['errors']}');
          throw Exception(result['errors'][0]['message']);
        }
        
        if (result['data'] == null || result['data']['recentRadImages'] == null) {
          print('⚠️ No se encontró el campo recentRadImages en la respuesta');
          return [];
        }
        
        final images = result['data']['recentRadImages'] as List;
        print('✅ Imágenes obtenidas: ${images.length}');
        
        return images.cast<Map<String, dynamic>>();
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('❌ Body: ${response.body}');
        throw Exception('Error al obtener imágenes recientes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getRecentRadImages: $e');
      rethrow;
    }
  }
  
  // ALTERNATIVA: Si el backend no tiene el query recentRadImages,
  // puedes usar este método que obtiene todas las imágenes sin filtro
  static Future<List<Map<String, dynamic>>> getAllRadImages() async {
    try {
      print('🔍 Obteniendo todas las imágenes...');
      
      final query = '''
        query GetAllRadImages {
          allRadImages {
            id
            fileName
            image
            mask
            clinicHistoryId
            annotations
            uploadDate
            area
          }
        }
      ''';
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['errors'] != null) {
          throw Exception(result['errors'][0]['message']);
        }
        
        final images = result['data']['allRadImages'] as List;
        
        // Ordenar por fecha más reciente
        images.sort((a, b) {
          final dateA = DateTime.parse(a['uploadDate'] as String);
          final dateB = DateTime.parse(b['uploadDate'] as String);
          return dateB.compareTo(dateA);
        });
        
        print('✅ Total imágenes: ${images.length}');
        return images.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener todas las imágenes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getAllRadImages: $e');
      rethrow;
    }
  }
}