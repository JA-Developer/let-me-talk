import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria.dart';
import '../models/pictograma.dart';
import '../theme/app_theme.dart';
import 'pictogram_card.dart';

/// Barra superior de construcción y lectura de frases (estilo LetMeTalk).
class SentenceStrip extends StatefulWidget {
  final List<Pictograma> sentence;
  final Categoria Function(int categoriaId) resolveCategory;
  final bool isSpeaking;
  final int? activeWordIndex;
  final VoidCallback onSpeakOrStop;
  final VoidCallback onRemoveLast;
  final VoidCallback onClear;
  final VoidCallback onSaveAsQuickPhrase;
  final ValueChanged<int> onRemoveAt;

  const SentenceStrip({
    super.key,
    required this.sentence,
    required this.resolveCategory,
    required this.isSpeaking,
    required this.activeWordIndex,
    required this.onSpeakOrStop,
    required this.onRemoveLast,
    required this.onClear,
    required this.onSaveAsQuickPhrase,
    required this.onRemoveAt,
  });

  @override
  State<SentenceStrip> createState() => _SentenceStripState();
}

class _SentenceStripState extends State<SentenceStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant SentenceStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sentence.length > oldWidget.sentence.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.sentence.isNotEmpty;
    final previewText = widget.sentence.map((p) => p.etiqueta).join(' ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isSpeaking
              ? AppTheme.primary
              : hasItems
                  ? AppTheme.primary.withValues(alpha: 0.35)
                  : AppTheme.border,
          width: widget.isSpeaking ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isSpeaking ? AppTheme.primary : Colors.black)
                .withValues(alpha: widget.isSpeaking ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 92,
            child: hasItems
                ? ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.sentence.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final picto = widget.sentence[index];
                      final cat = widget.resolveCategory(picto.categoriaId);
                      final isActive =
                          widget.isSpeaking && widget.activeWordIndex == index;

                      return _SentenceChip(
                        pictograma: picto,
                        categoria: cat,
                        isActive: isActive,
                        onRemove: () {
                          HapticFeedback.lightImpact();
                          widget.onRemoveAt(index);
                        },
                      );
                    },
                  )
                : const _EmptySentenceHint(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: hasItems
                    ? Text(
                        previewText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : const Text(
                        'Tu frase aparecerá aquí',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              _StripIconButton(
                tooltip: 'Guardar frase rápida',
                icon: Icons.bookmark_add_outlined,
                enabled: hasItems,
                onPressed: widget.onSaveAsQuickPhrase,
              ),
              const SizedBox(width: 6),
              _StripIconButton(
                tooltip: 'Borrar último',
                icon: Icons.backspace_outlined,
                enabled: hasItems,
                onPressed: widget.onRemoveLast,
              ),
              const SizedBox(width: 6),
              _StripIconButton(
                tooltip: 'Limpiar frase',
                icon: Icons.delete_outline_rounded,
                enabled: hasItems,
                isDestructive: true,
                onPressed: widget.onClear,
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: hasItems
                    ? () {
                        HapticFeedback.mediumImpact();
                        widget.onSpeakOrStop();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      widget.isSpeaking ? AppTheme.danger : AppTheme.primary,
                  disabledBackgroundColor: AppTheme.border,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  widget.isSpeaking
                      ? Icons.stop_rounded
                      : Icons.volume_up_rounded,
                  size: 20,
                ),
                label: Text(
                  widget.isSpeaking ? 'Parar' : 'Hablar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentenceChip extends StatelessWidget {
  final Pictograma pictograma;
  final Categoria categoria;
  final bool isActive;
  final VoidCallback onRemove;

  const _SentenceChip({
    required this.pictograma,
    required this.categoria,
    required this.isActive,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 82,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primarySoft : AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppTheme.primary : categoria.borderColor,
              width: isActive ? 2.2 : 1.4,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                      child: ArasaacImage(
                        arasaacId: pictograma.arasaacId,
                        fallbackIcon: categoria.iconData,
                        accentColor: categoria.color,
                        softColor: categoria.softColor,
                        size: 300,
                        iconSize: 24,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : categoria.softColor,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      pictograma.etiqueta,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySentenceHint extends StatelessWidget {
  const _EmptySentenceHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: AppTheme.primary,
            size: 24,
          ),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Toca pictogramas abajo para formar una frase',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _StripIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = !enabled
        ? AppTheme.textSecondary.withValues(alpha: 0.35)
        : isDestructive
            ? AppTheme.danger
            : AppTheme.textPrimary;
    final bg = !enabled
        ? AppTheme.background
        : isDestructive
            ? AppTheme.dangerSoft.withValues(alpha: 0.7)
            : AppTheme.background;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed();
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 19, color: fg),
          ),
        ),
      ),
    );
  }
}
