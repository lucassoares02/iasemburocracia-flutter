import 'package:flutter/material.dart';

class AppTheme {
  static const double _baseFontSize = 14;

  static TextTheme _textTheme(Color textColor, Color secondaryColor) => TextTheme(
        headlineLarge: TextStyle(
          fontSize: _baseFontSize * 1.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: _baseFontSize,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: _baseFontSize,
          color: textColor.withOpacity(0.8),
        ),
        labelLarge: TextStyle(
          fontSize: _baseFontSize,
          fontWeight: FontWeight.w600,
          color: secondaryColor,
        ),
      );

  /// Tema claro
  static ThemeData get light {
    final primary = const Color(0xFF0066ff); // um vermelho ligeiramente mais escuro (Red 700)
    final secondary = const Color(0xFF0000ff); // um tom de “accent” (Red 400)
    final tertiary = const Color(0xFFFDC300); // um tom de “accent” (Red 400)

    final surface = const Color(0xFFF5F5F5); // neutro claro (Grey 100)
    final background = Colors.white; // cartões, modais, etc.

    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        tertiary: tertiary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        background: background,
        onBackground: Colors.grey[800]!,
        surface: surface,
        onSurface: Colors.grey[900]!,
      ),
      textTheme: _textTheme(Colors.grey[900]!, secondary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surface,
        iconTheme: const IconThemeData(color: Colors.grey),
        titleTextStyle: TextStyle(
          color: Colors.grey[900],
          fontSize: _baseFontSize * 1.25,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: _baseFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Tema escuro
  static ThemeData get dark {
    final primary = const Color(0xFFFF6600); // um vermelho ligeiramente mais escuro (Red 700)
    final secondary = const Color(0xFFff0000); // Red 200, para destaques mais sutis
    final tertiary = const Color(0xFFFDC300); // um tom de “accent” (Red 400)
    final surface = const Color(0xFF121212); // neutro escuro
    final background = const Color(0xFF1E1E1E); // cartas, caixas de diálogo, etc.

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        tertiary: tertiary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        background: background,
        onBackground: Colors.white70,
        surface: surface,
        onSurface: Colors.white70,
      ),
      textTheme: _textTheme(Colors.white, secondary),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surface,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: const TextStyle(
          color: Colors.white70,
          fontSize: _baseFontSize * 1.25,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: _baseFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
