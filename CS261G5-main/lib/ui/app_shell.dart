import 'package:air_traffic_sim/ui/models/realtime_dashboard_models.dart';
import 'package:air_traffic_sim/ui/screens/configuration.dart';
import 'package:air_traffic_sim/ui/screens/main_menu.dart';
import 'package:air_traffic_sim/ui/screens/real_time.dart';
import 'package:air_traffic_sim/ui/screens/results.dart';
import 'package:air_traffic_sim/ui/screens/scenario_comparison.dart';
import 'package:flutter/material.dart';
import '../simulation/interfaces/i_report.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  IReport? _currentReport;
  String? _latestScenarioName;
  String _latestGenerationModel = "Uniform";

  RealTimeScreenArguments? _realTimeScreenArguments;

  void _goToTab(int index, {Object? arguments}) {
    switch(arguments) {
      case ResultsNavigationPayload payload:
        _currentReport = payload.report;
        _latestScenarioName = payload.scenarioName;
        _latestGenerationModel = arguments.generationModel;
        break;
      case IReport report:
        _currentReport = report;
        break;
      case RealTimeScreenArguments args:
        _realTimeScreenArguments = args;
        break;
      default:
        // No arguments or unrecognized type, do nothing
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MainMenu(onNavigate: _goToTab),
      ConfigurationScreen(onNavigate: _goToTab),
      ResultsScreen(
        getReport: () => _currentReport,
        getLatestScenarioName: () => _latestScenarioName,
        getLatestGenerationModel: () => _latestGenerationModel,
        onNavigate: _goToTab,
      ),
      ScenarioScreen(onNavigate: _goToTab),
      RealTimeScreen(
        key: ValueKey(_realTimeScreenArguments), // Force rebuild when arguments change
        onNavigate: _goToTab,
        getArgs: () => _realTimeScreenArguments,
      )
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
    );
  }
}

class AppTab {
  static const mainmenu = 0;
  static const configuration = 1;
  static const results = 2;
  static const compare = 3;
  static const realtime = 4;
}

class ResultsNavigationPayload {
  final IReport report;
  final String? scenarioName;
  final String generationModel;

  const ResultsNavigationPayload({
    required this.report,
    this.scenarioName,
    this.generationModel = "Uniform",
  });
}
