import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_colors.dart';

/// Extension methods for easy, direct access to the app theme and color tokens.
/// Usage in any widget:
/// ```dart
/// context.colors.primary
/// context.colors.card
/// context.colors.background
/// ```
extension BuildContextThemeExtension on BuildContext {
  /// Access active [AppColors] for the current BuildContext
  AppColors get colors {
    return Theme.of(this).extension<AppColors>() ?? AppColors.light;
  }
}

/// Extension on GetInterface for accessing colors outside of build contexts where needed.
extension GetThemeExtension on GetInterface {
  /// Global access to active [AppColors]
  AppColors get colors {
    final ctx = Get.context;
    if (ctx != null) {
      return Theme.of(ctx).extension<AppColors>() ?? AppColors.light;
    }
    return AppColors.light;
  }
}
