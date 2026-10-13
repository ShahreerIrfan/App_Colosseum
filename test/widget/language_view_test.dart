import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/modules/language/controllers/language_controller.dart';
import 'package:colosseum_client/app/modules/language/views/language_view.dart';
import 'package:colosseum_client/app/routes/app_pages.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'LanguageView renders languages, shows default selection, and changes selection on tap',
    (WidgetTester tester) async {
      final controller = Get.put(LanguageController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const LanguageView(),
        ),
      );

      // Verify title and description
      expect(find.text('Select Language'), findsOneWidget);
      expect(
        find.text(
          'English audio guide is available now.\nAdditional languages will be released soon.',
        ),
        findsOneWidget,
      );

      // Verify language options are visible
      expect(find.text('English'), findsWidgets);
      expect(find.text('Italiano'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Français'), 100);
      expect(find.text('Français'), findsOneWidget);

      // Verify Continue button is visible
      expect(find.byKey(const Key('language_continue_button')), findsOneWidget);

      // Verify default selection is English
      expect(controller.selectedLanguageCode.value, 'en');

      // Tap on Italiano
      await tester.scrollUntilVisible(find.text('Italiano'), -100);
      await tester.tap(find.text('Italiano'));
      await tester.pump();

      // Verify selection updated
      expect(controller.selectedLanguageCode.value, 'it');

      // Tap on Français
      await tester.scrollUntilVisible(find.text('Français'), 100);
      await tester.tap(find.text('Français'));
      await tester.pump();

      // Verify selection updated
      expect(controller.selectedLanguageCode.value, 'fr');
    },
  );

  testWidgets(
    'LanguageView fits narrow Android screen (360x640) without any layout overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Get.put(LanguageController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const LanguageView(),
        ),
      );

      // Scroll to Portuguese (which previously overflowed)
      await tester.scrollUntilVisible(find.text('Portuguese'), 100);
      expect(find.text('Portuguese'), findsOneWidget);
      expect(find.text('Português'), findsOneWidget);

      // Scroll down to Korean
      await tester.scrollUntilVisible(find.text('Korean'), 100);
      expect(find.text('Korean'), findsOneWidget);

      // Verify no exceptions or overflow occurred
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'LanguageView fits ultra-narrow Android screen (320x480) without any layout overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Get.put(LanguageController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const LanguageView(),
        ),
      );

      // Scroll to Portuguese
      await tester.scrollUntilVisible(find.text('Portuguese'), 100);
      expect(find.text('Portuguese'), findsOneWidget);

      // Verify no exceptions or overflow occurred
      expect(tester.takeException(), isNull);
    },
  );
}
