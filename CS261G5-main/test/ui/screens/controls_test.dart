import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/ui/widgets/controls_card.dart'; 

void main() {
  group('ControlsCard Widget Tests', () {
    testWidgets('Tapping buttons triggers respective callbacks', (WidgetTester tester) async {
      bool startPressed = false;
      bool pausePressed = false;
      bool backPressed = false;

      // Pump the widget into the testing environment
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ControlsCard(
              onStart: () => startPressed = true,
              onPause: () => pausePressed = true,
              onBack: () => backPressed = true,
            ),
          ),
        ),
      );

      // Verify the buttons are rendered
      expect(find.text('START'), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);

      // Tap START and verify
      await tester.tap(find.text('START'));
      expect(startPressed, isTrue);

      // Tap PAUSE and verify
      await tester.tap(find.text('PAUSE'));
      expect(pausePressed, isTrue);

      // Tap BACK and verify
      await tester.tap(find.text('BACK'));
      expect(backPressed, isTrue);
    });
  });
}