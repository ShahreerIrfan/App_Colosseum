import 'package:flutter/material.dart';

/// App-wide border radius tokens matching CSS variables.
/// --radius: 0.625rem (10px)
class AppRadius {
  AppRadius._();

  /// --radius-sm: calc(var(--radius) - 4px) => 6px
  static const double sm = 6.0;

  /// --radius-md: calc(var(--radius) - 2px) => 8px
  static const double md = 8.0;

  /// --radius-lg: var(--radius) => 10px
  static const double lg = 10.0;

  /// --radius-xl: calc(var(--radius) + 4px) => 14px
  static const double xl = 14.0;

  /// Circular radius values
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);

  /// BorderRadius objects
  static const BorderRadius borderSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderXl = BorderRadius.all(radiusXl);
  static const BorderRadius borderPill = BorderRadius.all(
    Radius.circular(999.0),
  );
}
