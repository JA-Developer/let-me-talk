import 'package:flutter/material.dart';
import 'categoria.dart';

class Frase {
  final int id;
  final String titulo;
  final String textoVoz;
  final String arasaacIds;
  final String colorHex;

  const Frase({
    required this.id,
    required this.titulo,
    required this.textoVoz,
    required this.arasaacIds,
    this.colorHex = '#0D9488',
  });

  List<int> get listaArasaacIds {
    if (arasaacIds.trim().isEmpty) return const [];
    return arasaacIds
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  Color get color => Categoria.parseHexColor(colorHex);

  factory Frase.fromJson(Map<String, dynamic> json) {
    final titulo = json['titulo'] as String? ?? '';
    final textoVoz = json['textoVoz'] as String?;
    return Frase(
      id: json['id'] as int,
      titulo: titulo,
      textoVoz: (textoVoz == null || textoVoz.trim().isEmpty)
          ? titulo
          : textoVoz,
      arasaacIds: json['arasaacIds'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#0D9488',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'textoVoz': textoVoz,
      'arasaacIds': arasaacIds,
      'colorHex': colorHex,
    };
  }

  Frase copyWith({
    int? id,
    String? titulo,
    String? textoVoz,
    String? arasaacIds,
    String? colorHex,
  }) {
    return Frase(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      textoVoz: textoVoz ?? this.textoVoz,
      arasaacIds: arasaacIds ?? this.arasaacIds,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
