import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';
import 'package:air_traffic_sim/simulation/abstracts/real_time_simulation.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_real_controller.dart';

/// T must also implement [IRealTimeController] for this to work, but that is not enforced by the type system.
///  It is the responsibility of the user to ensure that T implements both [GenerativeController] and [IRealTimeController].
class RealTimeGenerativeSimulation<T extends GenerativeController> extends AbstractRealTimeSimulation {
  RealTimeGenerativeSimulation(super.param,T cl){
    if (cl is! IRealTimeController) {
      throw ArgumentError('T must implement IRealTimeController');
    }
    controller = cl;
  }
}