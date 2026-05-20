import 'package:flutter/widgets.dart';

/// Dark Productivity Design — 圆角系统
///
/// 4 级圆角：Button 18dp / Card 24dp / MainCard 28dp / Sheet 32dp

class CpShapes {
  /// ButtonShape — 18dp
  static const BorderRadius button = BorderRadius.all(Radius.circular(18));

  /// CardShape — 24dp
  static const BorderRadius card = BorderRadius.all(Radius.circular(24));

  /// MainCardShape — 28dp
  static const BorderRadius mainCard = BorderRadius.all(Radius.circular(28));

  /// SheetShape — 32dp
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(32));
}
