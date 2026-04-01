import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_aircraft.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_real_controller.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_runway.dart';
import 'package:air_traffic_sim/ui/utils/runway_animation_helpers.dart';

abstract class RealTimeGenerativeController extends GenerativeController implements IRealTimeController {
  late final RunwayAnimationManager runwayAnimationManager;

  RealTimeGenerativeController(super.p,this.runwayAnimationManager);

  @override
  void depart(IRunway runway, IAircraft aircraft) {
    super.depart(runway, aircraft);
    runwayAnimationManager.startTakeoffAnimation(runway.id);
  }

  @override
  void land(IRunway runway, IAircraft aircraft) {
    super.land(runway, aircraft);
    runwayAnimationManager.startLandingAnimation(runway.id);
  }
}