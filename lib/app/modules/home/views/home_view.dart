import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

/// Client landing view presenting Aurelia - Colosseum Audio Tour introduction.
/// Matches the reference client UI design with hero background, emblem,
/// descriptive copy, and 'Start Tour' CTA.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0908),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed hero background image
        Image.asset(
          'assets/images/background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F1A15), Color(0xFF0A0908)],
              ),
            ),
          ),
        ),

        // Dark gradient overlay for contrast
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.65, 1.0],
              colors: [
                const Color(0xFF0A0908).withValues(alpha: 0.3),
                const Color(0xFF0A0908).withValues(alpha: 0.5),
                const Color(0xFF0A0908).withValues(alpha: 0.85),
                const Color(0xFF0A0908),
              ],
            ),
          ),
        ),

        // Responsive content container with zero overflow protection
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
                                  // Decorative Colosseum emblem
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF15120F)
                                          .withValues(alpha: 0.6),
                                      border: Border.all(
                                        color: const Color(0xFFC9A24B)
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFE5CB7A),
                                          Color(0xFFC9A24B),
                                          Color(0xFFA8692C),
                                        ],
                                      ).createShader(bounds),
                                      child: const Icon(
                                        Icons.stadium,
                                        size: 44,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Roman Aurelia branding title
                                  const Text(
                                    'Aurelia',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFC9A24B),
                                      letterSpacing: 4,
                                      fontSize: 44,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Elegant subtle divider
                                  Container(
                                    width: 48,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFC9A24B)
                                              .withValues(alpha: 0.5),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Tour description
                                  const Text(
                                    'Explore the Colosseum through panoramic views and immersive audio narration. Navigate through 5 iconic stops.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.7,
                                      color: Color(0xFF9B9183),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Primary CTA button: Start Tour
                          FadeTransition(
                            opacity: _fade,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                key: const Key('home_next_button'),
                                onPressed: widget.onStartTour,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC9A24B),
                                  foregroundColor: const Color(0xFF0A0908),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Start Tour',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF0A0908),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Subtle audio experience indicator
                          FadeTransition(
                            opacity: _fade,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.headphones_rounded,
                                  size: 14,
                                  color: Color(0xFF5C544B),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Immersive Audio Experience',
                                  style: TextStyle(
                                    color: Color(0xFF5C544B),
                                    fontSize: 11,
                                    letterSpacing: 1,
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
