import 'package:air_traffic_sim/persistence/app_persistence.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';

import 'dart:collection';

import 'dart:convert';

import 'package:air_traffic_sim/simulation/concretes/generative_batch_simulation.dart';
import 'package:air_traffic_sim/simulation/concretes/uniform_sim_controller.dart';
import 'package:air_traffic_sim/simulation/concretes/poisson_sim_controller.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import 'package:air_traffic_sim/simulation/implementations/rate_parameters.dart';
import 'package:air_traffic_sim/simulation/implementations/report.dart';
import 'package:air_traffic_sim/simulation/orchestration/run_persistence_orchestrator.dart';
import 'package:air_traffic_sim/ui/screens/real_time.dart';
import 'package:air_traffic_sim/ui/app_shell.dart';
import 'package:air_traffic_sim/ui/widgets/runway_canvas.dart';
import "../models/realtime_dashboard_models.dart";
import 'package:flutter/material.dart';

import '../models/runway_config_ui.dart';
import '../widgets/runway_card.dart';

class ConfigurationScreen extends StatefulWidget {
  final void Function(int index, {Object? arguments}) onNavigate;

  const ConfigurationScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

String _normaliseEmergencyProbabilityForUi(Object? rawValue, String fallback) {
  if (rawValue == null) {
    return fallback;
  }

  final parsed = rawValue is num ? rawValue.toDouble() : double.tryParse(rawValue.toString().trim());
  if (parsed == null) {
    return rawValue.toString();
  }

  final scaled = (parsed >= 0 && parsed <= 1) ? parsed * 100 : parsed;
  return scaled.round().toString();
}


class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();

  List<RunwayConfigUI> runways = [
    RunwayConfigUI(runwayId: '01'),
  ];

  final TextEditingController emergencyProbController =
      TextEditingController(text: "0");
  final TextEditingController inboundFlowController = TextEditingController(text: "15");
  final TextEditingController outboundFlowController = TextEditingController(text: "15");
  final TextEditingController maxWaitController =
      TextEditingController(text: "30");
  final TextEditingController fuelThresholdController =
      TextEditingController(text: "10");
  final TextEditingController durationController =
      TextEditingController(text: "1");
  String _selectedGenerationModel = "Uniform";

  @override
  void dispose() {
    emergencyProbController.dispose();
    inboundFlowController.dispose();
    outboundFlowController.dispose();
    maxWaitController.dispose();
    fuelThresholdController.dispose();
    durationController.dispose();
    super.dispose();
  }

  String? _selectedScenarioId;
  String? _selectedScenarioName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF183059),
      appBar: AppBar(
        title: const Text("Configure Simulation"),
        centerTitle: true,
        foregroundColor: const Color(0xFFFFFFFF),
        backgroundColor: const Color(0xFF276FBF),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFF183059),
            width: 5,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          const double wbreakpoint = 900;
          const double hbreakpoint = 800;
          final bool isNarrow = viewportConstraints.maxWidth < wbreakpoint ||
              viewportConstraints.maxHeight < hbreakpoint;

          final double runwayHeight = isNarrow
              ? 500
              : (viewportConstraints.maxHeight - 32).clamp(
                  500.0,
                  double.infinity,
                );

          final Widget simulationInputsCard = Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF276FBF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Simulation Inputs",
                  style: Theme.of(context).textTheme.headlineSmall
                ),
                _buildDropdown(
                  value: _selectedGenerationModel,
                  label: "Generation Model",
                  items: const ["Uniform", "Poisson"],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedGenerationModel = value;
                    });
                  },
                ),
                _buildNumberField(
                  controller: inboundFlowController,
                  label: "Inbound Flow Rate (aircraft/hour)",
                  min: 1,
                  max: 999,
                ),
                _buildNumberField(
                  controller: outboundFlowController,
                  label: "Outbound Flow Rate (aircraft/hour)",
                  min: 1,
                  max: 999,
                ),
                _buildNumberField(
                  controller: emergencyProbController,
                  label: "Emergency Probability (0-100%)",
                  min: 0,
                  max: 100,
                ),
                _buildNumberField(
                  controller: maxWaitController,
                  label: "Max Outbound Wait (minutes)",
                  min: 1,
                ),
                _buildNumberField(
                  controller: fuelThresholdController,
                  label: "Fuel Diversion Threshold (minutes)",
                  min: 1,
                ),
                _buildNumberField(
                  controller: durationController,
                  label: "Simulation Duration (hours)",
                  min: 1,
                ),
              ],
            ),
          );

          final Widget runwayCanvasCard = Container(
            height: runwayHeight,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF276FBF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Runway Configuration",
                  style: Theme.of(context).textTheme.headlineSmall
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RunwayCanvas(
                    runways: runways,
                    onAdd: _addRunway,
                    onRemove: _removeRunway,
                    onEdit: _editRunway,
                  ),
                ),
              ],
            ),
          );

          final Widget actionButtonsNarrow = Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCompactNavButton(
                icon: Icons.play_arrow,
                label: "Run Simulation",
                onPressed: _runSimulation,
              ),
              _buildCompactNavButton(
                icon: Icons.hourglass_top,
                label: "Real-Time Model",
                onPressed: _realtimeModel,
              ),
              _buildCompactNavButton(
                icon: Icons.folder_open,
                label: "Load Scenario",
                onPressed: _loadScenarioFromDatabase,
              ),
              _buildCompactNavButton(
                icon: Icons.home,
                label: "Main Menu",
                onPressed: () {
                  widget.onNavigate(AppTab.mainmenu);
                },
              ),
            ],
          );

          final Widget actionButtonsWide = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildLargeNavButton(
                    icon: Icons.play_arrow,
                    label: "Run Simulation",
                    onPressed: _runSimulation,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildLargeNavButton(
                    icon: Icons.hourglass_top,
                    label: "Real-Time Model",
                    onPressed: _realtimeModel,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildLargeNavButton(
                    icon: Icons.folder_open,
                    label: "Load Scenario",
                    onPressed: _loadScenarioFromDatabase,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildLargeNavButton(
                    icon: Icons.home,
                    label: "Main Menu",
                    onPressed: () {
                      widget.onNavigate(AppTab.mainmenu);
                    },
                  ),
                ),
              ],
            ),
          );

          if (isNarrow) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    simulationInputsCard,
                    const SizedBox(height: 16),
                    runwayCanvasCard,
                    const SizedBox(height: 16),
                    actionButtonsNarrow,
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SizedBox(
                height: viewportConstraints.maxHeight - 32,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: runwayCanvasCard,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          simulationInputsCard,
                          const SizedBox(height: 16),
                          actionButtonsWide,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF276FBF),
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildLargeNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        final iconSize = h * 0.32;
        final fontSize = h * 0.16;
        final spacing = h * 0.08;

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF276FBF),
            foregroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize),
              SizedBox(height: spacing),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    int? min,
    int? max,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0x88FFFFFF)),
        errorStyle: const TextStyle(color: Colors.orange),
        filled: true,
        fillColor: const Color(0xFF276FBF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFFFFFF),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFFFFFF),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.orange,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.orange,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field is required";
        }

        final number = int.tryParse(value);
        if (number == null) {
          return "Enter a valid number";
        }

        if (min != null && number < min) {
          return "Minimum value is $min";
        }

        if (max != null && number > max) {
          return "Maximum value is $max";
        }

        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((v) => DropdownMenuItem(
        value: v, 
        child: Text(
          v
        )
        )).toList(),
      onChanged: onChanged,
      dropdownColor: Color(0xFFA2C2E1),
      iconEnabledColor: Color(0xFFFFFFFF),
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0x80FFFFFF)),
        filled: true,
        fillColor: const Color(0xFF276FBF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFFFFFF),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFFFFFF),
            width: 2,
          ),
        ),
      ),
    );
  }

  void _editRunway(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFFFFFFFF),
                  width: 2,
                ),
              ),
              backgroundColor: const Color(0xFF183059),
              title: Text(
                "Configure Runway ${index + 1}",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              content: SizedBox(
                width: 1000,
                height: 800,
                child: RunwayCard(
                  runway: runways[index],
                  index: index,
                  onChanged: () {
                    setDialogState(() {});
                    runways[index].isInvalid = false;
                    setState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addRunway() {
    if (runways.length < 10) {
      setState(() {
        final nextId = (runways.length + 1).toString().padLeft(2, '0');
        runways.add(RunwayConfigUI(runwayId: nextId));
      });
    }
  }

  void _removeRunway(int index) {
    if (runways.length > 1) {
      setState(() {
        runways.removeAt(index);
      });
    }
  }

  /// Gets all saved scenarios from storage, then shows them in a dialog
  ///
  /// So the user can load, delete, or clear saved items.
  Future<void> _loadScenarioFromDatabase() async {
    Future<List<ScenarioRecord>> scenariosFuture =
        AppPersistence.instance.scenarioRepository.listScenarios();

    if (!mounted) return;

    final ScrollController scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void refreshScenarios() {
              setDialogState(() {
                scenariosFuture =
                    AppPersistence.instance.scenarioRepository.listScenarios();
              });
            }

            return Dialog(
              backgroundColor: const Color(0xFF183059),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFFFFFFFF),
                  width: 2,
                ),
              ),
              child: SizedBox(
                width: 800,
                height: 480,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Load Scenario",
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF276FBF),
                              foregroundColor: const Color(0xFFFFFFFF),
                            ),
                            onPressed: () async {
                              await _clearAll(onDone: refreshScenarios);
                            },
                            icon: const Icon(Icons.delete_sweep_outlined),
                            label: const Text("Clear all"),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF276FBF),
                              foregroundColor: const Color(0xFFFFFFFF),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: FutureBuilder<List<ScenarioRecord>>(
                        future: scenariosFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Failed to load scenarios: ${snapshot.error}",
                              ),
                            );
                          }

                          final scenarios = snapshot.data ?? const [];

                          if (scenarios.isEmpty) {
                            return const Center(
                              child: Text(
                                "No saved scenarios yet. Run a simulation first.",
                              ),
                            );
                          }

                          return Theme(
                            data: Theme.of(context).copyWith(
                              scrollbarTheme: const ScrollbarThemeData(
                                thumbColor: WidgetStatePropertyAll(
                                  Color(0xFFFFFFFF),
                                ),
                                trackColor: WidgetStatePropertyAll(
                                  Color(0x33FFFFFF),
                                ),
                                trackBorderColor: WidgetStatePropertyAll(
                                  Colors.transparent,
                                ),
                                radius: Radius.circular(8),
                                thickness: WidgetStatePropertyAll(10),
                                thumbVisibility: WidgetStatePropertyAll(true),
                                trackVisibility: WidgetStatePropertyAll(true),
                              ),
                            ),
                            child: Scrollbar(
                              controller: scrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.separated(
                                controller: scrollController,
                                itemCount: scenarios.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0x33FFFFFF),
                                ),
                                itemBuilder: (context, index) {
                                  final scenario = scenarios[index];
                                  return ListTile(
                                    title: Text(
                                      scenario.name,
                                      style: const TextStyle(
                                        color: Color(0xFFFFFFFF),
                                      ),
                                    ),
                                    subtitle: Text(
                                      decodeScenarioDescription(
                                        scenario.configJson,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFFFFFFFF),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatCreatedAt(
                                            scenario.createdAt.toLocal(),
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF276FBF),
                                            foregroundColor:
                                                const Color(0xFFFFFFFF),
                                          ),
                                          tooltip: "Delete Scenario",
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () async {
                                            await _deleteScenario(
                                              scenario,
                                              onDone: refreshScenarios,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      _applyScenarioMetadata(scenario);
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Reads saved scenario JSON from storage and fills the form fields.
  ///
  /// This lets users continue from old settings without typing again.
  void _applyScenarioMetadata(ScenarioRecord scenario) {
    final raw = scenario.configJson ?? scenario.description;
    if (raw == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text("Scenario has no saved configuration payload."),
          ) 
        ),
      );
      return;
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: const Text("Scenario payload format is invalid."),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedScenarioId = scenario.id;
      _selectedScenarioName = scenario.name;
      _selectedGenerationModel =
          decoded['generationModel']?.toString() ?? scenario.generationModel;
      emergencyProbController.text = _normaliseEmergencyProbabilityForUi(
        decoded['emergencyProbability'],
        emergencyProbController.text,
      );
      inboundFlowController.text = (decoded['inboundRate'] ?? inboundFlowController.text).toString();
      outboundFlowController.text = (decoded['outboundRate'] ?? outboundFlowController.text).toString();
      maxWaitController.text = (decoded['maxWaitTime'] ?? maxWaitController.text).toString();
      fuelThresholdController.text = (decoded['minFuelThreshold'] ?? fuelThresholdController.text).toString();
      durationController.text = (decoded['duration'] ?? durationController.text).toString();
      final runwayPayload = decoded['runways'];
      if (runwayPayload is List) {
        runways = runwayPayload.map((item) {
          final map =
              item is Map<String, dynamic> ? item : <String, dynamic>{};
          final eventsPayload = map['events'];
          final events = <RunwayEventUI>[];

          if (eventsPayload is List) {
            for (final event in eventsPayload) {
              final eventMap = event is Map<String, dynamic>
                  ? event
                  : <String, dynamic>{};
              final ui = RunwayEventUI(
                type: (eventMap['type'] ?? 'Inspection').toString(),
              );
              ui.startController.text = (eventMap['start'] ?? '').toString();
              ui.durationController.text =
                  (eventMap['duration'] ?? '').toString();
              events.add(ui);
            }
          }

          return RunwayConfigUI(
            mode: (map['mode'] ?? 'Landing').toString(),
            runwayId: (map['runwayId'] ?? '').toString(),
            events: events,
          );
        }).toList();

        if (runways.isEmpty) {
          runways = [RunwayConfigUI()];
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Text('Loaded scenario "${scenario.name}"'),
        ) 
      ),
    );
  }

  /// Removes one saved scenario from storage and refreshes UI state.
  Future<void> _deleteScenario(
    ScenarioRecord scenario, {
    VoidCallback? onDone,
  }) async {
    await AppPersistence.instance.scenarioRepository
        .deleteScenarioById(scenario.id);
    if (!mounted) return;

    onDone?.call();
  }

  /// Deletes every saved scenario from storage in one action.
  Future<void> _clearAll({
    VoidCallback? onDone,
  }) async {
    await AppPersistence.instance.scenarioRepository
        .deleteAllScenarios();
    if (!mounted) return;

    onDone?.call();
  }

  String decodeScenarioDescription(String? configJson) {
    if (configJson == null || configJson.isEmpty) {
      return "No scenario details saved";
    }

    try {
      final decoded = jsonDecode(configJson);
      if (decoded is Map<String, dynamic>) {
        final landingRunways = decoded["landingRunways"]?.toString() ?? "n/a";
        final takeoffRunways = decoded["takeoffRunways"]?.toString() ?? "n/a";
        final mixedRunways = decoded["mixedRunways"]?.toString() ?? "n/a";
        final duration = decoded["duration"]?.toString() ?? "n/a";
        final inboundFlow =
            decoded["inboundRate"]?.toString() ??
            decoded["inboundFlow"]?.toString() ??
            "n/a";
        final outboundFlow =
            decoded["outboundRate"]?.toString() ??
            decoded["outboundFlow"]?.toString() ??
            "n/a";
         final generationModel =
            decoded["generationModel"]?.toString() ??
            "Uniform";

        return "Model: $generationModel | Landing: $landingRunways | Takeoff: $takeoffRunways | Mixed: $mixedRunways | Duration (hr): $duration | In: $inboundFlow/hr | Out: $outboundFlow/hr";
      }
    } catch (_) {
      return configJson;
    }

    return configJson;
  }

  String _formatCreatedAt(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, "0");
    final month = dateTime.month.toString().padLeft(2, "0");
    final day = dateTime.day.toString().padLeft(2, "0");
    final hour = dateTime.hour.toString().padLeft(2, "0");
    final minute = dateTime.minute.toString().padLeft(2, "0");
    final second = dateTime.second.toString().padLeft(2, "0");
    return "$year-$month-$day $hour:$minute:$second";
  }

  Future<void> _runSimulation() async {
    if (!_validateConfiguration()) {
      return;
    }

    if (!_validateUniqueRunwayIds()) {
      return;
    }

    final simulationInputs = _buildSimulationInputs();

    try {
      final simulation = GenerativeBatchSimulation(simulationInputs,
        _selectedGenerationModel == 'Poisson' ?
        PoissonSimulationController(simulationInputs) :
        UniformSimulationController(simulationInputs)
      );
      final stats = simulation.run();
      final report = Report(stats: stats, inputs: simulationInputs);
      
      final scenarioId = _selectedScenarioId;

      if (scenarioId != null) {
        final orchestrator = RunPersistenceOrchestrator(
          runRepository: AppPersistence.instance.runRepository,
        );
        await orchestrator.persistRunLifecycle(
          scenarioId: scenarioId,
          metrics: stats,
        );
      }
      
      widget.onNavigate(
        AppTab.results,
        arguments: ResultsNavigationPayload(
          report: report,
          scenarioName: _selectedScenarioName,
          generationModel: _selectedGenerationModel,
        ),
      );

    } catch (error, stackTrace) {
      debugPrint("Scenario execution failed: $error");
      debugPrint("$stackTrace");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text("Failed to run scenario: $error"),
          ) 
        ),
      );
    }
  }


  void _realtimeModel() {
    if (!_validateConfiguration()) {
      return;
    }

    if (!_validateUniqueRunwayIds()) {
      return;
    }

    widget.onNavigate(
      AppTab.realtime,
      arguments: _buildRealTimeScreenArguments(),
    );
  }

  bool _validateConfiguration() {
    final mainValid = _formKey.currentState!.validate();
    var allRunwaysValid = true;

    for (final runway in runways) {
      final valid = runway.isValid();
      runway.isInvalid = !valid;
      if (!valid) {
        allRunwaysValid = false;
      }
    }

    setState(() {});
    return mainValid && allRunwaysValid;
  }

  bool _validateUniqueRunwayIds() {
    final seenIds = <String>{};
    final duplicatedIds = <String>{};

    for (final runway in runways) {
      final rawId = runway.runwayIdController.text.trim();
      if (rawId.isEmpty) {
        continue;
      }

      if (!seenIds.add(rawId)) {
        duplicatedIds.add(rawId);
      }
    }

    if (duplicatedIds.isNotEmpty) {
      final duplicateSummary = duplicatedIds.toList()..sort();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text('Runway IDs must be unique. Duplicate ID(s): ${duplicateSummary.join(", ")}'),
          ) 
        ),
      );
      return false;
    }

    return true;
  }

  RealTimeScreenArguments _buildRealTimeScreenArguments() {
    final runwaysForRealtime = <DashboardRunway>[];
    final initialEvents = <SimulationEvent>[];

    for (var index = 0; index < runways.length; index++) {
      final runway = runways[index];
      final rawId = runway.runwayIdController.text.trim();
      final id = int.tryParse(rawId.isEmpty ? "${index + 1}" : rawId) ?? (index + 1);
      final displayName =
          rawId.isEmpty ? "RUNWAY ${index + 1}" : "RUNWAY $rawId";

      runwaysForRealtime.add(
        DashboardRunway(
          id: id,
          name: displayName,
          operatingMode: _mapRunwayOperatingMode(runway.mode),
        ),
      );

      for (final event in runway.events) {
        final type = _mapRunwayEventType(event.type);

        final startMinutes = int.tryParse(event.startController.text) ?? 0;
        final durationMinutes =
            int.tryParse(event.durationController.text) ?? 0;

        if (durationMinutes <= 0) {
          continue;
        }

        final startTime = defaultClockStartTime.add(Duration(minutes: startMinutes));

        addEventWithOverlapCorrection(initialEvents,
          SimulationEvent(
            id:
                "$id-${initialEvents.length + 1}-${DateTime.now().microsecondsSinceEpoch}",
            runwayId: id,
            eventType: type,
            dtStartTime: startTime,
            duration: Duration(minutes: durationMinutes)
          ),
        );
      }
    }

    final inboundRate =
        int.tryParse(inboundFlowController.text.trim()) ?? 0;
    final outboundRate =
        int.tryParse(outboundFlowController.text.trim()) ?? 0;
    final emergencyProb =
        (int.tryParse(emergencyProbController.text.trim()) ?? 0)/100.0;
    final maxOutboundWait =
        int.tryParse(maxWaitController.text.trim()) ?? 30;
    final fuelDiversionThreshold =
        int.tryParse(fuelThresholdController.text.trim()) ?? 10;

    return RealTimeScreenArguments(
      runways: runwaysForRealtime,
      events: initialEvents,
      inboundRate: inboundRate,
      outboundRate: outboundRate,
      emergencyProbability: emergencyProb,
      maxWaitTime: maxOutboundWait,
      minFuelThreshold: fuelDiversionThreshold,
      distribution: _selectedGenerationModel
    );
  }

  RunwayMode _mapRunwayOperatingMode(String mode) {
    switch (mode) {
      case "Take Off":
        return RunwayMode.takeOff;
      case "Mixed":
        return RunwayMode.mixed;
      case "Landing":
      default:
        return RunwayMode.landing;
    }
  }

  RunwayStatus _mapRunwayEventType(String type) {
    // Values stored in the UI come from the RunwayStatus.name getter
    return RunwayStatus.fromString(type);
  }

  RateParameters _buildSimulationInputs() {
    return RateParameters(
      runways: runways.map((runway) => runway.toRunway()).toList(),
      emergencyProbability:
          double.parse(emergencyProbController.text) / 100.0,
      events: Queue.from(
        runways
            .map((runway) => runway.getEvents())
            .expand((events) => events)
            .toList()
          ..sort(
            (event1, event2) =>
                event1.getStartTime.compareTo(event2.getStartTime),
          ),
      ),
      maxWaitTime: int.parse(maxWaitController.text),
      minFuelThreshold: int.parse(fuelThresholdController.text),
      duration: Duration(
        hours: int.parse(durationController.text),
      ).inMinutes,
      outboundRate: int.parse(outboundFlowController.text),
      inboundRate: int.parse(inboundFlowController.text),
    );
  }

}