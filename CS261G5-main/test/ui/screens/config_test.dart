import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/ui/models/runway_config_ui.dart';

void main() {
  group('RunwayConfigUI Validation Tests', () {
    test('isValid returns false for empty or single-digit runway IDs', () {
      final configEmpty = RunwayConfigUI(runwayId: '');
      final configSingleDigit = RunwayConfigUI(runwayId: '5');
      
      expect(configEmpty.isValid(), isFalse);
      expect(configSingleDigit.isValid(), isFalse);
    });

    test('isValid returns true for exactly two-digit runway IDs', () {
      final configValid = RunwayConfigUI(runwayId: '09');
      
      expect(configValid.isValid(), isTrue);
    });

    test('isValid returns false if event inputs are invalid', () {
      final eventUI = RunwayEventUI(type: 'Inspection')
        ..startController.text = '-5' // Invalid start time
        ..durationController.text = '0'; // Invalid duration

      final config = RunwayConfigUI(
        runwayId: '12',
        events: [eventUI],
      );

      expect(config.isValid(), isFalse);
    });
  });
}