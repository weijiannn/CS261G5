import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart';
import 'package:air_traffic_sim/simulation/mixins/uniform_generator.dart';

/// A controller for dynamically generating uniformally scheduled aircraft, 
/// with actual times distributed N(schedule,5).
class UniformSimulationController extends GenerativeController with UniformGenerator {
  UniformSimulationController(IRateParameters p) : super(p){
    init(p.getInboundRate, p.getOutboundRate);
    generateInbounds();
    generateOutbounds();
  }
}
