import 'package:flutter_test/flutter_test.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';
import 'package:air_traffic_sim/ui/utils/realtime_event_utils.dart';

void main() {
  group('Realtime Event Utils Tests', () {
    final now = DateTime(2025, 1, 1, 12, 0, 0);

    test('isEventActive returns true for an ongoing event', () {
      final activeEvent = SimulationEvent(
        id: 'event-1',
        runwayId: 1,
        eventType: RunwayStatus.inspection,
        dtStartTime: now.subtract(const Duration(minutes: 5)),
        duration: const Duration(minutes: 10),
      );

      expect(isEventActive(activeEvent, now), isTrue);
      expect(isEventUpcoming(activeEvent, now), isFalse);
    });

    test('isEventUpcoming returns true for a future event', () {
      final upcomingEvent = SimulationEvent(
        id: 'event-2',
        runwayId: 1,
        eventType: RunwayStatus.closure,
        dtStartTime: now.add(const Duration(minutes: 10)),
        duration: const Duration(minutes: 5),
      );

      expect(isEventUpcoming(upcomingEvent, now), isTrue);
      expect(isEventPast(upcomingEvent, now), isFalse);
    });
  });
}