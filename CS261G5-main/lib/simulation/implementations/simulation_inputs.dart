import 'package:air_traffic_sim/simulation/implementations/rate_parameters.dart';

/// Stores the parameters of a simulation
class SimulationInputs extends RateParameters{
  SimulationInputs({
    required super.runways,
    required super.emergencyProbability,
    required super.events,
    required super.maxWaitTime,
    required super.minFuelThreshold,
    required super.duration,
    required super.outboundRate,
    required super.inboundRate,
  });
}
