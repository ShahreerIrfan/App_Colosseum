import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../controllers/home_controller.dart';

/// Client landing view presenting Aurelia - Colosseum Audio Tour introduction.
/// Implements the client UI layout (hero background, circular stadium emblem,
/// Aurelia branding, tour description, full-width Start Tour CTA, and audio indicator)
/// strictly following the ColosseumClient Light Theme tokens.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: _HomeLandingContent(
        onStartTour: controller.navigateToAllPointsMap,
      ),
    );
  }
}

class _HomeLandingContent extends StatefulWidget {
  final VoidCallback onStartTour;

  const _HomeLandingContent({required this.onStartTour});

  @override
  State<_HomeLandingContent> createState() => _HomeLandingContentState();
}

class _HomeLandingContentState extends State<_HomeLandingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final isTest = Get.testMode;
    _controller = AnimationController(
      vsync: this,
      duration: isTest ? Duration.zero : const Duration(milliseconds: 1200),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (isTest) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed hero background artwork
        Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: colors.background,
          ),
        ),

        // Luminous light gradient vignette overlay honoring the ColosseumClient light theme
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.70, 1.0],
              colors: [
                colors.background.withValues(alpha: 0.65),
                colors.background.withValues(alpha: 0.85),
                colors.background.withValues(alpha: 0.95),
                colors.background,
              ],
            ),
          ),
        ),

        // Responsive content container with zero overflow protection across all mobile screens
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),

                          // Title and emblem section with fade and slide transition
                          FadeTransition(
                            opacity: _fade,
                            child: SlideTransition(
                              position: _slide,
                              child: Column(
                                children: [
                                  // Decorative circular Colosseum emblem
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.card,
                                      border: Border.all(
                                        color: colors.primary
                                            .withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary
                                              .withValues(alpha: 0.12),
                                          blurRadius: 24,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          colors.primary,
                                          colors.ring,
                                          colors.primary,
                                        ],
                                      ).createShader(bounds),
                                      child: Icon(
                                        Icons.stadium,
                                        size: 46,
                                        color: colors.primaryForeground,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Roman Aurelia branding title in theme foreground
                                  Text(
                                    'Aurelia',
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineLarge?.copyWith(
                                      color: colors.foreground,
                                      letterSpacing: 4.0,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Elegant subtle divider
                                  Container(
                                    width: 48,
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colors.primary
                                              .withValues(alpha: 0.0),
                                          colors.primary
                                              .withValues(alpha: 0.5),
                                          colors.primary
                                              .withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Tour description in semantic muted foreground
                                  Text(
                                    'Explore the Colosseum through panoramic views and immersive audio narration. Navigate through 5 iconic stops.',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      height: 1.7,
                                      color: colors.mutedForeground,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Primary CTA button: Start Tour in Roman Imperial Red theme
                          FadeTransition(
                            opacity: _fade,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                key: const Key('home_next_button'),
                                onPressed: widget.onStartTour,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.primaryForeground,
                                  elevation: 4,
                                  shadowColor: colors.primary
                                      .withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Start Tour',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colors.primaryForeground,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtle audio experience indicator
                          FadeTransition(
                            opacity: _fade,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.headphones_rounded,
                                  size: 15,
                                  color: colors.mutedForeground
                                      .withValues(alpha: 0.75),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Immersive Audio Experience',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.mutedForeground
                                        .withValues(alpha: 0.75),
                                    fontSize: 11,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),
                        ],
                      ),
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
