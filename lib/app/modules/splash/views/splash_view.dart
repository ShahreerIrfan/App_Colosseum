import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Instantiate lazy controller upon view build
    controller;

    final colors = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // TODO: Replace placeholder icon with brand logo asset when available.
                Icon(
                  Icons.account_balance_rounded,
                  size: 80,
                  color: colors.primary,
                ),
                const SizedBox(height: 28),
                Text(
                  'COLOSSEUM',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AUDIO GUIDE',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Explore 2,000 years of history',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.mutedForeground,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => Text(
                      controller.syncStatusMessage.value,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.primary.withValues(alpha: 0.8),
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    )),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
