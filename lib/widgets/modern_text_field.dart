import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernTextField extends StatelessWidget {
  final String name;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscureText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final VoidCallback? onTap;

  const ModernTextField({
    super.key,
    required this.name,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: FormBuilderTextField(
            name: name,
            controller: controller,
            initialValue: initialValue,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            obscureText: obscureText,
            readOnly: readOnly,
            onTap: onTap,
            cursorColor: Theme.of(context).primaryColor,
            style: GoogleFonts.inter(
                fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
                fontSize: 15,
              ),
              prefixText: prefixText,
              prefixStyle: GoogleFonts.inter(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 16,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      size: 22)
                  : null,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
