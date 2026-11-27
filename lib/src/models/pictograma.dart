class Pictograma {
  final int id;
  final int arasaacId;
  final String etiqueta;
  final String textoVoz;
  final int categoriaId;
  final bool esFavorito;

  const Pictograma({
    required this.id,
    required this.arasaacId,
    required this.etiqueta,
    required this.textoVoz,
    required this.categoriaId,
    this.esFavorito = false,
  });

  String imageUrl({int size = 300}) =>
      'https://static.arasaac.org/pictograms/$arasaacId/${arasaacId}_$size.png';

  factory Pictograma.fromJson(Map<String, dynamic> json) {
    final etiqueta = json['etiqueta'] as String? ?? '';
    final textoVoz = json['textoVoz'] as String?;
    return Pictograma(
      id: json['id'] as int,
      arasaacId: json['arasaacId'] as int,
      etiqueta: etiqueta,
      textoVoz: (textoVoz == null || textoVoz.trim().isEmpty)
          ? etiqueta
          : textoVoz,
      categoriaId: json['categoriaId'] as int,
      esFavorito: json['esFavorito'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arasaacId': arasaacId,
      'etiqueta': etiqueta,
      'textoVoz': textoVoz,
      'categoriaId': categoriaId,
      'esFavorito': esFavorito,
    };
  }

  Pictograma copyWith({
    int? id,
    int? arasaacId,
    String? etiqueta,
    String? textoVoz,
    int? categoriaId,
    bool? esFavorito,
  }) {
    return Pictograma(
      id: id ?? this.id,
      arasaacId: arasaacId ?? this.arasaacId,
      etiqueta: etiqueta ?? this.etiqueta,
      textoVoz: textoVoz ?? this.textoVoz,
      categoriaId: categoriaId ?? this.categoriaId,
      esFavorito: esFavorito ?? this.esFavorito,
    );
  }
}

/// Resultado de búsqueda en vivo de la biblioteca oficial ARASAAC (+9,000 imágenes).
class ArasaacResultado {
  final int id;
  final String keyword;
  final String? meaning;
  final bool isAac;

  const ArasaacResultado({
    required this.id,
    required this.keyword,
    this.meaning,
    this.isAac = false,
  });

  String get etiquetaSugerida {
    if (keyword.isEmpty) return '';
    return keyword[0].toUpperCase() + keyword.substring(1);
  }

  Pictograma toPictograma({
    required int categoriaId,
    String? etiquetaPersonalizada,
    bool esFavorito = true,
  }) {
    final texto = (etiquetaPersonalizada ?? etiquetaSugerida).trim();
    return Pictograma(
      id: 0,
      arasaacId: id,
      etiqueta: texto,
      textoVoz: texto,
      categoriaId: categoriaId,
      esFavorito: esFavorito,
    );
  }
}
