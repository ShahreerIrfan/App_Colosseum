import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:colosseum_client/app/core/theme/app_theme.dart';
import 'package:colosseum_client/app/routes/app_pages.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('App smoke test launches at Splash', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        title: "Colosseum Tour Guide",
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
        theme: AppTheme.lightTheme,
      ),
    );

    expect(find.text('COLOSSEUM'), findsOneWidget);
    expect(find.text('AUDIO GUIDE'), findsOneWidget);
  });
}
