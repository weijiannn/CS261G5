import 'package:air_traffic_sim/simulation/interfaces/i_airport.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_simulation_controller.dart';
import 'package:flutter/material.dart';

/// Abstract class for a simulation.
abstract class AbstractSimulation implements ISimulation {
  @protected
  late final ISimulationController controller;
  @protected
  late final IAirport airport;
}