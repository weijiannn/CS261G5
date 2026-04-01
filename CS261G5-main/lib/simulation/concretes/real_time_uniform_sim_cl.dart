import 'package:air_traffic_sim/simulation/abstracts/real_time_generative_cl.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_rate_parameters.dart';
import 'package:air_traffic_sim/simulation/mixins/real_time_controller.dart';
import 'package:air_traffic_sim/simulation/mixins/uniform_generator.dart';
import 'package:air_traffic_sim/ui/utils/runway_animation_helpers.dart';

class RealTimeUniformSimulationController extends RealTimeGenerativeController with RealTimeController,UniformGenerator {
  RealTimeUniformSimulationController(IRateParameters p,RunwayAnimationManager runwayAnimationManager) : super(p,runwayAnimationManager){
    init(p.getInboundRate,p.getOutboundRate);
    generateInbounds();
    generateOutbounds();
  }
}