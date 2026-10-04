import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../controllers/floors_controller.dart';
import '../widgets/floor_card.dart';

/// Screen allowing the user to select which level of the Colosseum to explore.
class FloorsView extends GetView<FloorsController> {
  const FloorsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Prominent Place Name Header with Subtitle
                    Obx(
                      () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.8),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.foreground.withValues(alpha: 0.04),
                              blurRadius: 8.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.landmarkName.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineSmall?.copyWith(
                                color: colors.foreground,
                                fontWeight: FontWeight.w800,
                                fontSize: 22.0,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Select a level to explore',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.mutedForeground.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                                fontSize: 13.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Comfortable spacing separating header from section intro
                    const SizedBox(height: 24.0),

                    // 3. Section Label
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                      child: Text(
                        'Available levels',
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.mutedForeground.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.0,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    // 4. Data-driven Floor Cards List
                    Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < controller.floors.length; i++) ...[
                            FloorCard(
                              floor: controller.floors[i],
                              isSelected: controller.selectedFloorId.value ==
                                  controller.floors[i].id,
                              onTap: () => controller.selectFloor(
                                controller.floors[i].id,
                              ),
                            ),
                            if (i < controller.floors.length - 1)
                              const SizedBox(height: 14.0),
                          ],
                        ],
                      ),
                    ),

                    // 5. Bottom spacing
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
