import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/ui/utils/runway_style_utils.dart';

void main() {
  group('RunwayStatusUi Extension Tests', () {
    test('Available status returns green border and correct label', () {
      expect(RunwayStatus.available.uiLabel, 'AVAILABLE');
      expect(RunwayStatus.available.borderColor, Colors.greenAccent.shade400);
    });

    test('Closure status returns red border and correct label', () {
      expect(RunwayStatus.closure.uiLabel, 'CLOSURE');
      expect(RunwayStatus.closure.borderColor, Colors.redAccent.shade400);
    });

    test('Occupied status returns cyan border and correct label', () {
      expect(RunwayStatus.occupied.uiLabel, 'IN USE');
      expect(RunwayStatus.occupied.borderColor, Colors.cyanAccent.shade400);
    });
  });
}