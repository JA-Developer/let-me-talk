import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:letmetalk/src/screens/home_screen.dart';
import 'package:letmetalk/src/services/arasaac_service.dart';
import 'package:letmetalk/src/services/categoria_service.dart';
import 'package:letmetalk/src/services/frase_service.dart';
import 'package:letmetalk/src/services/pictograma_service.dart';
import 'package:letmetalk/src/services/tts_service.dart';
import 'package:letmetalk/src/theme/app_theme.dart';

/// Simula la API C# (Categoria, Pictograma, Frase) en memoria para pruebas de widgets.
class FakeApiHarness {
  final List<Map<String, dynamic>> categorias = [
    {'id': 1, 'nombre': 'Personas', 'colorHex': '#D97706', 'icono': 'people'},
    {'id': 2, 'nombre': 'Acciones', 'colorHex': '#059669', 'icono': 'actions'},
    {'id': 3, 'nombre': 'Emociones', 'colorHex': '#0284C7', 'icono': 'emotions'},
    {'id': 4, 'nombre': 'Necesidades', 'colorHex': '#E11D48', 'icono': 'needs'},
  ];

  final List<Map<String, dynamic>> pictogramas = [
    {
      'id': 1,
      'arasaacId': 6632,
      'etiqueta': 'Yo',
      'textoVoz': 'Yo',
      'categoriaId': 1,
      'esFavorito': true,
    },
    {
      'id': 2,
      'arasaacId': 2458,
      'etiqueta': 'Mamá',
      'textoVoz': 'Mamá',
      'categoriaId': 1,
      'esFavorito': false,
    },
    {
      'id': 3,
      'arasaacId': 32464,
      'etiqueta': 'Agua',
      'textoVoz': 'Agua',
      'categoriaId': 4,
      'esFavorito': true,
    },
    {
      'id': 4,
      'arasaacId': 9907,
      'etiqueta': 'Feliz',
      'textoVoz': 'Feliz',
      'categoriaId': 3,
      'esFavorito': true,
    },
  ];

  final List<Map<String, dynamic>> frases = [
    {
      'id': 1,
      'titulo': 'Necesito ayuda',
      'textoVoz': 'Necesito ayuda, por favor',
      'arasaacIds': '37160,32648',
      'colorHex': '#E11D48',
    },
  ];

  int _nextCatId = 10;
  int _nextPictoId = 10;
  int _nextFraseId = 10;

  MockClient createClient() {
    return MockClient((request) async {
      final path = request.url.path;
      final method = request.method;

      if (path.endsWith('/api/Categoria')) {
        if (method == 'GET') {
          return http.Response(
            jsonEncode(categorias),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          body['id'] = _nextCatId++;
          categorias.add(body);
          return http.Response('"Categoría creada correctamente"', 200);
        }
      }

      if (path.contains('/api/Categoria/')) {
        final id = int.parse(path.split('/').last);
        if (method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final idx = categorias.indexWhere((c) => c['id'] == id);
          if (idx >= 0) categorias[idx] = {...body, 'id': id};
          return http.Response('"Categoría actualizada correctamente"', 200);
        }
        if (method == 'DELETE') {
          categorias.removeWhere((c) => c['id'] == id);
          pictogramas.removeWhere((p) => p['categoriaId'] == id);
          return http.Response('"Categoría eliminada correctamente"', 200);
        }
      }

      if (path.endsWith('/api/Pictograma')) {
        if (method == 'GET') {
          return http.Response(
            jsonEncode(pictogramas),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          body['id'] = _nextPictoId++;
          pictogramas.add(body);
          return http.Response('"Pictograma creado correctamente"', 200);
        }
      }

      if (path.contains('/api/Pictograma/')) {
        final id = int.parse(path.split('/').last);
        if (method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final idx = pictogramas.indexWhere((p) => p['id'] == id);
          if (idx >= 0) pictogramas[idx] = {...body, 'id': id};
          return http.Response('"Pictograma actualizado correctamente"', 200);
        }
        if (method == 'DELETE') {
          pictogramas.removeWhere((p) => p['id'] == id);
          return http.Response('"Pictograma eliminado correctamente"', 200);
        }
      }

      if (path.endsWith('/api/Frase')) {
        if (method == 'GET') {
          return http.Response(
            jsonEncode(frases),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          body['id'] = _nextFraseId++;
          frases.add(body);
          return http.Response('"Frase creada correctamente"', 200);
        }
      }

      if (path.contains('/api/Frase/')) {
        final id = int.parse(path.split('/').last);
        if (method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final idx = frases.indexWhere((f) => f['id'] == id);
          if (idx >= 0) frases[idx] = {...body, 'id': id};
          return http.Response('"Frase actualizada correctamente"', 200);
        }
        if (method == 'DELETE') {
          frases.removeWhere((f) => f['id'] == id);
          return http.Response('"Frase eliminada correctamente"', 200);
        }
      }

      if (path.contains('/pictograms/es/search/')) {
        return http.Response(
          jsonEncode([
            {
              '_id': 7202,
              'aac': true,
              'violence': false,
              'sex': false,
              'keywords': [
                {'keyword': 'perro', 'meaning': 'Animal doméstico'}
              ],
            }
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return http.Response('Not Found', 404);
    });
  }

  Widget buildApp() {
    final client = createClient();
    return MaterialApp(
      theme: AppTheme.build(),
      home: HomeScreen(
        customCategoriaService: CategoriaService(client: client),
        customPictogramaService: PictogramaService(client: client),
        customFraseService: FraseService(client: client),
        customArasaacService: ArasaacService(client: client),
        customTtsService: TtsService(),
      ),
    );
  }
}

void main() {
  testWidgets('Loads data from C# API, builds sentence, and saves quick phrase',
      (WidgetTester tester) async {
    final harness = FakeApiHarness();
    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle();

    expect(find.text('LetMeTalk'), findsOneWidget);
    expect(find.text('Yo'), findsOneWidget);
    expect(find.text('Agua'), findsOneWidget);

    // Forma frase tocando pictogramas.
    await tester.tap(find.text('Yo'));
    await tester.pump();
    await tester.tap(find.text('Agua'));
    await tester.pump();
    expect(find.text('Yo Agua'), findsOneWidget);

    // Guarda la frase actual en la API C# (POST /api/Frase).
    await tester.tap(find.byTooltip('Guardar frase rápida'));
    await tester.pumpAndSettle();
    expect(harness.frases.length, 2);

    // Cambia de categoría y verifica los pictogramas de Personas.
    await tester.tap(find.text('Personas'));
    await tester.pumpAndSettle();
    expect(find.text('Mamá'), findsOneWidget);

    // Limpia la frase.
    await tester.tap(find.byTooltip('Limpiar frase'));
    await tester.pump();
    expect(
      find.text('Toca pictogramas abajo para formar una frase'),
      findsOneWidget,
    );
  });

  testWidgets('Opens ARASAAC explorer, quick phrases, and settings cleanly',
      (WidgetTester tester) async {
    final harness = FakeApiHarness();
    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle();

    // Abre ARASAAC explorer.
    await tester.tap(find.textContaining('ARASAAC').first);
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca ARASAAC'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Abre Frases rápidas cargadas de la API.
    await tester.tap(find.byTooltip('Frases rápidas'));
    await tester.pumpAndSettle();
    expect(find.text('Necesito ayuda'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Abre Ajustes y Acerca de.
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Acerca de LetMeTalk'), findsOneWidget);
  });

  testWidgets('Renders cleanly on compact phone viewport without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = FakeApiHarness();
    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle();

    expect(find.text('LetMeTalk'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Emociones'),
      120,
      scrollable: find.descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emociones'));
    await tester.pumpAndSettle();
    expect(find.text('Feliz'), findsOneWidget);
  });

  testWidgets('ARASAAC save sheet and category dialog dispose controllers safely',
      (WidgetTester tester) async {
    final harness = FakeApiHarness();
    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle();

    // Crea una categoría desde el diálogo y verifica que cierre sin errores.
    await tester.scrollUntilVisible(
      find.text('Nueva'),
      140,
      scrollable: find.descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Mascotas');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(harness.categorias.any((c) => c['nombre'] == 'Mascotas'), isTrue);

    // Abre ARASAAC, busca "perro", abre la hoja de guardado y guarda en la API.
    await tester.tap(find.textContaining('ARASAAC').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perro'));
    await tester.pumpAndSettle();

    // Toca el resultado encontrado para abrir _ArasaacSaveSheet.
    await tester.tap(find.text('Perro').last);
    await tester.pumpAndSettle();
    expect(find.text('Guardar'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(harness.pictogramas.any((p) => p['arasaacId'] == 7202), isTrue);
  });
}
