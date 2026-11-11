import '../../../core/localization/tour_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_extensions.dart';
import '../controllers/language_controller.dart';
import '../widgets/language_tile.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Header matching client design
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 10.0),
              child: Column(
                children: [
                  // Circular Emblem with translation icon
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.card,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.12),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.translate_rounded,
                        size: 32,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Select Language'.tourText,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 23,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Obx(() => Text(
                    controller.languages.where((option) => option.isAvailable).length > 1
                        ? 'Choose a language for the tour and narration.'.tourText
                        : 'English audio guide is available now.\nAdditional languages will be released soon.'.tourText,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  )),
                  const SizedBox(height: 12),
                  // Subtle divider
                  Container(
                    width: 48,
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.border.withValues(alpha: 0.0),
                          colors.primary.withValues(alpha: 0.4),
                          colors.border.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Language Lists
            Expanded(
              child: Obx(() {
                final selectedCode = controller.selectedLanguageCode.value;
                final availableLanguages = controller.languages.where((l) => l.isAvailable);
                final releasingSoonLanguages = controller.languages.where((l) => !l.isAvailable);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
                  children: [
                    // Section 1: AVAILABLE NOW
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AVAILABLE NOW'.tourText,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...availableLanguages.map((option) {
                      final isSelected = selectedCode == option.code;
                      return LanguageTile(
                        title: option.name,
                        nativeName: option.nativeName,
                        subtitle: 'Full Audio Guide'.tourText,
                        flag: option.flag,
                        isSelected: isSelected,
                        isAvailable: true,
                        onTap: () => controller.selectLanguage(option.code),
                      );
                    }),

                    const SizedBox(height: 18),

                    // Section 2: RELEASING SOON
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: colors.mutedForeground.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'RELEASING SOON'.tourText,
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.mutedForeground.withValues(alpha: 0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...releasingSoonLanguages.map((option) {
                      final isSelected = selectedCode == option.code;
                      return LanguageTile(
                        title: option.name,
                        nativeName: option.nativeName,
                        subtitle: 'Releasing Soon'.tourText,
                        flag: option.flag,
                        isSelected: isSelected,
                        isAvailable: false,
                        onTap: () => controller.selectLanguage(option.code),
                      );
                    }),
                  ],
                );
              }),
            ),

            // Bottom CTA Button & Footnote
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Obx(() {
                      final selectedLang = controller.selectedLanguage;
                      final busy = controller.isSyncing.value;
                      final buttonText = busy ? 'Downloading…'.tourText
                          : 'Continue with {language}'.tourTextWith({'language': selectedLang.nativeName});

                      return ElevatedButton(
                        key: const Key('language_continue_button'),
                        onPressed: busy ? null : controller.continueToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.primaryForeground,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderLg,
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.primaryForeground,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => controller.downloadFailed.value
                      ? Text('Connect to the internet to download this language.'.tourText)
                      : const SizedBox.shrink()),
                  Text(
                    'You can change your language anytime in Settings'.tourText,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
