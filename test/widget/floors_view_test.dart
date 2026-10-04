import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/floors/controllers/floors_controller.dart';
import 'package:colosseum_client/app/modules/floors/views/floors_view.dart';
import 'package:colosseum_client/app/modules/floors/widgets/floor_card.dart';

import 'package:colosseum_client/app/routes/app_pages.dart';

import '../helpers/mock_tts.dart';

void main() {
  setUpAll(() {
    setupMockTts();
  });

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'FloorsView renders place name header, floor cards, and switches selection on tap',
    (WidgetTester tester) async {
      final controller = Get.put(FloorsController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorsView(),
          getPages: AppPages.routes,
        ),
      );

      // Verify Place Name Header
      expect(find.text('Colosseum'), findsOneWidget);

      // Verify all 4 Floor cards
      expect(find.byType(FloorCard), findsNWidgets(4));
      expect(find.text('Underground (Hypogeum)'), findsOneWidget);
      expect(find.text('Floor 1'), findsOneWidget);
      expect(find.text('Floor 2'), findsOneWidget);
      expect(find.text('Floor 3'), findsOneWidget);

      // Verify viewpoint count badges
      expect(find.text('7 viewpoints'), findsNWidgets(2));
      expect(find.text('9 viewpoints'), findsOneWidget);
      expect(find.text('5 viewpoints'), findsOneWidget);

      // Verify initial checkmark on Underground
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(controller.selectedFloorId.value, 'floor_underground');

      // Tap on Floor 1
      await tester.tap(find.text('Floor 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify selection moved to Floor 1
      expect(controller.selectedFloorId.value, 'floor_1');
    },
  );

  testWidgets(
    'FloorsView dynamically displays completed count badge (e.g. completed: 5) and updates to Completed when all visited',
    (WidgetTester tester) async {
      final controller = Get.put(FloorsController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const FloorsView(),
          getPages: AppPages.routes,
        ),
      );

      // Initially all floors have completed: 0
      expect(find.text('completed: 0'), findsNWidgets(4));

      // Mark 5 viewpoints as visited on Underground
      controller.visitedService.setVisitedIdsForTesting([
        'vp_100', 'vp_101', 'vp_102', 'vp_103', 'vp_104'
      ]);
      await tester.pump();

      // Underground card now displays "completed: 5"
      expect(find.text('completed: 5'), findsOneWidget);
      expect(find.text('completed: 0'), findsNWidgets(3));

      // Complete all 7 viewpoints on Underground
      controller.visitedService.setVisitedIdsForTesting([
        'vp_100', 'vp_101', 'vp_102', 'vp_103', 'vp_104', 'vp_105', 'vp_106'
      ]);
      await tester.pump();

      // Underground now displays "Completed"
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('completed: 5'), findsNothing);
    },
  );
}
