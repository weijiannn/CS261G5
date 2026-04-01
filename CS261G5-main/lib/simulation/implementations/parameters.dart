import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway_event.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart'; 


class Parameters implements IParameters {
  final List<IRunway> _runways;
  final double _emergencyProbability;
  final Iterable<IRunwayEvent> _events;
  final int _maxWaitTime;
  final int _minFuelThreshold;
  final int _duration;

  Parameters({
    required List<IRunway> runways,
    required double emergencyProbability,
    required Iterable<IRunwayEvent> events,
    required int maxWaitTime,
    required int minFuelThreshold,
    required int duration,
  })  : _runways = runways,
        _emergencyProbability = emergencyProbability,
        _events = events,
        _maxWaitTime = maxWaitTime,
        _minFuelThreshold = minFuelThreshold,
        _duration = duration {
    final runwayIds = <int>{};
    for (final runway in _runways) {
      if (!runwayIds.add(runway.id)) {
        throw ArgumentError.value(
          runway.id,
          'runways',
          'runway ids must be unique in a scenario',
        );
      }
    }
  }


  @override
  List<IRunway> get getRunways => _runways;

  @override
  double get getEmergencyProbability => _emergencyProbability;

  @override
  Iterable<IRunwayEvent> get getEvents => _events;

  @override
  int get getMaxWaitTime => _maxWaitTime;

  @override
  int get getMinFuelThreshold => _minFuelThreshold;

  @override
  int get getDuration => _duration;

  @override
  int get getLandingRunwayCount => getRunways.whereType<LandingRunway>().length;

  @override
  int get getTakeoffRunwayCount => getRunways.whereType<TakeOffRunway>().length;

  @override
  int get getMixedRunwayCount => getRunways.whereType<MixedRunway>().length;
}