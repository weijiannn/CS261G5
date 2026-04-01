import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart'; // The file containing IRateParameters
import 'package:air_traffic_sim/simulation/implementations/parameters.dart'; // The file containing the concrete Parameters class

class RateParameters extends Parameters implements IRateParameters {
  final int _outboundRate;
  final int _inboundRate;

  RateParameters({
    required super.runways,
    required super.emergencyProbability,
    required super.events,
    required super.maxWaitTime,
    required super.minFuelThreshold,
    required super.duration,
    
    required int outboundRate,
    required int inboundRate,
  })  : _outboundRate = outboundRate,
        _inboundRate = inboundRate;

  @override
  int get getOutboundRate => _outboundRate;

  @override
  int get getInboundRate => _inboundRate;
}
