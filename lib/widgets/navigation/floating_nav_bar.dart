import 'package:flutter/material.dart';
import '../../config/palette.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IconData> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding Pill Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment(
              -1 + (2 * currentIndex / (items.length - 1)),
              0,
            ),
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.symmetric(
                horizontal:
                    (MediaQuery.of(context).size.width - 48) /
                        items.length /
                        2 -
                    25,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.orangeAccent, AppPalette.orangeLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.orangeAccent.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),

          // Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final int index = entry.key;
              final IconData icon = entry.value;
              final bool isSelected = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 70,
                    child: Icon(
                      icon,
                      size: 28,
                      color: isSelected
                          ? AppPalette.white
                          : AppPalette.textDisabled,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
