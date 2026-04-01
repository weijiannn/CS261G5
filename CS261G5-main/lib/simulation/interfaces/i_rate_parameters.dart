import 'package:air_traffic_sim/simulation/interfaces/i_parameters.dart';

abstract class IRateParameters extends IParameters {
  
  /// Getters
  
  int get getOutboundRate;
  int get getInboundRate;
}
