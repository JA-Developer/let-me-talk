import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria.dart';
import '../models/frase.dart';
import '../theme/app_theme.dart';
import 'pictogram_card.dart';

/// Hoja de frases rápidas con CRUD completo respaldado por la API C#.
class QuickPhrasesSheet extends StatefulWidget {
  final List<Frase> frases;
  final ValueChanged<Frase> onSpeakPhrase;
  final Future<List<Frase>> Function(Frase nueva) onCreatePhrase;
  final Future<List<Frase>> Function(Frase editada) onUpdatePhrase;
  final Future<List<Frase>> Function(int id) onDeletePhrase;

  const QuickPhrasesSheet({
    super.key,
    required this.frases,
    required this.onSpeakPhrase,
    required this.onCreatePhrase,
    required this.onUpdatePhrase,
    required this.onDeletePhrase,
  });

  @override
  State<QuickPhrasesSheet> createState() => _QuickPhrasesSheetState();
}

class _QuickPhrasesSheetState extends State<QuickPhrasesSheet> {
  late List<Frase> _frases;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _frases = List<Frase>.from(widget.frases);
  }

  Future<void> _abrirFormulario({Frase? existente}) async {
    final guardado = await showDialog<Frase>(
      context: context,
      builder: (_) => _FraseFormDialog(existente: existente),
    );

    if (guardado == null) return;

    setState(() => _ocupado = true);
    try {
      final actualizadas = existente == null
          ? await widget.onCreatePhrase(guardado)
          : await widget.onUpdatePhrase(guardado);
      if (!mounted) return;
      setState(() => _frases = actualizadas);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _eliminar(Frase frase) async {
    setState(() => _ocupado = true);
    try {
      final actualizadas = await widget.onDeletePhrase(frase.id);
      if (!mounted) return;
      setState(() => _frases = actualizadas);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.primaryDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frases rápidas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Toca para hablar · usa ⋮ para editar o eliminar',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Agregar frase rápida',
                    onPressed: _ocupado ? null : () => _abrirFormulario(),
                    icon: const Icon(Icons.add_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (_ocupado)
              const LinearProgressIndicator(
                minHeight: 2.5,
                color: AppTheme.primary,
              ),
            if (_frases.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Aún no hay frases guardadas. Toca + para crear una.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: _frases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final phrase = _frases[index];
                    return Material(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onSpeakPhrase(phrase);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: phrase.color.withValues(alpha: 0.28),
                              width: 1.4,
                            ),
                          ),
                          child: Row(
                            children: [
                              ...phrase.listaArasaacIds.take(3).map(
                                (id) => Container(
                                  width: 46,
                                  height: 46,
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: ArasaacImage(
                                    arasaacId: id,
                                    fallbackIcon: Icons.chat_rounded,
                                    accentColor: phrase.color,
                                    softColor:
                                        phrase.color.withValues(alpha: 0.12),
                                    iconSize: 20,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  phrase.titulo,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: phrase.color,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _abrirFormulario(existente: phrase);
                                  } else if (action == 'delete') {
                                    _eliminar(phrase);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Eliminar',
                                      style: TextStyle(color: AppTheme.danger),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FraseFormDialog extends StatefulWidget {
  final Frase? existente;

  const _FraseFormDialog({this.existente});

  @override
  State<_FraseFormDialog> createState() => _FraseFormDialogState();
}

class _FraseFormDialogState extends State<_FraseFormDialog> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _vozCtrl;
  late final TextEditingController _idsCtrl;
  late String _colorHex;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.existente?.titulo ?? '');
    _vozCtrl = TextEditingController(text: widget.existente?.textoVoz ?? '');
    _idsCtrl =
        TextEditingController(text: widget.existente?.arasaacIds ?? '6522');
    _colorHex = widget.existente?.colorHex ?? '#0D9488';
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _vozCtrl.dispose();
    _idsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existente == null ? 'Nueva frase rápida' : 'Editar frase',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título visible',
                hintText: 'Ej. Necesito ayuda',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vozCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Texto que se leerá en voz alta',
                hintText: 'Ej. Necesito ayuda, por favor',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idsCtrl,
              decoration: const InputDecoration(
                labelText: 'IDs ARASAAC (separados por coma)',
                hintText: 'Ej. 37160,32648',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Categoria.coloresDisponibles.map((hex) {
                final selected = hex == _colorHex;
                final color = Categoria.parseHexColor(hex);
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: 30,
                    height: 30,
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
            final titulo = _tituloCtrl.text.trim();
            if (titulo.isEmpty) return;
            final voz =
                _vozCtrl.text.trim().isEmpty ? titulo : _vozCtrl.text.trim();
            Navigator.of(context).pop(
              Frase(
                id: widget.existente?.id ?? 0,
                titulo: titulo,
                textoVoz: voz,
                arasaacIds: _idsCtrl.text.trim(),
                colorHex: _colorHex,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
