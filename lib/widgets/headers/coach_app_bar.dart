import 'package:flutter/material.dart';
import '../../config/palette.dart';

class CoachAppBar extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  final Color? backgroundColor;

  const CoachAppBar({
    super.key,
    required this.child,
    this.bottomPadding = 20.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20, // Reduced horizontal padding
        MediaQuery.of(context).padding.top +
            10, // Standardized top safe area + padding
        20,
        bottomPadding, // Standardized bottom padding
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppPalette.navyPrimary, // Navy Blue in both themes
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: child,
    );
  }
}
