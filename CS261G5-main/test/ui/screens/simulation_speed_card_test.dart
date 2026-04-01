import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/ui/widgets/speed_slider.dart'; 

void main() {
  group('SimulationSpeedCard Tests', () {
    testWidgets('Displays current speed and triggers add event callback', (WidgetTester tester) async {
      bool addEventPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimulationSpeedCard(
              speedMultiplier: 2.0, // Set speed to 2x
              simulationTimeLabel: '12:00',
              onSpeedChanged: (newSpeed) {}, 
              onAddRunwayEvent: () => addEventPressed = true, // Track if pressed
            ),
          ),
        ),
      );

      expect(find.text('2.00x'), findsWidgets);

      final addButton = find.text('Add Runway Event');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      expect(addEventPressed, isTrue);
    });
  });
}