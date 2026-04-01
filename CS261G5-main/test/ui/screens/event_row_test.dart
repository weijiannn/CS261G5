import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/ui/models/runway_config_ui.dart';
import 'package:air_traffic_sim/ui/widgets/runway_event_row.dart'; 
void main() {
  group('Runway Event Row Tests', () {
    testWidgets('Tapping the delete icon triggers onDelete callback', (WidgetTester tester) async {
      bool deletePressed = false;
      
      final dummyEvent = RunwayEventUI(type: 'Inspection');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RunwayEventRow(
              event: dummyEvent,
              onChanged: () {},
              onDelete: () => deletePressed = true, 
            ),
          ),
        ),
      );

      final deleteIcon = find.byIcon(Icons.remove_circle);
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      
      expect(deletePressed, isTrue);
    });
  });
}