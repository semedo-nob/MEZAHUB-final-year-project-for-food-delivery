import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';

class ModernThemeToggle extends StatelessWidget {
  const ModernThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Light Mode Option
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            label: 'Light',
            isActive: themeProvider.themeMode == ThemeMode.light,
            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
          ),

          // System Mode Option
          _ThemeOption(
            icon: Icons.auto_mode_outlined,
            label: 'Auto',
            isActive: themeProvider.themeMode == ThemeMode.system,
            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
          ),

          // Dark Mode Option
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            label: 'Dark',
            isActive: themeProvider.themeMode == ThemeMode.dark,
            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}