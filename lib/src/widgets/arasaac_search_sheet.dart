import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria.dart';
import '../models/pictograma.dart';
import '../services/arasaac_service.dart';
import '../theme/app_theme.dart';
import 'pictogram_card.dart';

/// Explorador en vivo de los +9,000 pictogramas ARASAAC con guardado directo en la API C#.
class ArasaacSearchSheet extends StatefulWidget {
  final ArasaacService arasaacService;
  final List<Categoria> categorias;
  final int defaultCategoryId;
  final ValueChanged<Pictograma> onUseInSentence;
  final Future<void> Function(Pictograma pictograma) onSaveToApi;
  final ValueChanged<String> onSpeakPreview;

  const ArasaacSearchSheet({
    super.key,
    required this.arasaacService,
    required this.categorias,
    required this.defaultCategoryId,
    required this.onUseInSentence,
    required this.onSaveToApi,
    required this.onSpeakPreview,
  });

  @override
  State<ArasaacSearchSheet> createState() => _ArasaacSearchSheetState();
}

class _ArasaacSearchSheetState extends State<ArasaacSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<ArasaacResultado> _results = const [];
  bool _isLoading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
        _isLoading = false;
        _lastQuery = '';
      });
      return;
    }

    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 380), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _lastQuery = trimmed;
    });

    try {
      final items = await widget.arasaacService.buscar(trimmed);
      if (!mounted || _lastQuery != trimmed) return;
      setState(() {
        _results = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || _lastQuery != trimmed) return;
      setState(() {
        _results = const [];
        _isLoading = false;
        _error =
            'Sin conexión con ARASAAC. Revisa tu internet e intenta de nuevo.';
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _runSearch(suggestion);
  }

  Future<void> _openResultOptions(ArasaacResultado result) async {
    if (widget.categorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crea primero una categoría para guardar pictogramas.'),
        ),
      );
      return;
    }

    final initialCategoryId = widget.categorias.any(
      (c) => c.id == widget.defaultCategoryId,
    )
        ? widget.defaultCategoryId
        : widget.categorias.first.id;

    final action = await showModalBottomSheet<_ArasaacSheetAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ArasaacSaveSheet(
        result: result,
        categorias: widget.categorias,
        initialCategoryId: initialCategoryId,
        onSpeakPreview: widget.onSpeakPreview,
        onSaveToApi: widget.onSaveToApi,
      ),
    );

    if (!mounted || action == null) return;
    if (action.useInSentence) {
      Navigator.of(context).pop();
      widget.onUseInSentence(action.pictograma);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 700
        ? 5
        : screenWidth >= 480
            ? 4
            : 3;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.collections_rounded,
                        color: AppTheme.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biblioteca ARASAAC',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Más de 9,000 pictogramas accesibles en español',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: _runSearch,
                  decoration: InputDecoration(
                    hintText:
                        'Busca cualquier palabra (ej. perro, parque, pizza)…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _controller.clear();
                              _onQueryChanged('');
                            },
                            icon: const Icon(Icons.clear_rounded),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: _buildBody(scrollController, crossAxisCount),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController, int crossAxisCount) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 14),
            Text(
              'Buscando en ARASAAC…',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 46,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: () => _runSearch(_lastQuery),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_lastQuery.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          const Text(
            'Sugerencias rápidas',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ArasaacService.sugerencias.map((word) {
              return ActionChip(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _selectSuggestion(word);
                },
                backgroundColor: AppTheme.background,
                side: const BorderSide(color: AppTheme.border),
                label: Text(
                  word[0].toUpperCase() + word.substring(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                avatar: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: AppTheme.secondary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toca cualquier pictograma encontrado para usarlo al instante en tu frase o guardarlo en la base de datos de tu tablero.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                'No encontramos pictogramas para “$_lastQuery”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Prueba con una palabra más simple o en singular.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];

        return Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _openResultOptions(item);
            },
            child: Ink(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border, width: 1.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ArasaacImage(
                        arasaacId: item.id,
                        fallbackIcon: Icons.image_rounded,
                        accentColor: AppTheme.secondary,
                        softColor: AppTheme.secondarySoft,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 7,
                    ),
                    color: AppTheme.background,
                    child: Text(
                      item.etiquetaSugerida,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArasaacSheetAction {
  final Pictograma pictograma;
  final bool useInSentence;

  const _ArasaacSheetAction({
    required this.pictograma,
    required this.useInSentence,
  });
}

class _ArasaacSaveSheet extends StatefulWidget {
  final ArasaacResultado result;
  final List<Categoria> categorias;
  final int initialCategoryId;
  final ValueChanged<String> onSpeakPreview;
  final Future<void> Function(Pictograma pictograma) onSaveToApi;

  const _ArasaacSaveSheet({
    required this.result,
    required this.categorias,
    required this.initialCategoryId,
    required this.onSpeakPreview,
    required this.onSaveToApi,
  });

  @override
  State<_ArasaacSaveSheet> createState() => _ArasaacSaveSheetState();
}

class _ArasaacSaveSheetState extends State<_ArasaacSaveSheet> {
  late final TextEditingController _labelController;
  late int _selectedCategoryId;
  bool _esFavorito = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.result.etiquetaSugerida);
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Pictograma _buildPictograma() {
    final customLabel = _labelController.text.trim();
    return widget.result.toPictograma(
      categoriaId: _selectedCategoryId,
      etiquetaPersonalizada: customLabel.isEmpty ? null : customLabel,
      esFavorito: _esFavorito,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categorias.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => widget.categorias.first,
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cat.borderColor, width: 1.5),
                  ),
                  child: ArasaacImage(
                    arasaacId: widget.result.id,
                    fallbackIcon: cat.iconData,
                    accentColor: cat.color,
                    softColor: cat.softColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelController.text.isEmpty
                            ? widget.result.etiquetaSugerida
                            : _labelController.text,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ARASAAC #${widget.result.id}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (widget.result.meaning != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.result.meaning!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Escuchar',
                  onPressed: () {
                    final text = _labelController.text.trim().isEmpty
                        ? widget.result.etiquetaSugerida
                        : _labelController.text.trim();
                    widget.onSpeakPreview(text);
                  },
                  icon: const Icon(Icons.volume_up_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Texto del pictograma',
                prefixIcon: Icon(Icons.edit_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Categoría',
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
              children: widget.categorias.map((c) {
                final active = c.id == _selectedCategoryId;
                return ChoiceChip(
                  selected: active,
                  onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                  avatar: Icon(
                    c.iconData,
                    size: 16,
                    color: active ? Colors.white : c.color,
                  ),
                  label: Text(c.nombre),
                  selectedColor: c.color,
                  backgroundColor: c.softColor,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppTheme.textPrimary,
                  ),
                  side: BorderSide(color: c.borderColor),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: AppTheme.primary,
              title: const Text(
                'Marcar como favorito',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              value: _esFavorito,
              onChanged: (v) => setState(() => _esFavorito = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _guardando
                        ? null
                        : () {
                            Navigator.of(context).pop(
                              _ArasaacSheetAction(
                                pictograma: _buildPictograma(),
                                useInSentence: true,
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: AppTheme.primary),
                      foregroundColor: AppTheme.primary,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text(
                      'Usar ahora',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _guardando
                        ? null
                        : () async {
                            setState(() => _guardando = true);
                            final picto = _buildPictograma();
                            await widget.onSaveToApi(picto);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_circle_outline_rounded),
                    label: const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
