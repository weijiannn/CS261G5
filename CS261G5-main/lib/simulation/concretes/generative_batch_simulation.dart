import 'package:air_traffic_sim/simulation/abstracts/batch_simulation.dart';
import 'package:air_traffic_sim/simulation/abstracts/generative_controller.dart';

class GenerativeBatchSimulation<T extends GenerativeController> extends AbstractBatchSimulation {
  GenerativeBatchSimulation(super.param,T cl) {
    controller = cl;
  }
}