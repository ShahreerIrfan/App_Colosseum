import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/routes/app_pages.dart';

import '../helpers/mock_http_overrides.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Full onboarding navigation flow: Splash -> Language -> Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        theme: AppTheme.lightTheme,
      ),
    );

    // Initial frame
    await tester.pump();

    // 1. Splash screen is visible initially
    expect(find.text('COLOSSEUM'), findsOneWidget);
    expect(find.text('AUDIO GUIDE'), findsOneWidget);

    // 2. Wait for splash timer (>2s)
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    // 3. Language selection screen is now visible
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Italiano'), findsOneWidget);

    // 4. Tap 'Italiano'
    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();

    // 5. Tap 'Continue'
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 6. Home/Main screen with map is now visible
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Colosseum'), findsNWidgets(2)); // Recenter button + Map Marker label

    // 7. Verify previous onboarding screens are not on the stack
    expect(find.text('Choose your language'), findsNothing);
    expect(find.text('AUDIO GUIDE'), findsNothing);
  });
}
