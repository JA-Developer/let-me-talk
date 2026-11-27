import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pictograma.dart';

class PictogramaService {
  final String baseUrl = 'http://localhost:5238/api/Pictograma';
  final http.Client _client;

  PictogramaService({http.Client? client}) : _client = client ?? http.Client();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // Listar pictogramas
  Future<List<Pictograma>> listarPictogramas({
    int? categoriaId,
    bool? soloFavoritos,
  }) async {
    final queryParams = <String, String>{};
    if (categoriaId != null) {
      queryParams['categoriaId'] = '$categoriaId';
    }
    if (soloFavoritos == true) {
      queryParams['soloFavoritos'] = 'true';
    }

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await _client.get(
      uri,
      headers: _headers,
    );

    debugPrint('Listar pictogramas: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> decodedJson = jsonDecode(utf8.decode(response.bodyBytes));

      return decodedJson
          .map((el) => Pictograma.fromJson(el as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'Error al listar pictogramas: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Crear pictograma
  Future<String> crearPictograma(Pictograma pictograma) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _headers,
      body: jsonEncode(pictograma.toJson()),
    );

    debugPrint('Crear pictograma: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'Pictograma agregado correctamente';
    }

    throw Exception(
      'Error al crear pictograma: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Editar pictograma
  Future<String> editarPictograma(int id, Pictograma pictograma) async {
    final url = Uri.parse('$baseUrl/$id');

    final response = await _client.put(
      url,
      headers: _headers,
      body: jsonEncode(pictograma.toJson()),
    );

    debugPrint('Editar pictograma: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return 'Pictograma editado correctamente';
    }

    throw Exception(
      'Error al editar pictograma: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Eliminar pictograma
  Future<String> eliminarPictograma(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _headers,
    );

    debugPrint('Eliminar pictograma: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return 'Pictograma eliminado correctamente';
    }

    throw Exception(
      'Error al eliminar pictograma: '
      '${response.statusCode} - ${response.body}',
    );
  }
}
