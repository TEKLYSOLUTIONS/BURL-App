import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/palette.dart';

class ModernDurationSelector<T> extends StatelessWidget {
  final T? selectedValue;
  final List<T> options;
  final String Function(T) labelBuilder;
  final void Function(T) onSelected;
  final String? customLabel;
  final VoidCallback? onCustomTap;

  const ModernDurationSelector({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
    this.customLabel,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...options.map((option) {
          final isSelected = selectedValue == option;
          return GestureDetector(
            onTap: () => onSelected(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppPalette.orangeAccent
                      : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                labelBuilder(option),
                style: GoogleFonts.inter(
                  color: isSelected
                      ? AppPalette.orangeAccent
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
        if (customLabel != null && onCustomTap != null)
          GestureDetector(
            onTap: onCustomTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                customLabel!,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
