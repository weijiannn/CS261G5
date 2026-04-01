import 'dart:convert';
import 'dart:collection';
import 'package:air_traffic_sim/persistence/app_persistence.dart';
import 'package:air_traffic_sim/persistence/models/scenario_record.dart';
import 'package:air_traffic_sim/simulation/interfaces/i_report.dart';
import 'package:air_traffic_sim/simulation/implementations/report.dart';
import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:air_traffic_sim/simulation/implementations/simulation_inputs.dart';
import 'package:air_traffic_sim/simulation/orchestration/run_persistence_orchestrator.dart';
import 'package:air_traffic_sim/ui/app_shell.dart';
import 'package:air_traffic_sim/ui/widgets/scenario_picker_overlay.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:flutter/material.dart';
import 'package:air_traffic_sim/ui/widgets/section_average_graph.dart'; 
import 'package:flutter/services.dart';


class ResultsScreen extends StatefulWidget {
  final IReport? Function() getReport;
  final String? Function()? getLatestScenarioName;
  final String? Function()? getLatestGenerationModel;
  final void Function(int index, {Object? arguments}) onNavigate;

  const ResultsScreen({
    super.key,
    required this.getReport,
    this.getLatestScenarioName,
    this.getLatestGenerationModel,
    required this.onNavigate,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ScrollController _outputsScrollController = ScrollController();
  final TextEditingController _saveScenarioNameController = TextEditingController();
  String _selectedGenerationModel = "Uniform";
  double? _inputsCardHeight;

  @override
  void initState() {
    super.initState();

    final latestGenerationModel = widget.getLatestGenerationModel?.call()?.trim();
    if (latestGenerationModel != null && latestGenerationModel.isNotEmpty) {
      _selectedGenerationModel = latestGenerationModel;
    }
  }

  String _resolveSelectedGenerationModel() {
    final latestGenerationModel = widget.getLatestGenerationModel?.call()?.trim();
    if (latestGenerationModel != null && latestGenerationModel.isNotEmpty) {
      _selectedGenerationModel = latestGenerationModel;
    }

    return _selectedGenerationModel;
  }

  String _formatRunwayUtilisationPercentage(double ratio) {
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }
  

  @override
  void dispose() {
    _outputsScrollController.dispose();
    _saveScenarioNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.getReport();

    return Scaffold(
      backgroundColor: Color(0xFF183059),
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF276FBF),
        title: const Text("Results"),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFF183059),
            width: 5,
          ),
        ),
      ),
      body: results == null
          ? const Center(
              child: Text("No simulation results available."),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Simulation Summary",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Color(0xFFFFFFFF)
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;

                      int columns;
                      if (constraints.maxWidth >= 1400) {
                        columns = 6;
                      } else if (constraints.maxWidth >= 1000) {
                        columns = 3;
                      } else if (constraints.maxWidth >= 650) {
                        columns = 2;
                      } else {
                        columns = 1;
                      }

                      final cardWidth =
                          (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              context,
                              "Runway Utilisation",
                              _formatRunwayUtilisationPercentage(
                                results.getStats.runwayUtilisation,
                              ),
                              Icons.speed,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              context,
                              "Cancellations",
                              results.getStats.totalCancellations.toString(),
                              Icons.cancel,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              context,
                              "Diversions",
                              results.getStats.totalDiversions.toString(),
                              Icons.call_missed_outgoing,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              context,
                              "Total Aircraft",
                              results.getStats.totalAircraft.toString(),
                              Icons.flight,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              context,
                              "Landing Aircraft",
                              results.getStats.totalLandingAircraft.toString(),
                              Icons.flight_land,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _summaryCard(
                              context,
                              "Departing Aircraft",
                              results.getStats.totalDepartingAircraft.toString(),
                              Icons.flight_takeoff,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _inputsSection(context, results),
                            _outputsSection(context, results),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _inputsSection(
                              context,
                              results,
                              measureCard: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: _outputsSection(
                              context,
                              results,
                              matchedCardHeight: _inputsCardHeight,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Graphs",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Color(0xFFFFFFFF)
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionAverageGraph(
                    title: "Average Landing Delay Over Time",
                    multiSectionAverages: [results.getStats.sectionAverageLandingDelayList],
                  ),
                  const SizedBox(height: 12),
                  SectionAverageGraph(
                    title: "Average Departure Delay Over Time",
                    multiSectionAverages: [results.getStats.sectionAverageDepartureDelayList],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  if (results != null) {
                    final csv = results.exportCSV();
                    _showExportPreview(
                      context,
                      title: "Export CSV",
                      content: csv,
                    );
                  }
                },
                icon: const Icon(Icons.table_view),
                label: const Text("Export to CSV"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  if (results != null) {
                    _showSaveScenarioDialog(context, results);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text("Save Scenario"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () async {
                  final scenario = await showScenarioPickerOverlay(context);

                  if (!context.mounted || scenario == null) return;

                  final loadedInputs = _buildInputsFromScenario(scenario);
                  if (loadedInputs == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                          child: Text('Unable to load scenario configuration: ${scenario.name}'),
                        ) 
                      ),
                    );
                    return;
                  }

                  final runs = await AppPersistence.instance.runRepository
                      .listRunsByScenario(scenario.id);
                  if (!context.mounted) {
                    return;
                  }

                  if (runs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No run history for this scenario yet'),
                      ),
                    );
                    return;
                  }

                  final latestRun = runs.first;
                  final rebuiltReport = Report(
                    stats: latestRun.stats,
                    inputs: loadedInputs,
                  );

                  setState(() {
                    _selectedGenerationModel = scenario.generationModel;
                  });

                  widget.onNavigate(
                    AppTab.results,
                    arguments: ResultsNavigationPayload(
                      report: rebuiltReport,
                      scenarioName: scenario.name,
                      generationModel: scenario.generationModel,
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        child: Text('Loaded scenario: ${scenario.name}'),
                      ) 
                    ),
                  );
                },
                icon: const Icon(Icons.folder_open),
                label: const Text("Load Scenario"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  widget.onNavigate(AppTab.configuration);
                },
                icon: const Icon(Icons.settings),
                label: const Text("Configure Simulation"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  widget.onNavigate(AppTab.compare);
                },
                icon: const Icon(Icons.compare_arrows),
                label: const Text("Compare Simulations"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF276FBF),
                    foregroundColor: Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                onPressed: () {
                  widget.onNavigate(AppTab.mainmenu);
                },
                icon: const Icon(Icons.home),
                label: const Text("Main Menu"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a dialog to save the current inputs/results as a scenario record
  ///
  /// in local storage so it can be loaded later.
  Future<void> _showSaveScenarioDialog(BuildContext context, IReport results) async {
    final suggestedScenarioName = widget.getLatestScenarioName?.call()?.trim();
    final scenarioNameToPrefill =
        (suggestedScenarioName != null && suggestedScenarioName.isNotEmpty)
            ? suggestedScenarioName
            : _buildDefaultScenarioName(DateTime.now().toLocal());
    _saveScenarioNameController.text = scenarioNameToPrefill;
    String? validationError;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogStateContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF183059),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFFFFFFF),
              width: 2,
            ),
          ),
          title: const Text(
            'Save Scenario',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
          ),
          content: SizedBox(
            width: 640,
            child: TextField(
              style: TextStyle(color: Color(0xFFFFFFFF)),
              controller: _saveScenarioNameController,
              autofocus: false,
              decoration: InputDecoration(
                labelText: "Scenario Name",
                labelStyle: const TextStyle(color: Color(0xFFFFFFFF)),
                errorStyle: const TextStyle(color: Colors.orange),
                errorText: validationError,
                filled: true,
                fillColor: const Color(0xFF183059),
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
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF276FBF),
                foregroundColor: const Color(0xFFFFFFFF),
              ),
              onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF276FBF),
                foregroundColor: const Color(0xFFFFFFFF),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final scenarioName = _saveScenarioNameController.text.trim();

                      if (scenarioName.isEmpty) {
                        setDialogState(() {
                          validationError = 'Scenario name is required';
                        });
                        return;
                      }

                      final existingScenarios = await AppPersistence
                          .instance
                          .scenarioRepository
                          .listScenarios();
                      final duplicateNameExists = existingScenarios.any(
                        (scenario) =>
                            scenario.name.trim().toLowerCase() ==
                            scenarioName.toLowerCase(),
                      );

                      if (duplicateNameExists) {
                        setDialogState(() {
                          validationError =
                              'A scenario with this name already exists';
                        });
                        return;
                      }


                      final timestamp = DateTime.now();
                      final scenarioId = _buildScenarioId(scenarioName, timestamp);
                      final generationModel = _resolveSelectedGenerationModel();
                      final record = ScenarioRecord(
                        id: scenarioId,
                        name: scenarioName,
                        generationModel: generationModel,
                        configJson: jsonEncode(
                          _buildScenarioConfigJson(
                            results,
                            generationModel: generationModel,
                          ),
                        ),
                        createdAt: timestamp.toUtc(),
                      );

                      setDialogState(() {
                        isSaving = true;
                        validationError = null;
                      });

                      try {
                        await AppPersistence.instance.scenarioRepository.upsertScenario(record);
                        await RunPersistenceOrchestrator(
                          runRepository: AppPersistence.instance.runRepository,
                        ).persistRunLifecycle(
                          scenarioId: record.id,
                          metrics: results.getStats,
                        );
                        if (!mounted) {
                          return;
                        }
                         setState(() {});
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                              child: Text('Scenario "${record.name}" saved successfully.'),
                            ) 
                          ),
                        );
                      } catch (error) {
                        if (!mounted) {
                          return;
                        }
                        setDialogState(() {
                          isSaving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                              child: Text('Failed to save scenario: $error'),
                            ) 
                          ),
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a stable id for DB storage by combining time + a safe name.
  String _buildScenarioId(String scenarioName, DateTime timestamp) {
    final slug = scenarioName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '${timestamp.millisecondsSinceEpoch}-${slug.isEmpty ? 'scenario' : slug}';
  }

  String _buildDefaultScenarioName(DateTime timestamp) {
    final year = timestamp.year.toString().padLeft(4, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return 'Scenario $year-$month-$day $hour:$minute:$second';
  }

  Widget _outputsSection(
    BuildContext context,
    IReport results, {
    double? matchedCardHeight,
  }) {
    final card = Card(
      color: Color(0xFF276FBF),
      child: ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(true),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(8),
        thumbColor: WidgetStatePropertyAll(Color(0xFFA2C2E1)), 
        trackColor: WidgetStatePropertyAll(Color(0x33000000)), 
      ),
      child: Scrollbar(
        controller: _outputsScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _outputsScrollController,
          padding: const EdgeInsets.all(12),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _tableRow(
                "Average Landing Delay",
                results.getStats.averageLandingDelay.toStringAsFixed(2),
              ),
              _tableRow(
                "Average Hold Time",
                results.getStats.averageHoldTime.toStringAsFixed(2),
              ),
              _tableRow(
                "Average Departure Delay",
                results.getStats.averageDepartureDelay.toStringAsFixed(2),
              ),
              _tableRow(
                "Average Wait Time",
                results.getStats.averageWaitTime.toStringAsFixed(2),
              ),
              _tableRow(
                "Maximum Landing Delay",
                results.getStats.maxLandingDelay.toString(),
              ),
              _tableRow(
                "Maximum Departure Delay",
                results.getStats.maxDepartureDelay.toString(),
              ),
              _tableRow(
                "Maximum Inbound Queue Size",
                results.getStats.maxInboundQueue.toString(),
              ),
              _tableRow(
                "Maximum Outbound Queue Size",
                results.getStats.maxOutboundQueue.toString(),
              ),
              _tableRow(
                "Total Aircraft",
                results.getStats.totalAircraft.toString(),
              ),
              _tableRow(
                "Total Cancellations",
                results.getStats.totalCancellations.toString(),
              ),
              _tableRow(
                "Total Diversions",
                results.getStats.totalDiversions.toString(),
              ),
              _tableRow(
                "Total Landing Aircraft",
                results.getStats.totalLandingAircraft.toString(),
              ),
              _tableRow(
                "Total Departing Aircraft",
                results.getStats.totalDepartingAircraft.toString(),
              ),
              _tableRow(
                "Runway Utilisation Percentage",
                _formatRunwayUtilisationPercentage(
                  results.getStats.runwayUtilisation,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Simulation Outputs",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Color(0xFFFFFFFF)
                    ),
        ),
        const SizedBox(height: 12),
        if (matchedCardHeight != null)
          SizedBox(
            height: matchedCardHeight,
            child: card,
          )
        else
          card,
      ],
    );
  }

  Widget _inputsSection(
    BuildContext context,
    IReport results, {
    bool measureCard = false,
  }) {
    final card = measureCard
        ? MeasureSize(
            onChange: (size) {
              if (_inputsCardHeight != size.height) {
                setState(() {
                  _inputsCardHeight = size.height;
                });
              }
            },
            child: _inputConfigCard(results),
          )
        : _inputConfigCard(results);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Simulation Inputs",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Color(0xFFFFFFFF)
                    ),
        ),
        const SizedBox(height: 12),
        card,
      ],
    );
  }


  Widget _summaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      color: const Color(0xFF276FBF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: const Color(0xFFFFFFFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFFFFFFF),
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFFFFFFFF),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: TextStyle(color: Color(0xFFFFFFFF))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(value, style: TextStyle(color: Color(0xFFFFFFFF))),
        ),
      ],
    );
  }

  Widget _inputConfigCard(IReport? results) {
    return Card(
      color: Color(0xFF276FBF),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: results == null 
            ? const Align(
                alignment: Alignment.centerLeft,
                child: Text("No input configuration available."),
              )
            : Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  _tableRow(
                    "Inbound Flow Rate (aircraft/hour)", 
                    results.getInputs.getInboundRate.toString()
                  ),
                  _tableRow(
                    "Outbound Flow Rate (aircraft/hour)", 
                    results.getInputs.getOutboundRate.toString()
                  ),
                  _tableRow(
                    "Aircraft Emergency Probability", 
                    "${(results.getInputs.getEmergencyProbability * 100).toString()}%"
                  ),
                  _tableRow(
                    "Maximum Outbound Wait Time (minutes)", 
                    results.getInputs.getMaxWaitTime.toString()
                  ),
                  _tableRow(
                    "Fuel Diversion Threshold (minutes)", 
                    results.getInputs.getMinFuelThreshold.toString()
                  ),
                  _tableRow(
                    "Simulation Duration (hours)", 
                    "${Duration(minutes: results.getInputs.getDuration).inHours.toString()}:${Duration(minutes: results.getInputs.getDuration % 60).inMinutes.toString().padLeft(2, '0')}"
                  ),
                  _tableRow(
                    "Takeoff Runways", 
                    results.getInputs.getRunways.whereType<TakeOffRunway>().length.toString()
                  ),
                  _tableRow(
                    "Landing Runways", 
                    results.getInputs.getRunways.whereType<LandingRunway>().length.toString()
                  ),
                  _tableRow(
                    "Mixed Runways", 
                    results.getInputs.getRunways.whereType<MixedRunway>().length.toString()
                  ),
                ]
              ),
      ),
    );
  }

  /// Reads JSON text from a saved scenario and returns a config map.
  ///
  /// If parsing fails, we return null so callers can handle it safely.
  Map<String, dynamic>? _scenarioConfigFromRecord(ScenarioRecord scenario) {
    final raw = scenario.configJson;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _extractScenarioConfig(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Converts saved config data from storage back into SimulationInputs.
  ///
  /// This is used when loading old scenarios into the results view.
  SimulationInputs? _buildInputsFromScenario(ScenarioRecord scenario) {
    final config = _scenarioConfigFromRecord(scenario);
    if (config == null) {
      return null;
    }

    final inboundRate = _readInt(config, ['inboundRate', 'inboundFlow']);
    final outboundRate = _readInt(config, ['outboundRate', 'outboundFlow']);
    final emergencyProbability = _readDouble(config, ['emergencyProbability']);
    final maxWaitTime = _readInt(config, ['maxWaitTime']);
    final minFuelThreshold = _readInt(config, ['minFuelThreshold']);
    final duration = _readDurationMinutes(config);

    if (inboundRate == null ||
        outboundRate == null ||
        emergencyProbability == null ||
        maxWaitTime == null ||
        minFuelThreshold == null ||
        duration == null) {
      return null;
    }

    final runways = _readRunways(config);
    if (runways.isEmpty) {
      return null;
    }

    return SimulationInputs(
      runways: runways,
      emergencyProbability:
          emergencyProbability > 1 ? emergencyProbability / 100 : emergencyProbability,
      events: Queue.from(const []),
      maxWaitTime: maxWaitTime,
      minFuelThreshold: minFuelThreshold,
      duration: duration,
      outboundRate: outboundRate,
      inboundRate: inboundRate,
    );
  }

  /// Helper for DB/json reads: try many key names and parse as int.
  int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      return int.tryParse(value.toString());
    }
    return null;
  }

  /// Helper for DB/json reads: try many key names and parse as double
  double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value.toString());
    }
    return null;
  }

  int? _readDurationMinutes(Map<String, dynamic> map) {
    final durationMinutes = _readInt(map, ['durationMinutes']);
    if (durationMinutes != null) {
      return durationMinutes;
    }

    final durationHours = _readInt(map, ['duration']);
    if (durationHours != null) {
      return durationHours * 60;
    }

    return null;
  }

  /// Rebuilds runway objects from saved config.
  ///
  /// Falls back to runway counts if full runway list is missing
  List<AbstractRunway> _readRunways(Map<String, dynamic> config) {
    final runwaysJson = config['runways'];
    final parsedRunways = <AbstractRunway>[];

    if (runwaysJson is List) {
      var nextId = 1;
      for (final runwayJson in runwaysJson) {
        if (runwayJson is! Map<String, dynamic>) {
          continue;
        }

        final runwayId = int.tryParse(
              runwayJson['runwayId']?.toString() ?? runwayJson['id']?.toString() ?? '',
            ) ??
            nextId;
        nextId = runwayId + 1;

        final mode = runwayJson['mode']?.toString();
        switch (mode) {
          case 'landing':
            parsedRunways.add(LandingRunway(id: runwayId));
            break;
          case 'takeOff':
            parsedRunways.add(TakeOffRunway(id: runwayId));
            break;
          case 'mixed':
            parsedRunways.add(MixedRunway(id: runwayId));
            break;
        }
      }

      if (parsedRunways.isNotEmpty) {
        return parsedRunways;
      }
    }

    final landingRunways = _readInt(config, ['landingRunways']) ?? 0;
    final takeoffRunways = _readInt(config, ['takeoffRunways']) ?? 0;
    final mixedRunways = _readInt(config, ['mixedRunways']) ?? 0;

    var runwayId = 1;
    for (var i = 0; i < landingRunways; i++) {
      parsedRunways.add(LandingRunway(id: runwayId++));
    }
    for (var i = 0; i < takeoffRunways; i++) {
      parsedRunways.add(TakeOffRunway(id: runwayId++));
    }
    for (var i = 0; i < mixedRunways; i++) {
      parsedRunways.add(MixedRunway(id: runwayId++));
    }

    return parsedRunways;
  }


  /*String _readNumValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      return value.toString();
    }
    return "-";
  }

  String _readEmergencyProbability(Map<String, dynamic> map) {
    final raw = map["emergencyProbability"];
    if (raw is num) {
      final value = raw <= 1 ? raw * 100 : raw;
      return "${value.toString()}%";
    }
    if (raw != null) {
      return "${raw.toString()}%";
    }
    return "-";
  }

  String _readDuration(Map<String, dynamic> map) {
    final minutesRaw = map["durationMinutes"];
    if (minutesRaw is num) {
      final totalMinutes = minutesRaw.round();
      final hours = totalMinutes ~/ 60;
      final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
      return "$hours:$minutes";
    }

    final hoursRaw = map["duration"];
    if (hoursRaw != null) {
      return "$hoursRaw:00";
    }

    return "-";
  }*/

  /// Builds the JSON payload we store for a scenario.
  ///
  /// Includes both inputs and summary output values.
  Map<String, dynamic> _buildScenarioConfigJson(
    IReport results, {
    required String generationModel,
  }) {
    final runways = results.getInputs.getRunways;
    final landingRunways = runways.whereType<LandingRunway>().length;
    final takeoffRunways = runways.whereType<TakeOffRunway>().length;
    final mixedRunways = runways.whereType<MixedRunway>().length;
    final events = results.getInputs.getEvents.toList(growable: false);


    return {
      "generationModel": _selectedGenerationModel,
      "runwayCount": landingRunways + takeoffRunways + mixedRunways,
      "inboundRate": results.getInputs.getInboundRate,
      "outboundRate": results.getInputs.getOutboundRate,
      "emergencyProbability": results.getInputs.getEmergencyProbability,
      "maxWaitTime": results.getInputs.getMaxWaitTime,
      "minFuelThreshold": results.getInputs.getMinFuelThreshold,
      "duration": (results.getInputs.getDuration / 60).round(),
      "durationMinutes": results.getInputs.getDuration,
      "landingRunways": landingRunways,
      "takeoffRunways": takeoffRunways,
      "mixedRunways": mixedRunways,
      "runways": runways
          .map((runway) => {
                "mode": runway is MixedRunway
                    ? RunwayMode.mixed.name
                    : runway.mode().name,
                "runwayId": runway.id.toString().padLeft(2, '0'),
                "events": events
                    .where((event) => event.getRunwayId == runway.id)
                    .map((event) => {
                          "type": event.getEventType.name,
                          "start": event.getStartTime,
                          "duration": event.getDuration,
                        })
                    .toList(growable: false),
              })
          .toList(growable: false),

      "results": {
        "averageLandingDelay": results.getStats.averageLandingDelay,
        "averageHoldTime": results.getStats.averageHoldTime,
        "averageDepartureDelay": results.getStats.averageDepartureDelay,
        "averageWaitTime": results.getStats.averageWaitTime,
        "maxLandingDelay": results.getStats.maxLandingDelay,
        "maxDepartureDelay": results.getStats.maxDepartureDelay,
        "maxInboundQueue": results.getStats.maxInboundQueue,
        "maxOutboundQueue": results.getStats.maxOutboundQueue,
        "totalCancellations": results.getStats.totalCancellations,
        "totalDiversions": results.getStats.totalDiversions,
        "totalLandingAircraft": results.getStats.totalLandingAircraft,
        "totalDepartingAircraft": results.getStats.totalDepartingAircraft,
        "runwayUtilisation": results.getStats.runwayUtilisation,
        "sectionAverageLandingDelayList": results.getStats.sectionAverageLandingDelayList,
        "sectionAverageDepartureDelayList": results.getStats.sectionAverageDepartureDelayList,
      },

    };
  }

  /// Accepts different saved JSON shapes and normalizes them into one config map that the app can read.
  Map<String, dynamic> _extractScenarioConfig(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Could not find scenario configuration object in JSON.');
    }

    final scenario = payload['scenario'];
    final metrics = payload['results'] ?? payload['metricsSummary'] ?? payload['metrics'];
    if (scenario is Map<String, dynamic>) {
      if (metrics is Map<String, dynamic>) {
        return {
          ...scenario,
          'results': metrics,
        };
      }

      return scenario;
    }

    final config = payload['config'];
    if (config is Map<String, dynamic>) {
      if (metrics is Map<String, dynamic>) {
        return {
          ...config,
          'results': metrics,
        };
      }

      return config;
    }

    if (metrics is Map<String, dynamic>) {
      return {
        ...payload,
        'results': metrics,
      };
    }

    return payload;
  }

  Future<void> _copyToClipboard(BuildContext context, String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Text('Copied to clipboard.'),
        ) 
      ),
    );
  }

  void _showExportPreview(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final ScrollController scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFFFFFFF),
            width: 2,
          ),
        ),
        backgroundColor: const Color(0xFF183059),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        content: SizedBox(
          width: 640,
          height: 480,
          child: Theme(
            data: Theme.of(context).copyWith(
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
                trackColor: WidgetStatePropertyAll(Color(0x33FFFFFF)),
                trackBorderColor: WidgetStatePropertyAll(Colors.transparent),
                radius: const Radius.circular(8),
                thickness: WidgetStatePropertyAll(10),
                thumbVisibility: WidgetStatePropertyAll(true),
                trackVisibility: WidgetStatePropertyAll(true),
              ),
            ),
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
        ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF276FBF),
                              foregroundColor: const Color(0xFFFFFFFF),
                            ),
            onPressed: () async {
              await _copyToClipboard(context, content);
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF276FBF),
                              foregroundColor: const Color(0xFFFFFFFF),
                            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

}

class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({
    super.key,
    required this.child,
    required this.onChange,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newSize = context.size;
      if (newSize != null && _oldSize != newSize) {
        _oldSize = newSize;
        widget.onChange(newSize);
      }
    });

    return widget.child;
  }
}
