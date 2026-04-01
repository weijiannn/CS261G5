import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:flutter/material.dart';
import 'package:air_traffic_sim/simulation/enums/runway_status.dart';
import '../models/runway_config_ui.dart';

class RunwayEventRow extends StatelessWidget {
  final RunwayEventUI event;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const RunwayEventRow({
    super.key,
    required this.event,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFA2C2E1),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: event.type,
                  items: [
                    DropdownMenuItem(
                      value: RunwayStatus.inspection.name,
                      child: Text(RunwayStatus.inspection.name),
                    ),
                    DropdownMenuItem(
                      value: RunwayStatus.snowClearance.name,
                      child: Text(RunwayStatus.snowClearance.name),
                    ),
                    DropdownMenuItem(
                      value: RunwayStatus.maintenance.name,
                      child: Text(RunwayStatus.maintenance.name),
                    ),
                    DropdownMenuItem(
                      value: RunwayStatus.closure.name,
                      child: Text(RunwayStatus.closure.name),
                    ),
                  ],
                  validator: (v) =>
                      v == null || v.isEmpty ? "Select type" : null,
                  onChanged: (v) {
                    event.type = v!;
                    onChanged();
                  },
                  dropdownColor: Color(0xFFA2C2E1),
                  iconEnabledColor: Color(0xFF000000),
                  style: const TextStyle(
                    color: Color(0xFF000000),
                  ),
                  decoration: InputDecoration(
                    labelText: "Event",
                    labelStyle: const TextStyle(color: Color(0xFF000000)),
                    filled: true,
                    fillColor: const Color(0xFFA2C2E1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF000000),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF000000),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextFormField(
                  controller: event.startController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "This field is required";
                    final n = int.tryParse(v);
                    if (n == null || n < 0) return "Value must be greater than 0";
                    return null;
                  },
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: "Time from start (min)",
                    labelStyle: const TextStyle(color: Color(0xFF000000)),
                    errorStyle: const TextStyle(color: Colors.red),
                    filled: true,
                    fillColor: const Color(0xFFA2C2E1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF000000),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF000000),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextFormField(
                  controller: event.durationController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "This field is required";
                    final n = int.tryParse(v);
                    if (n == null || n <= AbstractRunway.occupationTime + AbstractRunway.wakeSeparationTime) return "Value must be at least ${AbstractRunway.occupationTime + AbstractRunway.wakeSeparationTime + 1}";
                    return null;
                  },
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: "Duration (min)",
                    labelStyle: const TextStyle(color: Color(0xFF000000)),
                    errorStyle: const TextStyle(color: Colors.red),
                    filled: true,
                    fillColor: const Color(0xFFA2C2E1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF000000),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF000000),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
