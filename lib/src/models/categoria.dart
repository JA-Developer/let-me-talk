import 'package:flutter/material.dart';

class Categoria {
  final int id;
  final String nombre;
  final String colorHex;
  final String icono;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.colorHex,
    required this.icono,
  });

  /// Pestaña virtual para mostrar los pictogramas marcados como favoritos.
  static const Categoria favoritos = Categoria(
    id: 0,
    nombre: 'Favoritos',
    colorHex: '#4F46E5',
    icono: 'star',
  );

  /// Paleta predefinida para crear o editar categorías.
  static const List<String> coloresDisponibles = [
    '#D97706',
    '#059669',
    '#0284C7',
    '#E11D48',
    '#EA580C',
    '#7C3AED',
    '#0D9488',
    '#4F46E5',
  ];

  /// Iconos disponibles al crear o editar categorías.
  static const Map<String, IconData> iconosDisponibles = {
    'star': Icons.star_rounded,
    'people': Icons.people_alt_rounded,
    'actions': Icons.directions_run_rounded,
    'emotions': Icons.sentiment_satisfied_alt_rounded,
    'needs': Icons.favorite_rounded,
    'objects': Icons.category_rounded,
    'social': Icons.waving_hand_rounded,
    'food': Icons.restaurant_rounded,
    'home': Icons.home_rounded,
    'school': Icons.school_rounded,
    'music': Icons.music_note_rounded,
    'folder': Icons.folder_rounded,
  };

  Color get color => parseHexColor(colorHex);

  Color get softColor => Color.lerp(color, Colors.white, 0.88) ?? Colors.white;

  Color get borderColor => Color.lerp(color, Colors.white, 0.65) ?? color;

  IconData get iconData => iconosDisponibles[icono] ?? Icons.category_rounded;

  static Color parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final value = int.tryParse('FF$cleaned', radix: 16);
      if (value != null) return Color(value);
    }
    if (cleaned.length == 8) {
      final value = int.tryParse(cleaned, radix: 16);
      if (value != null) return Color(value);
    }
    return const Color(0xFF0D9488);
  }

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#0D9488',
      icono: json['icono'] as String? ?? 'category',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'colorHex': colorHex,
      'icono': icono,
    };
  }

  Categoria copyWith({
    int? id,
    String? nombre,
    String? colorHex,
    String? icono,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      colorHex: colorHex ?? this.colorHex,
      icono: icono ?? this.icono,
    );
  }
}
