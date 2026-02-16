import 'package:flutter/material.dart';
import 'coach_bottom_bar.dart';

class CoachNavigation extends StatelessWidget {
  final Widget child;

  const CoachNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const CoachBottomBar());
  }
}
