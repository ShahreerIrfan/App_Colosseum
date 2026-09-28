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
      expect(find.text('Choose your language'), findsOneWidget);
      expect(
        find.text(
          'Select the language you would like to use during your Colosseum experience.',
        ),
        findsOneWidget,
      );

      // Verify language options are visible
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);

      // Verify Continue button is visible
      expect(find.text('Continue'), findsOneWidget);

      // Verify default selection is English
      expect(controller.selectedLanguageCode.value, 'en');

      // Tap on Italiano
      await tester.tap(find.text('Italiano'));
      await tester.pump();

      // Verify selection updated
      expect(controller.selectedLanguageCode.value, 'it');

      // Tap on Français
      await tester.tap(find.text('Français'));
      await tester.pump();

      // Verify selection updated
      expect(controller.selectedLanguageCode.value, 'fr');
    },
  );
}
