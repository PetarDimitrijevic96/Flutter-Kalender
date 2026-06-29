import 'package:flutter/material.dart';

class ThemeLamp extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const ThemeLamp({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      right: 30,
      child: GestureDetector(
        onTap: onToggleTheme,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
            color: isDarkMode ? Colors.amber : Colors.orangeAccent,
            size: 30,
          ),
        ),
      ),
    );
  }
}
