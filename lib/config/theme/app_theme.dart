import 'package:flutter/material.dart';

class AppTheme {
  static const Color colorSeed = Colors.purple;

  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorSeed,
    );
  }
}
