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

    return Scaffold(
      backgroundColor: context.colors.background,
      body: _SplashContent(controller: controller),
    );
  }
}

class _SplashContent extends StatefulWidget {
  final SplashController controller;

  const _SplashContent({required this.controller});

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    final isTest = Get.testMode;

    _animController = AnimationController(
      vsync: this,
      duration: isTest ? Duration.zero : const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.7, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (isTest) {
      _animController.value = 1.0;
    } else {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background artwork with vignette overlay
        Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: colors.background,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.75, 1.0],
              colors: [
                colors.background.withValues(alpha: 0.82),
                colors.background.withValues(alpha: 0.92),
                colors.background,
                colors.background,
              ],
            ),
          ),
        ),
        // Center Emblem & Content
        Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Emblem with pulsing glow
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow rings
                              ...List.generate(3, (i) {
                                final ringGlow =
                                    (_glowAnimation.value - i * 0.2)
                                        .clamp(0.0, 1.0);
                                return Container(
                                  width: 105 + i * 22,
                                  height: 105 + i * 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.ring
                                          .withValues(alpha: 0.25 * ringGlow),
                                      width: 0.8,
                                    ),
                                  ),
                                );
                              }),
                              // Main circular emblem
                              Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(26),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        colors.card,
                                        colors.secondary,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: colors.ring.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.ring.withValues(
                                          alpha: 0.2 * _glowAnimation.value,
                                        ),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                      BoxShadow(
                                        color: colors.primary.withValues(
                                          alpha: 0.1 * _glowAnimation.value,
                                        ),
                                        blurRadius: 60,
                                        spreadRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colors.foreground,
                                        colors.primary,
                                        colors.ring,
                                      ],
                                    ).createShader(bounds),
                                    child: const Icon(
                                      Icons.stadium_rounded,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.foreground,
                              colors.primary,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'COLOSSEUM',
                            textAlign: TextAlign.center,
                            style: (textTheme.headlineMedium ??
                                    const TextStyle())
                                .copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primary,
                              colors.ring,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'AUDIO GUIDE',
                            textAlign: TextAlign.center,
                            style: (textTheme.titleMedium ??
                                    const TextStyle())
                                .copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Roman Diamond Divider
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.ring.withValues(alpha: 0.0),
                                    colors.ring.withValues(alpha: 0.6),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.ring,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.ring.withValues(alpha: 0.6),
                                    colors.ring.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'YOUR JOURNEY THROUGH HISTORY',
                          textAlign: TextAlign.center,
                          style: (textTheme.labelSmall ??
                                  const TextStyle())
                              .copyWith(
                            color: colors.mutedForeground
                                .withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() => Text(
                              widget.controller.syncStatusMessage.value,
                              textAlign: TextAlign.center,
                              style: (textTheme.bodySmall ??
                                      const TextStyle())
                                  .copyWith(
                                color: colors.mutedForeground
                                    .withValues(alpha: 0.75),
                                fontSize: 12,
                                letterSpacing: 0.4,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
