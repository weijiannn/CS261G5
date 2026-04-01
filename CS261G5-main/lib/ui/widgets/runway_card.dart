import 'package:flutter/services.dart';
import 'package:air_traffic_sim/simulation/enums/runway_mode.dart';
import 'package:flutter/material.dart';
import '../models/runway_config_ui.dart';
import 'runway_event_row.dart';

class RunwayCard extends StatefulWidget {
  final RunwayConfigUI runway;
  final int index;
  final VoidCallback onChanged;

  const RunwayCard({
    super.key,
    required this.runway,
    required this.index,
    required this.onChanged,
  });

  @override
  State<RunwayCard> createState() => _RunwayCardState();
}

class _RunwayCardState extends State<RunwayCard> {
  final _runwayKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF276FBF),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          child: Form(
            key: _runwayKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Runway ${widget.index + 1}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
                ),
                const SizedBox(height: 10),

                _buildNumberField(
                  controller: widget.runway.runwayIdController,
                  label: "Runway ID",
                  validator: (v) {
                    if (v == null || v.isEmpty) return "This field is required";
                    if (!RegExp(r'^\d{2}$').hasMatch(v)) return "ID must be exactly 2 digits";
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                _buildDropdown(
                  value: widget.runway.mode,
                  label: "Operating Mode",
                  items: RunwayMode.allNames,
                  onChanged: (value) {
                    widget.runway.mode = value!;
                    widget.onChanged();
                  },
                ),

                const SizedBox(height: 10),

                const Text("Events", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))),
                const SizedBox(height: 10),

                Expanded(
                  child: widget.runway.events.isEmpty
                      ? const Center(child: Text("No events added"))
                      : ListView.builder(
                          itemCount: widget.runway.events.length,
                          itemBuilder: (context, i) {
                            final event = widget.runway.events[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: RunwayEventRow(
                                event: event,
                                onChanged: widget.onChanged,
                                onDelete: () {
                                  setState(() {
                                    widget.runway.events.removeAt(i);
                                    widget.onChanged();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF183059),
                    foregroundColor: Color(0xFFFFFFFF),
                  ),
                  onPressed: () {
                    setState(() {
                      widget.runway.events.add(RunwayEventUI());
                      widget.onChanged();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Event"),
                ),
                const SizedBox(height: 10),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF183059),
                    foregroundColor: Color(0xFFFFFFFF),
                  ),
                    onPressed: () {
                      if (_runwayKey.currentState!.validate()) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Confirm Runway"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // only 0-9
        LengthLimitingTextInputFormatter(2),    // max 2 digits
      ],
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0x80FFFFFF)),
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
      validator: validator,
      onChanged: (_) => widget.onChanged(),
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

  @override
  void initState() {
    super.initState();

    if (widget.runway.runwayIdController.text.isEmpty) {
      widget.runway.runwayIdController.text =
          (widget.index + 1).toString().padLeft(2, '0');
    }
  }
}