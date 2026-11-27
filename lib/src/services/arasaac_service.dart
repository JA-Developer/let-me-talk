import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pictograma.dart';

/// Servicio para buscar en la biblioteca oficial ARASAAC (+9,000 pictogramas).
class ArasaacService {
  static const String _baseUrl = 'https://api.arasaac.org/v1';

  final http.Client _client;

  ArasaacService({http.Client? client}) : _client = client ?? http.Client();

  static const List<String> sugerencias = [
    'perro',
    'gato',
    'pizza',
    'parque',
    'autobús',
    'cumpleaños',
    'chocolate',
    'televisión',
    'playa',
    'pintar',
    'nadar',
    'dentista',
  ];

  Future<List<ArasaacResultado>> buscar(
    String query, {
    String language = 'es',
    int limit = 40,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final encoded = Uri.encodeComponent(trimmed);
    final uri = Uri.parse('$_baseUrl/pictograms/$language/search/$encoded');

    final response = await _client.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode == 404) {
      return const [];
    }
    if (response.statusCode != 200) {
      throw Exception('Error al buscar en ARASAAC (${response.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    final lowerQuery = trimmed.toLowerCase();
    final results = <ArasaacResultado>[];
    final seenIds = <int>{};

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['_id'];
      if (id is! int || seenIds.contains(id)) continue;
      if (item['violence'] == true || item['sex'] == true) continue;

      final keywords = item['keywords'];
      String matchedKeyword = trimmed;
      String? meaning;

      if (keywords is List && keywords.isNotEmpty) {
        Map<String, dynamic>? bestKw;
        for (final kw in keywords) {
          if (kw is Map<String, dynamic>) {
            final word = (kw['keyword'] as String? ?? '').toLowerCase();
            if (word == lowerQuery) {
              bestKw = kw;
              break;
            }
            if (bestKw == null && word.contains(lowerQuery)) {
              bestKw = kw;
            }
          }
        }
        bestKw ??= keywords.first is Map<String, dynamic>
            ? keywords.first as Map<String, dynamic>
            : null;

        if (bestKw != null) {
          final k = bestKw['keyword'] as String?;
          if (k != null && k.trim().isNotEmpty) {
            matchedKeyword = k.trim();
          }
          final m = bestKw['meaning'] as String?;
          if (m != null && m.trim().isNotEmpty) {
            meaning = m.trim();
          }
        }
      }

      seenIds.add(id);
      results.add(
        ArasaacResultado(
          id: id,
          keyword: matchedKeyword,
          meaning: meaning,
          isAac: item['aac'] == true,
        ),
      );
    }

    results.sort((a, b) {
      final aExact = a.keyword.toLowerCase() == lowerQuery ? 0 : 1;
      final bExact = b.keyword.toLowerCase() == lowerQuery ? 0 : 1;
      if (aExact != bExact) return aExact.compareTo(bExact);

      final aAac = a.isAac ? 0 : 1;
      final bAac = b.isAac ? 0 : 1;
      if (aAac != bAac) return aAac.compareTo(bAac);

      return a.keyword.length.compareTo(b.keyword.length);
    });

    return results.length > limit ? results.sublist(0, limit) : results;
  }
}
