import 'package:flutter/material.dart';
import 'colors.dart';
import 'shapes.dart';

/// Dark Productivity Design — ThemeData 组装
///
/// 深色主题：暗色背景 + 亮色文字 + 金色强调
/// 浅色主题：浅色背景 + 暗色文字 + 金色强调
/// 自动跟随系统 isSystemInDarkTheme()

class CpTheme {
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: cpAccent,
      onPrimary: cpPrimaryBackground,
      surface: cpCardSurface,
      onSurface: cpPrimaryText,
      onSurfaceVariant: cpSecondaryText,
      outlineVariant: cpHintText,
      error: cpDanger,
    ),
    scaffoldBackgroundColor: cpPrimaryBackground,
    cardTheme: CardThemeData(
      color: cpCardSurface,
      shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cpPrimaryBackground,
      foregroundColor: cpPrimaryText,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cpSecondarySurface,
      indicatorColor: cpAccent.withValues(alpha: 0.15),
    ),
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFB8860B), // 深金色（浅色底可见）
      onPrimary: Colors.white,
      surface: Color(0xFFF8F9FA),
      onSurface: Color(0xFF1A1D23),
      onSurfaceVariant: Color(0xFF6B7280),
      outlineVariant: Color(0xFFD1D5DB),
      error: cpDanger,
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F2F5),
    cardTheme: CardThemeData(
      color: const Color(0xFFF8F9FA),
      shape: RoundedRectangleBorder(borderRadius: CpShapes.card),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF0F2F5),
      foregroundColor: Color(0xFF1A1D23),
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF8F9FA),
      indicatorColor: const Color(0xFFB8860B).withValues(alpha: 0.10),
    ),
  );

  /// 自动根据系统主题选择深色/浅色
  static ThemeData of(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
