import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart';
import 'package:air_traffic_sim/simulation/mixins/poisson_generator.dart';

/// A controller for dynamically generating exponentially scheduled aircraft, 
/// with actual times distributed N(schedule,5).
class PoissonSimulationController extends GenerativeController with PoissonGenerator{
  PoissonSimulationController(IRateParameters p) : super(p){
    init(p.getInboundRate, p.getOutboundRate);
    generateInbounds();
    generateOutbounds();
  }
}