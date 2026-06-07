import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 简言笔记 品牌色。
class AppColors {
  AppColors._();

  static const primary = Color(0xFF7C6F9E);
  static const danger = Color(0xFFE53935);

  // 向后兼容别名
  static const background = lightBg;
  static const surface = lightSurface;
  static const textPrimary = lightText;
  static const textSecondary = lightTextSec;

  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF8F5FC);
  static const lightText = Color(0xFF2D2640);
  static const lightTextSec = Color(0xFF9E9E9E);

  static const darkBg = Color(0xFF1A1A2E);
  static const darkSurface = Color(0xFF252540);
  static const darkText = Color(0xFFE8E8F0);
  static const darkTextSec = Color(0xFF8888A0);

  static const cardColors = [
    Color(0xFFE8F5E9), Color(0xFFFFF3E0), Color(0xFFE3F2FD),
    Color(0xFFFCE4EC), Color(0xFFF3E5F5), Color(0xFFE0F7FA),
  ];
  static const cardColorsDark = [
    Color(0xFF2E3B2E), Color(0xFF3B3528), Color(0xFF28323B),
    Color(0xFF3B282E), Color(0xFF33283B), Color(0xFF283B3B),
  ];
  static const cardIconColors = [
    Color(0xFF4CAF50), Color(0xFFFF9800), Color(0xFF2196F3),
    Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF00BCD4),
  ];

  static Color cardColor(int i, {bool dark = false}) =>
      (dark ? cardColorsDark : cardColors)[i % cardColors.length];
  static Color cardIconColor(int i) => cardIconColors[i % cardIconColors.length];
}

class AppTheme {
  AppTheme._();

  static ThemeData light = _build(true);
  static ThemeData dark = _build(false);

  static ThemeData _build(bool isLight) {
    final bg = isLight ? AppColors.lightBg : AppColors.darkBg;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final text = isLight ? AppColors.lightText : AppColors.darkText;
    final textSec = isLight ? AppColors.lightTextSec : AppColors.darkTextSec;
    final b = isLight ? Brightness.light : Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Noto Sans SC', 'Noto Sans CJK SC', 'Droid Sans Fallback', 'sans-serif'],
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: b),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg, foregroundColor: text, elevation: 0, centerTitle: false,
        titleTextStyle: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg, selectedItemColor: AppColors.primary,
        unselectedItemColor: textSec, type: BottomNavigationBarType.fixed, elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: textSec.withValues(alpha: 0.5)),
      ),
      dividerColor: textSec.withValues(alpha: 0.12),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── 主题持久化 ──────────────────────────────────────────

class ThemePrefs {
  static const _key = 'jianyan_dark_mode';
  static Future<bool> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_key.json');
      if (await file.exists()) {
        final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return m['dark'] as bool? ?? false;
      }
    } catch (_) {}
    return false;
  }
  static Future<void> save(bool dark) async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/$_key.json').writeAsString(jsonEncode({'dark': dark}));
  }
}
