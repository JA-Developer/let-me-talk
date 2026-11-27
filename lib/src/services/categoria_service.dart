import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/categoria.dart';

class CategoriaService {
  final String baseUrl = 'http://localhost:5238/api/Categoria';
  final http.Client _client;

  CategoriaService({http.Client? client}) : _client = client ?? http.Client();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // Listar categorías
  Future<List<Categoria>> listarCategorias() async {
    final response = await _client.get(
      Uri.parse(baseUrl),
      headers: _headers,
    );

    debugPrint('Listar categorías: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> decodedJson = jsonDecode(utf8.decode(response.bodyBytes));

      return decodedJson
          .map((el) => Categoria.fromJson(el as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'Error al listar categorías: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Crear categoría
  Future<String> crearCategoria(Categoria categoria) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _headers,
      body: jsonEncode(categoria.toJson()),
    );

    debugPrint('Crear categoría: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'Categoría agregada correctamente';
    }

    throw Exception(
      'Error al crear categoría: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Editar categoría
  Future<String> editarCategoria(int id, Categoria categoria) async {
    final url = Uri.parse('$baseUrl/$id');

    final response = await _client.put(
      url,
      headers: _headers,
      body: jsonEncode(categoria.toJson()),
    );

    debugPrint('Editar categoría: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return 'Categoría editada correctamente';
    }

    throw Exception(
      'Error al editar categoría: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Eliminar categoría
  Future<String> eliminarCategoria(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _headers,
    );

    debugPrint('Eliminar categoría: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return 'Categoría eliminada correctamente';
    }

    throw Exception(
      'Error al eliminar categoría: '
      '${response.statusCode} - ${response.body}',
    );
  }
}
