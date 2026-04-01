import 'dart:collection';

import 'package:air_traffic_sim/simulation/abstracts/abstract_controller.dart';
import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/simulation/fakes.dart';

void main() {
  group('AbstractController.startRunwayEvents', () {
    setUp(() {
      SimulationClock.reset();
    });

    test('processes events without reading first from an empty queue', () {
      final runway = FakeRunway(id: 11, normalMode: RunwayMode.landing);
      final airport = FakeAirport(runways: [runway]);
      final controller = _TestController();
      final events = Queue<IRunwayEvent>.from([
        FakeRunwayEvent(
          runwayId: 11,
          startTime: 0,
          duration: 15,
          eventType: RunwayStatus.inspection,
        ),
      ]);

      expect(
        () => controller.startRunwayEvents(events, airport),
        returnsNormally,
      );

      expect(events, isEmpty);
      expect(runway.closedDurations, [15]);
      expect(runway.closedStatuses, [RunwayStatus.inspection]);
    });
  });
}

class _TestController extends AbstractController {
  _TestController() : super(FakeParameters());

  @override
  IAircraft get nextInbound => FakeAircraft(id: 'X', operator: 'OP');

  @override
  IAircraft get nextOutbound => FakeAircraft(id: 'X', operator: 'OP');

  @override
  IAircraft get getNextInbound => FakeAircraft(id: 'X', operator: 'OP');

  @override
  IAircraft get getNextOutbound => FakeAircraft(id: 'X', operator: 'OP');
}
