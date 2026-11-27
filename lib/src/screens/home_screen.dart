import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria.dart';
import '../models/frase.dart';
import '../models/pictograma.dart';
import '../services/app_services.dart';
import '../services/arasaac_service.dart';
import '../services/categoria_service.dart';
import '../services/frase_service.dart';
import '../services/pictograma_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arasaac_search_sheet.dart';
import '../widgets/category_bar.dart';
import '../widgets/pictogram_card.dart';
import '../widgets/quick_phrases_sheet.dart';
import '../widgets/sentence_strip.dart';
import '../widgets/settings_sheet.dart';

/// Pantalla principal de LetMeTalk conectada a la API C# (SQL Server) y ARASAAC.
class HomeScreen extends StatefulWidget {
  final CategoriaService? customCategoriaService;
  final PictogramaService? customPictogramaService;
  final FraseService? customFraseService;
  final ArasaacService? customArasaacService;
  final TtsService? customTtsService;

  const HomeScreen({
    super.key,
    this.customCategoriaService,
    this.customPictogramaService,
    this.customFraseService,
    this.customArasaacService,
    this.customTtsService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CategoriaService _categoriaService;
  late final PictogramaService _pictogramaService;
  late final FraseService _fraseService;
  late final ArasaacService _arasaacService;
  late final TtsService _ttsService;

  final List<Pictograma> _sentence = [];
  List<Categoria> _categorias = [];
  List<Pictograma> _pictogramas = [];
  List<Frase> _frases = [];

  int _selectedCategoryId = 0; // 0 = Favoritos
  bool _isLoading = true;
  String? _errorMensaje;
  VoiceViewSettings _settings = const VoiceViewSettings();

  @override
  void initState() {
    super.initState();
    _categoriaService = widget.customCategoriaService ?? categoriaService;
    _pictogramaService = widget.customPictogramaService ?? pictogramaService;
    _fraseService = widget.customFraseService ?? fraseService;
    _arasaacService = widget.customArasaacService ?? arasaacService;
    _ttsService = widget.customTtsService ?? ttsService;

    _ttsService.init(
      speechRate: _settings.speechRate,
      pitch: _settings.speechPitch,
    );
    _cargarDatos();
  }

  Future<void> _cargarDatos({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _isLoading = true;
        _errorMensaje = null;
      });
    }

    try {
      final results = await Future.wait([
        _categoriaService.listarCategorias(),
        _pictogramaService.listarPictogramas(),
        _fraseService.listarFrases(),
      ]);

      if (!mounted) return;
      final cats = results[0] as List<Categoria>;
      final pictos = results[1] as List<Pictograma>;
      final frases = results[2] as List<Frase>;

      setState(() {
        _categorias = cats;
        _pictogramas = pictos;
        _frases = frases;
        _isLoading = false;
        _errorMensaje = null;

        if (_selectedCategoryId != 0 &&
            !_categorias.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = 0;
        }
      });
    } catch (e) {
      debugPrint('Error al cargar datos de la API: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMensaje =
            'No se pudo conectar con la API C# (http://localhost:5238).\nAsegúrate de iniciar LetMeTalkApi y SQL Server.';
      });
    }
  }

  Categoria _resolveCategory(int categoriaId) {
    for (final c in _categorias) {
      if (c.id == categoriaId) return c;
    }
    return Categoria.favoritos;
  }

  List<Pictograma> get _visiblePictograms {
    if (_selectedCategoryId == 0) {
      return _pictogramas.where((p) => p.esFavorito).toList();
    }
    return _pictogramas
        .where((p) => p.categoriaId == _selectedCategoryId)
        .toList();
  }

  Map<int, int> get _categoryCounts {
    final counts = <int, int>{
      0: _pictogramas.where((p) => p.esFavorito).length,
    };
    for (final c in _categorias) {
      counts[c.id] = _pictogramas.where((p) => p.categoriaId == c.id).length;
    }
    return counts;
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // ==================== BARRA DE FRASE ====================

  void _addToSentence(Pictograma pictograma) {
    setState(() {
      _sentence.add(pictograma);
    });
    if (_settings.speakOnTap) {
      _ttsService.speakText(pictograma.textoVoz);
    }
  }

  void _removeSentenceAt(int index) {
    if (index < 0 || index >= _sentence.length) return;
    if (_ttsService.isSpeaking) _ttsService.stop();
    setState(() => _sentence.removeAt(index));
  }

  void _removeLastFromSentence() {
    if (_sentence.isEmpty) return;
    _removeSentenceAt(_sentence.length - 1);
  }

  void _clearSentence() {
    if (_ttsService.isSpeaking) _ttsService.stop();
    setState(() => _sentence.clear());
  }

  void _speakOrStopSentence() {
    if (_ttsService.isSpeaking) {
      _ttsService.stop();
    } else {
      _ttsService.speakSentence(_sentence);
    }
  }

  Future<void> _guardarFraseDesdeBarra() async {
    if (_sentence.isEmpty) return;
    final texto = _sentence.map((p) => p.etiqueta).join(' ');
    final ids = _sentence.take(3).map((p) => p.arasaacId).join(',');

    try {
      final nueva = Frase(
        id: 0,
        titulo: texto,
        textoVoz: texto,
        arasaacIds: ids,
        colorHex: '#0D9488',
      );
      final msg = await _fraseService.crearFrase(nueva);
      await _cargarDatos(silencioso: true);
      _mostrarMensaje(msg);
    } catch (e) {
      debugPrint('Error al guardar frase: $e');
      _mostrarMensaje('Error al guardar frase: $e');
    }
  }

  // ==================== CRUD PICTOGRAMAS ====================

  Future<void> _crearPictogramaEnApi(Pictograma pictograma) async {
    try {
      final mensaje = await _pictogramaService.crearPictograma(pictograma);
      await _cargarDatos(silencioso: true);
      _mostrarMensaje(mensaje);
    } catch (e) {
      debugPrint('Error al crear pictograma: $e');
      _mostrarMensaje('Error al agregar pictograma: $e');
    }
  }

  Future<void> _toggleFavorito(Pictograma pictograma) async {
    final actualizado = pictograma.copyWith(esFavorito: !pictograma.esFavorito);
    try {
      final mensaje = await _pictogramaService.editarPictograma(
        pictograma.id,
        actualizado,
      );
      await _cargarDatos(silencioso: true);
      _mostrarMensaje(mensaje);
    } catch (e) {
      debugPrint('Error al actualizar favorito: $e');
      _mostrarMensaje('Error al actualizar favorito: $e');
    }
  }

  Future<void> _editarPictogramaDialog(Pictograma pictograma) async {
    final editado = await showDialog<Pictograma>(
      context: context,
      builder: (_) => _EditarPictogramaDialog(
        pictograma: pictograma,
        categorias: _categorias,
      ),
    );

    if (editado == null) return;

    try {
      final mensaje =
          await _pictogramaService.editarPictograma(editado.id, editado);
      await _cargarDatos(silencioso: true);
      _mostrarMensaje(mensaje);
    } catch (e) {
      debugPrint('Error al editar pictograma: $e');
      _mostrarMensaje('Error al editar pictograma: $e');
    }
  }

  Future<void> _eliminarPictograma(Pictograma pictograma) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pictograma'),
        content: Text('¿Deseas eliminar “${pictograma.etiqueta}” de tu tablero?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final mensaje = await _pictogramaService.eliminarPictograma(pictograma.id);
      await _cargarDatos(silencioso: true);
      _mostrarMensaje(mensaje);
    } catch (e) {
      debugPrint('Error al eliminar pictograma: $e');
      _mostrarMensaje('Error al eliminar pictograma: $e');
    }
  }

  // ==================== CRUD CATEGORÍAS ====================

  Future<void> _abrirFormularioCategoria({Categoria? existente}) async {
    final resultado = await showDialog<Categoria>(
      context: context,
      builder: (_) => _CategoriaFormDialog(existente: existente),
    );

    if (resultado == null) return;

    try {
      final mensaje = existente == null
          ? await _categoriaService.crearCategoria(resultado)
          : await _categoriaService.editarCategoria(resultado.id, resultado);
      await _cargarDatos(silencioso: true);
      _mostrarMensaje(mensaje);
    } catch (e) {
      debugPrint('Error en categoría: $e');
      _mostrarMensaje('Error al guardar categoría: $e');
    }
  }

  void _openCategoryActions(Categoria categoria) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(categoria.iconData, color: categoria.color),
                  title: Text(
                    categoria.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                  title: const Text(
                    'Editar categoría',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _abrirFormularioCategoria(existente: categoria);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.danger,
                  ),
                  title: const Text(
                    'Eliminar categoría',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Eliminar categoría'),
                        content: Text(
                          'Se eliminará “${categoria.nombre}” y sus pictogramas asociados. ¿Continuar?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dCtx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                            ),
                            onPressed: () => Navigator.of(dCtx).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmar != true) return;
                    try {
                      final msg =
                          await _categoriaService.eliminarCategoria(categoria.id);
                      await _cargarDatos(silencioso: true);
                      _mostrarMensaje(msg);
                    } catch (e) {
                      _mostrarMensaje('Error al eliminar categoría: $e');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== SHEETS ====================

  void _openArasaacExplorer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArasaacSearchSheet(
        arasaacService: _arasaacService,
        categorias: _categorias,
        defaultCategoryId: _selectedCategoryId,
        onUseInSentence: _addToSentence,
        onSaveToApi: _crearPictogramaEnApi,
        onSpeakPreview: _ttsService.speakText,
      ),
    );
  }

  void _openQuickPhrases() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickPhrasesSheet(
        frases: _frases,
        onSpeakPhrase: (phrase) => _ttsService.speakText(phrase.textoVoz),
        onCreatePhrase: (nueva) async {
          final msg = await _fraseService.crearFrase(nueva);
          await _cargarDatos(silencioso: true);
          _mostrarMensaje(msg);
          return _frases;
        },
        onUpdatePhrase: (editada) async {
          final msg = await _fraseService.editarFrase(editada.id, editada);
          await _cargarDatos(silencioso: true);
          _mostrarMensaje(msg);
          return _frases;
        },
        onDeletePhrase: (id) async {
          final msg = await _fraseService.eliminarFrase(id);
          await _cargarDatos(silencioso: true);
          _mostrarMensaje(msg);
          return _frases;
        },
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(
        initialSettings: _settings,
        onChanged: (next) {
          setState(() => _settings = next);
          _ttsService.updateVoiceSettings(
            speechRate: next.speechRate,
            pitch: next.speechPitch,
          );
        },
        onTestVoice: () => _ttsService.speakText(
          'Hola, soy LetMeTalk. Estoy listo para ayudarte a comunicar.',
        ),
      ),
    );
  }

  void _openPictogramActions(Pictograma pictograma) {
    final category = _resolveCategory(pictograma.categoriaId);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: category.borderColor),
                      ),
                      child: ArasaacImage(
                        arasaacId: pictograma.arasaacId,
                        fallbackIcon: category.iconData,
                        accentColor: category.color,
                        softColor: category.softColor,
                        iconSize: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pictograma.etiqueta,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${category.nombre} · ARASAAC #${pictograma.arasaacId}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.volume_up_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Escuchar palabra',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _ttsService.speakText(pictograma.textoVoz);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Icon(
                    pictograma.esFavorito
                        ? Icons.star_outline_rounded
                        : Icons.star_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  title: Text(
                    pictograma.esFavorito
                        ? 'Quitar de Favoritos'
                        : 'Agregar a Favoritos',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _toggleFavorito(pictograma);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.edit_rounded,
                    color: AppTheme.secondary,
                  ),
                  title: const Text(
                    'Editar pictograma',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _editarPictogramaDialog(pictograma);
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.danger,
                  ),
                  title: const Text(
                    'Eliminar pictograma',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _eliminarPictograma(pictograma);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _computeColumns(double width) {
    final base = switch (_settings.gridDensity) {
      GridDensity.large => (width / 155).floor(),
      GridDensity.medium => (width / 118).floor(),
      GridDensity.compact => (width / 96).floor(),
    };
    return base.clamp(2, 7);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePictograms;
    final counts = _categoryCounts;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactHeader = screenWidth < 420;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LetMeTalk',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Comunicación CAA',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilledButton.tonalIcon(
              onPressed: () {
                HapticFeedback.selectionClick();
                _openArasaacExplorer();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondarySoft,
                foregroundColor: AppTheme.secondary,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactHeader ? 10 : 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                isCompactHeader ? 'ARASAAC' : 'ARASAAC +9k',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Frases rápidas',
            onPressed: () {
              HapticFeedback.selectionClick();
              _openQuickPhrases();
            },
            icon: const Icon(
              Icons.bolt_rounded,
              color: AppTheme.primaryDark,
            ),
          ),
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () {
              HapticFeedback.selectionClick();
              _openSettings();
            },
            icon: const Icon(
              Icons.tune_rounded,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ListenableBuilder(
              listenable: _ttsService,
              builder: (context, _) {
                return SentenceStrip(
                  sentence: _sentence,
                  resolveCategory: _resolveCategory,
                  isSpeaking: _ttsService.isSpeaking,
                  activeWordIndex: _ttsService.activeWordIndex,
                  onSpeakOrStop: _speakOrStopSentence,
                  onRemoveLast: _removeLastFromSentence,
                  onClear: _clearSentence,
                  onSaveAsQuickPhrase: _guardarFraseDesdeBarra,
                  onRemoveAt: _removeSentenceAt,
                );
              },
            ),
            const SizedBox(height: 2),
            CategoryBar(
              categorias: _categorias,
              selectedCategoryId: _selectedCategoryId,
              counts: counts,
              onSelected: (id) => setState(() => _selectedCategoryId = id),
              onLongPressCategory: _openCategoryActions,
              onAddCategory: () => _abrirFormularioCategoria(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _buildBoardContent(visible),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardContent(List<Pictograma> visible) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 14),
            Text(
              'Cargando pictogramas desde la API…',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMensaje != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sin conexión con la API C#',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMensaje!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _cargarDatos,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar conexión'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (visible.isEmpty && _selectedCategoryId == 0) {
          return _EmptyBoardView(
            title: 'Aún no tienes favoritos',
            subtitle:
                'Mantén presionado cualquier pictograma para marcarlo como favorito o agrega nuevos desde ARASAAC.',
            onExplore: _openArasaacExplorer,
          );
        }

        final columns = _computeColumns(constraints.maxWidth);
        final isCompactCard = _settings.gridDensity == GridDensity.compact;

        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => _cargarDatos(silencioso: true),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isCompactCard ? 0.84 : 0.88,
            ),
            itemCount: visible.length + 1,
            itemBuilder: (context, index) {
              if (index == visible.length) {
                return _ExploreArasaacTile(onTap: _openArasaacExplorer);
              }
              final picto = visible[index];
              final cat = _resolveCategory(picto.categoriaId);
              return PictogramCard(
                pictograma: picto,
                categoria: cat,
                compact: isCompactCard,
                onTap: () => _addToSentence(picto),
                onLongPress: () => _openPictogramActions(picto),
              );
            },
          ),
        );
      },
    );
  }
}

class _ExploreArasaacTile extends StatelessWidget {
  final VoidCallback onTap;

  const _ExploreArasaacTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.secondarySoft.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 32,
                  color: AppTheme.secondary,
                ),
                SizedBox(height: 6),
                Text(
                  'Buscar más',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '+9,000 ARASAAC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBoardView extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onExplore;

  const _EmptyBoardView({
    required this.title,
    required this.subtitle,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.secondarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 40,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Explorar ARASAAC (+9,000)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditarPictogramaDialog extends StatefulWidget {
  final Pictograma pictograma;
  final List<Categoria> categorias;

  const _EditarPictogramaDialog({
    required this.pictograma,
    required this.categorias,
  });

  @override
  State<_EditarPictogramaDialog> createState() =>
      _EditarPictogramaDialogState();
}

class _EditarPictogramaDialogState extends State<_EditarPictogramaDialog> {
  late final TextEditingController _etiquetaCtrl;
  late final TextEditingController _vozCtrl;
  late final TextEditingController _arasaacCtrl;
  late int _categoriaId;
  late bool _esFavorito;

  @override
  void initState() {
    super.initState();
    _etiquetaCtrl = TextEditingController(text: widget.pictograma.etiqueta);
    _vozCtrl = TextEditingController(text: widget.pictograma.textoVoz);
    _arasaacCtrl =
        TextEditingController(text: '${widget.pictograma.arasaacId}');
    _categoriaId = widget.pictograma.categoriaId;
    _esFavorito = widget.pictograma.esFavorito;
  }

  @override
  void dispose() {
    _etiquetaCtrl.dispose();
    _vozCtrl.dispose();
    _arasaacCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Editar pictograma',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _etiquetaCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Etiqueta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vozCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Texto en voz alta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _arasaacCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID ARASAAC'),
            ),
            const SizedBox(height: 12),
            if (widget.categorias.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue:
                    widget.categorias.any((c) => c.id == _categoriaId)
                        ? _categoriaId
                        : widget.categorias.first.id,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: widget.categorias
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _categoriaId = v);
                },
              ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: AppTheme.primary,
              title: const Text('Favorito'),
              value: _esFavorito,
              onChanged: (v) => setState(() => _esFavorito = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final etiqueta = _etiquetaCtrl.text.trim();
            if (etiqueta.isEmpty) return;
            final arasaacId =
                int.tryParse(_arasaacCtrl.text.trim()) ??
                    widget.pictograma.arasaacId;
            Navigator.of(context).pop(
              widget.pictograma.copyWith(
                etiqueta: etiqueta,
                textoVoz: _vozCtrl.text.trim().isEmpty
                    ? etiqueta
                    : _vozCtrl.text.trim(),
                arasaacId: arasaacId,
                categoriaId: _categoriaId,
                esFavorito: _esFavorito,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CategoriaFormDialog extends StatefulWidget {
  final Categoria? existente;

  const _CategoriaFormDialog({this.existente});

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  late final TextEditingController _nombreCtrl;
  late String _colorHex;
  late String _icono;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.existente?.nombre ?? '');
    _colorHex =
        widget.existente?.colorHex ?? Categoria.coloresDisponibles.first;
    _icono = widget.existente?.icono ?? 'folder';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existente == null ? 'Nueva categoría' : 'Editar categoría',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                hintText: 'Ej. Mascotas, Escuela, Juegos',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Categoria.coloresDisponibles.map((hex) {
                final selected = hex == _colorHex;
                final color = Categoria.parseHexColor(hex);
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: AppTheme.textPrimary,
                              width: 2.5,
                            )
                          : null,
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Icono',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Categoria.iconosDisponibles.entries.map((entry) {
                final selected = entry.key == _icono;
                final color = Categoria.parseHexColor(_colorHex);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _icono = entry.key),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? color : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : AppTheme.border,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      size: 20,
                      color: selected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final nombre = _nombreCtrl.text.trim();
            if (nombre.isEmpty) return;
            Navigator.of(context).pop(
              Categoria(
                id: widget.existente?.id ?? 0,
                nombre: nombre,
                colorHex: _colorHex,
                icono: _icono,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
