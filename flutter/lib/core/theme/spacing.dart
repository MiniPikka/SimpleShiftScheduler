// Dark Productivity Design — 间距系统
// 4 级间距：xs=12 / sm=16 / md=20 / lg=24

class CpSpacing {
  /// 12dp — 组件内紧凑间距
  static const double xs = 12;

  /// 16dp — 标准组件间距
  static const double sm = 16;

  /// 20dp — 页面水平边距
  static const double md = 20;

  /// 24dp — 区块间距
  static const double lg = 24;

  /// 页面内容最大宽度（大屏居中限宽）
  static const double maxContentWidth = 600;

  /// Desktop content width (wider than mobile 600)
  static const double desktopContentWidth = 900;

  /// Breakpoint: below this width, use mobile layout
  static const double desktopBreakpoint = 720;
}
