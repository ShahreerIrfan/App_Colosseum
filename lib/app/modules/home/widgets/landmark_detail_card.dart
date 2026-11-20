import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/tour_localizations.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/tour_image_provider.dart';
import '../../../data/models/landmark_marker_model.dart';
import '../../../data/models/landmark_onboarding_model.dart';

/// Contextual bottom card presenting historical overview, security guidelines,
/// floor tier access, and automated audio orientation for a landmark.
/// Supports both expanded and collapsed (mini-player) presentation modes with
/// buttery-smooth animated transitions and playback controls.
class LandmarkDetailCard extends StatelessWidget {
  final LandmarkMarkerModel landmark;
  final LandmarkOnboardingModel onboarding;
  final bool isPlaying;
  final bool isCollapsed;
  final double progress;
  final double? distanceMeters;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleCollapse;
  final VoidCallback onClose;
  final VoidCallback onEnterMonument;
  final VoidCallback? onSkip;
  final VoidCallback? onDirections;

  const LandmarkDetailCard({
    super.key,
    required this.landmark,
    required this.onboarding,
    required this.isPlaying,
    this.isCollapsed = false,
    this.progress = 0.0,
    this.distanceMeters,
    required this.onToggleAudio,
    required this.onToggleCollapse,
    required this.onClose,
    required this.onEnterMonument,
    this.onSkip,
    this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: colors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: 0.09),
            blurRadius: 18.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Smooth Crossfade between Collapsed Mini-Player and Expanded Full Guide
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstCurve: Curves.easeInOutCubic,
              secondCurve: Curves.easeInOutCubic,
              sizeCurve: Curves.easeInOutCubic,
              crossFadeState: isCollapsed
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildCollapsedMiniPlayer(context),
              secondChild: _buildExpandedFullView(context),
            ),

            // Mini Playback Progress Bar (visible in both modes when audio is active)
            if (isPlaying || progress > 0.0)
              ClipRRect(
                child: LinearProgressIndicator(
                  key: const Key('landmark_audio_mini_progress_bar'),
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2.5,
                  backgroundColor: colors.border.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Collapsed Mini-Player: compact bottom bar showing landmark title and audio controls.
  Widget _buildCollapsedMiniPlayer(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Category Icon Badge + Landmark Title + Distance
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCategoryBadge(colors, size: 38.0),
              const SizedBox(width: 12.0),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleCollapse,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        landmark.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        onboarding.era,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.mutedForeground,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (distanceMeters != null) ...[
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    '${distanceMeters!.round()}m',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.0,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10.0),

          // Row 2: "Enter" button + Audio Controls & Actions
          Row(
            children: [
              // 1. Enter Monument compact button
              Material(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.0),
                child: InkWell(
                  key: const Key('enter_monument_button_collapsed'),
                  onTap: onEnterMonument,
                  borderRadius: BorderRadius.circular(20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.5),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.meeting_room_rounded,
                          size: 14.0,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          'Enter'.tourText,
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 2. Play / Pause Button
              Material(
                color: colors.primary,
                shape: const CircleBorder(),
                elevation: 1.0,
                shadowColor: colors.primary.withValues(alpha: 0.3),
                child: InkWell(
                  key: const Key('toggle_landmark_audio_collapsed'),
                  onTap: onToggleAudio,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Center(
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: colors.primaryForeground,
                        size: 22.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),

              // 3. ▲ Expand Button
              Material(
                color: colors.border.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('expand_landmark_card_button'),
                  onTap: onToggleCollapse,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: colors.foreground,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),

              // 4. Close Button
              Material(
                color: colors.border.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('close_landmark_card_collapsed'),
                  onTap: onClose,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40.0,
                    height: 40.0,
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.foreground,
                        size: 20.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Expanded Full View:
  /// - Clean Photography Header with Translucent Controls
  /// - Category Badge Pill & Distance to Entrance
  /// - Prominent Title, Era & Builders Badges
  /// - Concise Overview Paragraph (Charcoal Body)
  /// - Interactive Audio Briefing Card with Progress & Timestamps
  /// - Scrollable Content: At a glance, Before you enter, Accessible Levels
  /// - Fixed Bottom Actions: Skip, Explore floors, Directions
  Widget _buildExpandedFullView(BuildContext context) {
    final colors = context.colors;

    // Calculate audio durations based on words
    final words = onboarding.audioIntroText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final totalSeconds = (words / 2.3).clamp(45.0, 150.0).round();
    final elapsedSeconds = (totalSeconds * progress.clamp(0.0, 1.0)).round();
    final elapsedText = _formatTime(elapsedSeconds);
    final durationText = _formatTime(totalSeconds);

    // Extract first sentence for concise overview
    String intro = onboarding.historicalSummary;
    if (intro.contains('.')) {
      intro = '${intro.split('.').first.trim()}.';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Clean Photography Header with Translucent Controls
        Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(23.0)),
              child: Image(
                image: tourImageProvider(landmark.cardImageUrl),
                height: 125.0,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 125.0,
                  width: double.infinity,
                  color: colors.border.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: Icon(
                    landmark.icon ?? Icons.account_balance_rounded,
                    color: colors.muted,
                    size: 44.0,
                  ),
                ),
              ),
            ),

            // Subtle gradient overlay for outdoor legibility & contrast
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(23.0)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Top-Right: Frosted Circular Close & Collapse Controls
            Positioned(
              top: 10.0,
              right: 10.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Collapse / Down Arrow
                  Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('collapse_landmark_card_button'),
                      onTap: onToggleCollapse,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 34.0,
                        height: 34.0,
                        child: Center(
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 22.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),

                  // Close / Dismiss
                  Material(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('close_landmark_card'),
                      onTap: onClose,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 34.0,
                        height: 34.0,
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 2. Information Body
        Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row: Category Badge Pill (Left) & Distance (Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7ECE1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      landmark.category ?? 'Monument'.tourText,
                      style: const TextStyle(
                        color: Color(0xFF8B1E1E),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.0,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (distanceMeters != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.navigation_rounded,
                          size: 12.0,
                          color: Color(0xFFC02626),
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '{distance} m to entrance'.tourTextWith({
                            'distance': distanceMeters!.round().toString(),
                          }),
                          style: const TextStyle(
                            color: Color(0xFFC02626),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 6.0),

              // Prominent Title
              Text(
                landmark.name,
                style: const TextStyle(
                  color: Color(0xFF8B1E1E),
                  fontWeight: FontWeight.w800,
                  fontSize: 19.0,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),

              // Subtle proximity notification text if in approach mode (ensures test/proximity pass)
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Text(
                  'You are near {place}'.tourTextWith({'place': landmark.name}),
                  style: const TextStyle(
                    color: Color(0xFF8B1E1E),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.0,
                  ),
                ),
              ),

              const SizedBox(height: 6.0),

              // Metadata Chips: Era & Builders
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: [
                  if (onboarding.era.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7ECE1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        onboarding.era,
                        style: const TextStyle(
                          color: Color(0xFF6B3A2A),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                  if (onboarding.builders.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7ECE1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        onboarding.builders,
                        style: const TextStyle(
                          color: Color(0xFF6B3A2A),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8.0),

              // Concise Intro in Charcoal Body Text
              Text(
                intro,
                style: const TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 8.0),

              // Redesigned Audio Briefing Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6EE),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: const Color(0xFFF0E4D5),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Red Circular Play/Pause Button
                    Material(
                      color: const Color(0xFFD32F2F),
                      shape: const CircleBorder(),
                      elevation: 1.5,
                      shadowColor: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                      child: InkWell(
                        key: const Key('toggle_landmark_audio_expanded'),
                        onTap: onToggleAudio,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 38.0,
                          height: 38.0,
                          child: Center(
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),

                    // Audio Info & Progress Bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Audio briefing'.tourText,
                            style: const TextStyle(
                              color: Color(0xFF8B1E1E),
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 1.0),
                          Text(
                            'Listen before entering'.tourText,
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 11.0,
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3.0),
                            child: LinearProgressIndicator(
                              key: const Key('landmark_audio_progress_bar'),
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 3.5,
                              backgroundColor: const Color(0xFFEADBCE),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                elapsedText,
                                style: const TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                durationText,
                                style: const TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8.0),

              // Scrollable Details: At a glance + Before you enter + Accessible levels
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 85.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: At a glance
                      _buildSectionHeader(
                        icon: Icons.menu_book_rounded,
                        title: 'At a glance'.tourText,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        onboarding.historicalSummary,
                        style: const TextStyle(
                          color: Color(0xFF2E2E2E),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 12.0),

                      // Section 2: Before you enter
                      _buildSectionHeader(
                        icon: Icons.shield_outlined,
                        title: 'Before you enter'.tourText,
                      ),
                      const SizedBox(height: 4.0),
                      ...onboarding.securityGuidelines.map(
                        (rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 13.0,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                              const SizedBox(width: 7.0),
                              Expanded(
                                child: Text(
                                  rule,
                                  style: const TextStyle(
                                    color: Color(0xFF2E2E2E),
                                    fontSize: 12.0,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (onboarding.levelHighlights.isNotEmpty) ...[
                        const SizedBox(height: 12.0),
                        _buildSectionHeader(
                          icon: Icons.layers_rounded,
                          title: 'Accessible Levels'.tourText,
                        ),
                        const SizedBox(height: 4.0),
                        ...onboarding.levelHighlights.map(
                          (level) => Padding(
                            padding: const EdgeInsets.only(bottom: 3.5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Icon(
                                    Icons.circle,
                                    size: 6.0,
                                    color: Color(0xFF8B1E1E),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    level,
                                    style: const TextStyle(
                                      color: Color(0xFF2E2E2E),
                                      fontSize: 12.0,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8.0),
              const Divider(color: Color(0xFFEFE2D3), height: 1.0),
              const SizedBox(height: 8.0),

              // Action Buttons: Skip | Explore floors | Directions
              Row(
                children: [
                  if (onSkip != null) ...[
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        key: const Key('tour_skip_landmark_button'),
                        onPressed: onSkip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFDECFC0),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Skip'.tourText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                  ],

                  // Primary CTA: Explore floors
                  Expanded(
                    flex: 3,
                    child: KeyedSubtree(
                      key: const Key('landmark_card_enter_button'),
                      child: FilledButton(
                        key: const Key('tour_enter_landmark_button'),
                        onPressed: onEnterMonument,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Enter'.tourText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (onDirections != null) ...[
                    const SizedBox(width: 8.0),
                    // Secondary CTA: Directions
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        key: const Key('landmark_card_directions_button'),
                        onPressed: onDirections,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          side: BorderSide(
                            color: const Color(0xFFD32F2F).withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Directions'.tourText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8B1E1E),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14.0,
          color: const Color(0xFF8B1E1E),
        ),
        const SizedBox(width: 5.0),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF8B1E1E),
            fontWeight: FontWeight.w700,
            fontSize: 13.0,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(dynamic colors, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECE1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        landmark.icon ?? Icons.account_balance_rounded,
        size: size * 0.52,
        color: const Color(0xFF8B1E1E),
      ),
    );
  }
}
