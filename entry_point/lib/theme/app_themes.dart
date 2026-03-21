// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'app_colors.dart';

class DarkTheme {
  DarkTheme._();

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: DarkColors.main,
      scaffoldBackgroundColor: DarkColors.main,
      colorScheme: const ColorScheme.dark(
        primary: DarkColors.labelActive,
        secondary: DarkColors.orange,
        surface: DarkColors.inputField,
        onSurface: DarkColors.labelText,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: DarkColors.labelText),
        bodyMedium: TextStyle(color: DarkColors.labelText),
        bodySmall: TextStyle(color: DarkColors.labelText),
        titleLarge: TextStyle(color: DarkColors.labelText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: DarkColors.labelText),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: DarkColors.inputField,
        labelStyle: TextStyle(color: DarkColors.labelText),
        hintStyle: TextStyle(color: DarkColors.labelText),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: DarkColors.labelActive),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: DarkColors.lightInput),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DarkColors.main,
        elevation: 0,
        iconTheme: IconThemeData(color: DarkColors.labelActive),
        titleTextStyle: TextStyle(
          color: DarkColors.labelText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: DarkColors.inputField,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DarkColors.orange,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkColors.labelActive,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: DarkColors.inputField,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dividerColor: DarkColors.lightInput,
    );
  }
}

class LightTheme {
  LightTheme._();

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: LightColors.main,
      scaffoldBackgroundColor: LightColors.main,
      colorScheme: const ColorScheme.light(
        primary: LightColors.labelActive,
        secondary: LightColors.orange,
        surface: LightColors.main,
        onSurface: LightColors.purpleText,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: LightColors.purpleText),
        bodyMedium: TextStyle(color: LightColors.purpleText),
        bodySmall: TextStyle(color: LightColors.purpleText),
        titleLarge: TextStyle(color: LightColors.purpleText, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: LightColors.purpleText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        labelStyle: const TextStyle(color: LightColors.labelActive),
        hintStyle: TextStyle(color: Colors.grey[400]),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: LightColors.labelActive),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.main,
        elevation: 0,
        iconTheme: IconThemeData(color: LightColors.labelActive),
        titleTextStyle: TextStyle(
          color: LightColors.purpleText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[50],
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LightColors.orange,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightColors.labelActive,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dividerColor: Colors.grey.shade200,
    );
  }
}
