import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                labelBuilder(option),
                style: GoogleFonts.inter(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondary
                      : Colors.black87,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(
                customLabel!,
                style: GoogleFonts.inter(
                  color: Colors.black87,
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
