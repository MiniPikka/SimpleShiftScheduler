import 'package:flutter/material.dart';

/// Dark Productivity Design — 字体层级
///
/// 5 级规格：标题 28sp / 主数字 36sp / 二级标题 20sp / 正文 16sp / 辅助说明 13sp

class CpTypography {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle heroNumber = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.1,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}

/// 自定义 TextTheme 用于 ThemeData
TextTheme cpTextTheme(TextTheme base) {
  return base.copyWith(
    headlineLarge: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    displayLarge: const TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
    ),
  );
}
