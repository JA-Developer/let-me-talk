import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/frase.dart';

class FraseService {
  final String baseUrl = 'http://localhost:5238/api/Frase';
  final http.Client _client;

  FraseService({http.Client? client}) : _client = client ?? http.Client();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  // Listar frases rápidas
  Future<List<Frase>> listarFrases() async {
    final response = await _client.get(
      Uri.parse(baseUrl),
      headers: _headers,
    );

    debugPrint('Listar frases: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> decodedJson = jsonDecode(utf8.decode(response.bodyBytes));

      return decodedJson
          .map((el) => Frase.fromJson(el as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'Error al listar frases: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Crear frase
  Future<String> crearFrase(Frase frase) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _headers,
      body: jsonEncode(frase.toJson()),
    );

    debugPrint('Crear frase: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'Frase agregada correctamente';
    }

    throw Exception(
      'Error al crear frase: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Editar frase
  Future<String> editarFrase(int id, Frase frase) async {
    final url = Uri.parse('$baseUrl/$id');

    final response = await _client.put(
      url,
      headers: _headers,
      body: jsonEncode(frase.toJson()),
    );

    debugPrint('Editar frase: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return 'Frase editada correctamente';
    }

    throw Exception(
      'Error al editar frase: '
      '${response.statusCode} - ${response.body}',
    );
  }

  // Eliminar frase
  Future<String> eliminarFrase(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$id'),
      headers: _headers,
    );

    debugPrint('Eliminar frase: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return 'Frase eliminada correctamente';
    }

    throw Exception(
      'Error al eliminar frase: '
      '${response.statusCode} - ${response.body}',
    );
  }
}
