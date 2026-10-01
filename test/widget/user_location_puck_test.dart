import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colosseum_client/app/modules/floor_map/widgets/user_location_puck.dart';

void main() {
  group('UserLocationPuck Widget Tests', () {
    testWidgets('Renders center location dot and radar pulse without arrow when heading is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserLocationPuck(
                headingDegrees: null,
                accuracyMeters: 2.5,
              ),
            ),
          ),
        ),
      );

      // Verify puck structure
      expect(find.byType(UserLocationPuck), findsOneWidget);
      expect(find.byKey(const Key('heading_arrow_layer')), findsNothing); // No heading arrow
      expect(find.byType(Container), findsWidgets); // Contains location dot and radar rings
    });

    testWidgets('Renders live heading directional arrow when headingDegrees is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserLocationPuck(
                headingDegrees: 90.0, // Facing East
                accuracyMeters: 2.0,
                puckColor: Color(0xFF1976D2),
              ),
            ),
          ),
        ),
      );

      // Arrow CustomPaint is rendered
      expect(find.byType(UserLocationPuck), findsOneWidget);
      expect(find.byKey(const Key('heading_arrow_layer')), findsOneWidget);
      expect(find.byKey(const Key('heading_arrow_painter')), findsOneWidget);

      // Smoothly updates heading
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserLocationPuck(
                headingDegrees: 180.0, // Facing South
                accuracyMeters: 2.0,
                puckColor: Color(0xFF1976D2),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(UserLocationPuck), findsOneWidget);
      expect(find.byKey(const Key('heading_arrow_layer')), findsOneWidget);
    });
  });
}
