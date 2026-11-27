import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria.dart';
import '../models/pictograma.dart';
import '../theme/app_theme.dart';

/// Imagen oficial de ARASAAC con carga suave y respaldo visual limpio.
class ArasaacImage extends StatelessWidget {
  final int arasaacId;
  final IconData fallbackIcon;
  final Color accentColor;
  final Color softColor;
  final int size;
  final double? iconSize;

  const ArasaacImage({
    super.key,
    required this.arasaacId,
    required this.fallbackIcon,
    required this.accentColor,
    required this.softColor,
    this.size = 300,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final url =
        'https://static.arasaac.org/pictograms/$arasaacId/${arasaacId}_$size.png';

    return Image.network(
      url,
      fit: BoxFit.contain,
      cacheWidth: size,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: frame == null ? _buildPlaceholder() : child,
        );
      },
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: softColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: accentColor.withValues(alpha: 0.45),
          size: iconSize ?? 34,
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          color: accentColor,
          size: iconSize ?? 38,
        ),
      ),
    );
  }
}

/// Tarjeta táctil de pictograma con borde semántico Fitzgerald y animación suave.
class PictogramCard extends StatefulWidget {
  final Pictograma pictograma;
  final Categoria categoria;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PictogramCard({
    super.key,
    required this.pictograma,
    required this.categoria,
    required this.onTap,
    this.compact = false,
    this.onLongPress,
  });

  @override
  State<PictogramCard> createState() => _PictogramCardState();
}

class _PictogramCardState extends State<PictogramCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;

    return Semantics(
      button: true,
      label: widget.pictograma.etiqueta,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            onLongPress: widget.onLongPress == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    widget.onLongPress!();
                  },
            splashColor: cat.color.withValues(alpha: 0.14),
            highlightColor: cat.softColor.withValues(alpha: 0.5),
            child: Ink(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _pressed ? cat.color : cat.borderColor,
                  width: _pressed ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cat.color.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            widget.compact ? 8 : 12,
                            widget.compact ? 8 : 12,
                            widget.compact ? 8 : 12,
                            4,
                          ),
                          child: ArasaacImage(
                            arasaacId: widget.pictograma.arasaacId,
                            fallbackIcon: cat.iconData,
                            accentColor: cat.color,
                            softColor: cat.softColor,
                            iconSize: widget.compact ? 30 : 40,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: widget.compact ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: cat.softColor.withValues(alpha: 0.85),
                          border: Border(
                            top: BorderSide(
                              color: cat.borderColor.withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.pictograma.etiqueta,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.compact ? 12.5 : 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.pictograma.esFavorito)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
