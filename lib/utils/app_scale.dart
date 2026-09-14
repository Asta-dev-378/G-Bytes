// app_scale.dart — Shared adaptive sizing utility.
// Reads MediaQuery width and produces a scale factor relative to a 390dp baseline.
// All UI sizes should be expressed through sp() / dp() / icon() so the app looks
// correct on small phones, regular phones, and tablets without manual breakpoints.

import 'package:flutter/widgets.dart';

class AppScale {
  static const double _baseWidth = 390.0;
  static const double _maxScale = 1.35;
  static const double _minScale = 0.78;

  static double of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w / _baseWidth).clamp(_minScale, _maxScale);
  }

  /// Scale a font size (sp = scaled pixel).
  static double sp(BuildContext context, double size) => size * of(context);

  /// Scale a dimension (padding, margin, widget size, etc.).
  static double dp(BuildContext context, double size) => size * of(context);

  /// Scale an icon size.
  static double icon(BuildContext context, double size) => size * of(context);
}
