import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gallery/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          onPressed: () {
            themeProvider.toggleTheme();
          },
          icon: Icon(
            themeProvider.themeMode == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          tooltip: themeProvider.themeMode == ThemeMode.light
              ? 'Switch to dark mode'
              : 'Switch to light mode',
        );
      },
    );
  }
}
