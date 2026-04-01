import "dart:convert";

import "package:air_traffic_sim/persistence/app_persistence.dart";
import "package:air_traffic_sim/persistence/models/scenario_record.dart";
import "package:flutter/material.dart";

String formatScenarioCreatedAt(DateTime createdAt) {
  final local = createdAt.toLocal();
  final year = local.year.toString().padLeft(4, "0");
  final month = local.month.toString().padLeft(2, "0");
  final day = local.day.toString().padLeft(2, "0");
  final hour = local.hour.toString().padLeft(2, "0");
  final minute = local.minute.toString().padLeft(2, "0");
  return "$year-$month-$day $hour:$minute";
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
      final generationModel = decoded["generationModel"]?.toString() ?? "Uniform";
      return "Model: $generationModel | Landing: $landingRunways | Takeoff: $takeoffRunways | Mixed: $mixedRunways | Duration (hr): $duration | In: $inboundFlow/hr | Out: $outboundFlow/hr";
    }
  } catch (_) {
    return configJson;
  }

  return configJson;
}

Future<ScenarioRecord?> showScenarioPickerOverlay(BuildContext context) {
  return showDialog<ScenarioRecord>(
    context: context,
    builder: (_) => const ScenarioPickerOverlay(),
  );
}

class ScenarioPickerOverlay extends StatefulWidget {
  const ScenarioPickerOverlay({super.key});

  @override
  State<ScenarioPickerOverlay> createState() => _ScenarioPickerOverlayState();
}

class _ScenarioPickerOverlayState extends State<ScenarioPickerOverlay> {
  Future<List<ScenarioRecord>>? _future;

  @override
  void initState() {
    super.initState();
    _future = AppPersistence.instance.scenarioRepository.listScenarios();
  }

  void _reload() {
    setState(() {
      _future = AppPersistence.instance.scenarioRepository.listScenarios();
    });
  }

  Future<void> _deleteScenario(ScenarioRecord scenario) async {
    await AppPersistence.instance.scenarioRepository.deleteScenarioById(scenario.id);
    if (!mounted) return;
    _reload();
  }

  Future<void> _clearAll() async {
    await AppPersistence.instance.scenarioRepository.deleteAllScenarios();
    if (!mounted) return;
    _reload();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color (0xFF183059),
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
                    onPressed: _clearAll,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text("Clear all"),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF276FBF),
                      foregroundColor: const Color(0xFFFFFFFF),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<ScenarioRecord>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Failed to load scenarios: ${snapshot.error}"),
                    );
                  }

                  final scenarios = snapshot.data ?? const [];
                  if (scenarios.isEmpty) {
                    return const Center(
                      child: Text("No saved scenarios yet. Run a simulation first."),
                    );
                  }

                  return Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: const ScrollbarThemeData(
                        thumbColor: WidgetStatePropertyAll(Color(0xFFFFFFFF)),
                        trackColor: WidgetStatePropertyAll(Color(0x33FFFFFF)),
                        trackBorderColor: WidgetStatePropertyAll(Colors.transparent),
                        radius: Radius.circular(8),
                        thickness: WidgetStatePropertyAll(10),
                        thumbVisibility: WidgetStatePropertyAll(true),
                        trackVisibility: WidgetStatePropertyAll(true),
                      ),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: scenarios.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final scenario = scenarios[index];
                          return ListTile(
                            title: Text(
                              scenario.name,
                              style: const TextStyle(color: Color(0xFFFFFFFF)),
                            ),
                            subtitle: Text(
                              decodeScenarioDescription(scenario.configJson),
                              style: const TextStyle(color: Color(0xFFFFFFFF)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatCreatedAt(scenario.createdAt.toLocal()),
                                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                                  textAlign: TextAlign.end,
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF276FBF),
                                    foregroundColor: const Color(0xFFFFFFFF),
                                  ),
                                  tooltip: "Delete Scenario",
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteScenario(scenario),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pop(context, scenario),
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
}
