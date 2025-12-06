// lib/services/graphql_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GraphQLService {
  static const String baseUrl = 'https://api-graph.onrender.com/graphql';
  
  static Future<Map<String, dynamic>> uploadRadImage({
    required String fileName,
    required Uint8List imageBytes,
    required Uint8List maskBytes,
    required String mimetype,
    required String area,
    String? annotations,
    String? clinicHistoryId,
  }) async {
    try {
      print(' Preparando upload a MongoDB...');
      print('   - Filename: $fileName');
      print('   - Area: $area');
      print('   - Clinic History ID: $clinicHistoryId');
      
      final imageBase64 = base64Encode(imageBytes);
      final maskBase64 = base64Encode(maskBytes);
      
      print('   - Image size: ${imageBytes.length} bytes');
      print('   - Mask size: ${maskBytes.length} bytes');
      
      final mutation = '''
        mutation UploadRadImage(
          \$fileName: String!
          \$imageBase64: String!
          \$maskBase64: String!
          \$mimetype: String!
          \$area: String!
          \$annotations: String
          \$clinicHistoryId: String
        ) {
          uploadRadImage(
            fileName: \$fileName
            imageBase64: \$imageBase64
            maskBase64: \$maskBase64
            mimetype: \$mimetype
            area: \$area
            annotations: \$annotations
            clinicHistoryId: \$clinicHistoryId
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
              area
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
        'clinicHistoryId': clinicHistoryId,
      };
      
      print(' Enviando request a GraphQL...');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': mutation,
          'variables': variables,
        }),
      ).timeout(const Duration(seconds: 30));
      
      print(' Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['errors'] != null) {
          print(' GraphQL errors: ${result['errors']}');
          throw Exception(result['errors'][0]['message']);
        }
        
        final uploadData = result['data']['uploadRadImage'] as Map<String, dynamic>;
        print(' Upload exitoso: ${uploadData['message']}');
        
        return uploadData;
      } else {
        print(' HTTP error: ${response.statusCode}');
        print(' Response body: ${response.body}');
        throw Exception('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error en uploadRadImage: $e');
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> linkImageToClinicHistory({
    required String imageId,
    required String clinicHistoryId,
  }) async {
    try {
      print(' Vinculando imagen $imageId a historial $clinicHistoryId');
      
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
        
        print(' Imagen vinculada exitosamente');
        return result['data']['linkImageToClinicHistory'];
      } else {
        throw Exception('Error al vincular imagen: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error en linkImageToClinicHistory: $e');
      rethrow;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getImagesByClinicHistory(
    String clinicHistoryId,
  ) async {
    try {
      print(' Buscando imágenes para historial: $clinicHistoryId');
      
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
            area
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
        print(' Imágenes encontradas: ${images.length}');
        
        return images.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener imágenes: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error en getImagesByClinicHistory: $e');
      rethrow;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getRecentRadImages({
    int limit = 10,
  }) async {
    try {
      print(' Obteniendo imágenes recientes (limit: $limit)...');
      
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
          print(' GraphQL errors: ${result['errors']}');
          throw Exception(result['errors'][0]['message']);
        }
        
        if (result['data'] == null || result['data']['recentRadImages'] == null) {
          print(' No se encontró el campo recentRadImages en la respuesta');
          return [];
        }
        
        final images = result['data']['recentRadImages'] as List;
        print('Imágenes obtenidas: ${images.length}');
        
        return images.cast<Map<String, dynamic>>();
      } else {
        print(' Error HTTP: ${response.statusCode}');
        print(' Body: ${response.body}');
        throw Exception('Error al obtener imágenes recientes: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error en getRecentRadImages: $e');
      rethrow;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getAllRadImages() async {
    try {
      print(' Obteniendo todas las imágenes...');
      
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
        
        print(' Total imágenes: ${images.length}');
        return images.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener todas las imágenes: ${response.statusCode}');
      }
    } catch (e) {
      print(' Error en getAllRadImages: $e');
      rethrow;
    }
  }
}