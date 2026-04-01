import 'package:air_traffic_sim/simulation/concretes/sim_clock.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/exceptions/runway_unavailable_exception.dart';
import 'package:air_traffic_sim/simulation/implementations/aircraft.dart';
import 'package:air_traffic_sim/simulation/implementations/airport.dart';
import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    SimulationClock.reset();
  });

  test('throws when using unavailable runway', () {
    final runway = LandingRunway(id: 1);
    final airport = Airport([runway]);

    runway.closeRunway(10, RunwayStatus.maintenance);

    expect(
      () => airport.useRunway(1),
      throwsA(isA<RunwayUnavailableException>()),
    );
  });

  test('returns zero delay when queue for selected runway mode is empty', () {
    final airport = Airport([LandingRunway(id: 1), TakeOffRunway(id: 2)]);

    expect(airport.useRunway(1), 0);
    expect(airport.useRunway(2), 0);
  });

  test('useRunway computes delay from simulation time and aircraft schedule', () {
    final airport = Airport([LandingRunway(id: 1)]);
    final aircraft = InboundAircraft(
      id: 'A-1',
      scheduledTime: 3,
      actualTime: 3,
      fuelLevel: 20,
    );

    airport.addToHolding(aircraft);
    SimulationClock.time = 8;

    final delay = airport.useRunway(1);

    expect(delay, 5);
  });
}
