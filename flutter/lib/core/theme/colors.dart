import 'package:flutter/material.dart';
import '../../domain/models/shift_type.dart';

/// Dark Productivity Design — 颜色系统
///
/// 背景：深色三层（PrimaryBackground > SecondarySurface > CardSurface）
/// 文字：三层（PrimaryText > SecondaryText > HintText）
/// 班次：五色（早橙/中蓝/夜紫/休绿/学黄）
/// 语义：四色（Success/Warning/Danger/Accent）

// ── 背景 ──
const Color cpPrimaryBackground = Color(0xFF0B0D10);
const Color cpSecondarySurface = Color(0xFF15181D);
const Color cpCardSurface = Color(0xFF1B1F26);

// ── 文字 ──
const Color cpPrimaryText = Color(0xFFF5F7FA);
const Color cpSecondaryText = Color(0xFF9CA3AF);
const Color cpHintText = Color(0xFF6B7280);

// ── 班次颜色 ──
const Color shiftMorning = Color(0xFFFFB347);
const Color shiftAfternoon = Color(0xFF4DA3FF);
const Color shiftNight = Color(0xFF7C5CFF);
const Color shiftRest = Color(0xFF35D07F);
const Color shiftStudy = Color(0xFFF2D94E);

// ── 语义颜色 ──
const Color cpSuccess = Color(0xFF22C55E);
const Color cpWarning = Color(0xFFF59E0B);
const Color cpDanger = Color(0xFFEF4444);
const Color cpAccent = Color(0xFFFACC15);

/// 班次类型 → 颜色
Color shiftColor(ShiftType type) {
  switch (type) {
    case ShiftType.MORNING:
      return shiftMorning;
    case ShiftType.AFTERNOON:
      return shiftAfternoon;
    case ShiftType.NIGHT:
      return shiftNight;
    case ShiftType.REST:
      return shiftRest;
    case ShiftType.STUDY:
      return shiftStudy;
  }
}
