import 'package:flutter/widgets.dart';
import '../theme/spacing.dart';

/// Whether the current context is wide enough for desktop layout.
bool isDesktopLayout(BuildContext context) =>
    MediaQuery.of(context).size.width >= CpSpacing.desktopBreakpoint;

/// Content max width that adapts to screen size.
double contentMaxWidth(BuildContext context) =>
    isDesktopLayout(context)
        ? CpSpacing.desktopContentWidth
        : CpSpacing.maxContentWidth;
