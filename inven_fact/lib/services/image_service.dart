import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageService {
  // Clave API gratuita de Unsplash (regístrate en https://unsplash.com/developers)
  static const String _accessKey =
      'lgq-V6jIYPts1ewf9RmwEr8UwX5MVbH_9vA3l6D73CQ';
  static const String _baseUrl = 'https://api.unsplash.com';

  Future<String?> getProductImage(String productName) async {
    try {
      // Limpiar el nombre del producto para la búsqueda
      final searchQuery = productName.toLowerCase().replaceAll(' ', '+');

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/search/photos?query=$searchQuery&per_page=1&orientation=squarish'),
        headers: {
          'Authorization': 'Client-ID $_accessKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          // Retornar la URL de la imagen en tamaño regular
          return results[0]['urls']['regular'];
        }
      }
    } catch (e) {
      // print('Error al obtener imagen: $e');
    }

    return null;
  }

  // Alternativa con Pixabay API
  Future<String?> getProductImagePixabay(String productName) async {
    const String pixabayKey = 'TU_PIXABAY_API_KEY';

    try {
      final searchQuery = productName.toLowerCase().replaceAll(' ', '+');

      final response = await http.get(
        Uri.parse(
            'https://pixabay.com/api/?key=$pixabayKey&q=$searchQuery&image_type=photo&per_page=3&min_width=400'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hits = data['hits'] as List;

        if (hits.isNotEmpty) {
          return hits[0]['webformatURL'];
        }
      }
    } catch (e) {
      // print('Error al obtener imagen de Pixabay: $e');
    }

    return null;
  }
}