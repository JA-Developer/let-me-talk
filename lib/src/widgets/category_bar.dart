import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/categoria.dart';
import '../theme/app_theme.dart';

/// Barra horizontal de categorías CAA con colores Fitzgerald + botón para crear categoría.
class CategoryBar extends StatelessWidget {
  final List<Categoria> categorias;
  final int selectedCategoryId;
  final Map<int, int> counts;
  final ValueChanged<int> onSelected;
  final ValueChanged<Categoria> onLongPressCategory;
  final VoidCallback onAddCategory;

  const CategoryBar({
    super.key,
    required this.categorias,
    required this.selectedCategoryId,
    required this.counts,
    required this.onSelected,
    required this.onLongPressCategory,
    required this.onAddCategory,
  });

  @override
  Widget build(BuildContext context) {
    final items = [Categoria.favoritos, ...categorias];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return Tooltip(
              message: 'Nueva categoría',
              child: Material(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onAddCategory();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border, width: 1.3),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Nueva',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final category = items[index];
          final isSelected = category.id == selectedCategoryId;
          final count = counts[category.id];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(category.id);
              },
              onLongPress: category.id == 0
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onLongPressCategory(category);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? category.color : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? category.color : category.borderColor,
                    width: isSelected ? 1.5 : 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: category.color.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.iconData,
                      size: 18,
                      color: isSelected ? Colors.white : category.color,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      category.nombre,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (count != null && count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : category.softColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : category.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
