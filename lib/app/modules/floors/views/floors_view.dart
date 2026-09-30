import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_extensions.dart';
import '../controllers/floors_controller.dart';
import '../widgets/floor_card.dart';

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
                  horizontal: 26.0,
                  vertical: 28.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Prominent Place Name Header
                    Obx(
                      () => Container(
                        height: 60.0,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: colors.border,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.foreground.withValues(alpha: 0.04),
                              blurRadius: 8.0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          controller.landmarkName.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w800,
                            fontSize: 24.0,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),

                    // 2. Large Vertical Gap visually separating header from floor cards
                    const SizedBox(height: 68.0),

                    // 3. Data-driven Floor Cards List
                    Obx(
                      () => Column(
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
                              SizedBox(height: i == 0 ? 18.0 : 22.0),
                          ],
                        ],
                      ),
                    ),

                    // 4. Flexible bottom spacing
                    const SizedBox(height: 48.0),
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
