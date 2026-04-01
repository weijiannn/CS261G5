import 'package:air_traffic_sim/simulation/implementations/runway.dart';
import 'package:flutter/material.dart';

import 'package:air_traffic_sim/simulation/enums/runway_status.dart';

class RunwayEventDialogResult {
  final RunwayStatus type;
  final Duration duration;
  final Duration offsetFromNow;

  const RunwayEventDialogResult({
    required this.type,
    required this.duration,
    required this.offsetFromNow,
  });
}

Future<RunwayEventDialogResult?> showRunwayEventDialog(
  BuildContext context, {
  String? runwayName,
}) {
  return showDialog<RunwayEventDialogResult>(
    context: context,
    builder: (_) => RunwayEventDialog(runwayName: runwayName),
  );
}

class RunwayEventDialog extends StatefulWidget {
  final String? runwayName;

  const RunwayEventDialog({super.key, this.runwayName});

  @override
  State<RunwayEventDialog> createState() => _RunwayEventDialogState();
}

class _RunwayEventDialogState extends State<RunwayEventDialog> {
  final _formKey = GlobalKey<FormState>();
  RunwayStatus _selectedType = RunwayStatus.maintenance;
  final TextEditingController _durationController =
      TextEditingController(text: '30');
  final TextEditingController _offsetController =
      TextEditingController(text: '0');

  @override
  void dispose() {
    _durationController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFFFFFFFF),
                  width: 2,
                ),
              ),
          backgroundColor: const Color(0xFF183059),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.runwayName == null
                            ? 'Schedule Runway Event'
                            : 'Schedule Event for ${widget.runwayName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<RunwayStatus>(
                  initialValue: _selectedType,
                  items: const [
                    RunwayStatus.maintenance,
                    RunwayStatus.inspection,
                    RunwayStatus.closure,
                    RunwayStatus.snowClearance,
                  ]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                  dropdownColor: Color(0xFFA2C2E1),
                  iconEnabledColor: Color(0xFFFFFFFF),
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                  ),
                  decoration: InputDecoration(
                    labelText: "Event",
                    labelStyle: const TextStyle(color: Color(0xFFFFFFFF)),
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
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    labelStyle: const TextStyle(color: Color(0xFFFFFFFF)),
                    errorStyle: const TextStyle(color: Colors.orange),
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
                  validator: _validatePositiveInt,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _offsetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Offset from time after event-save (minutes)',
                    labelStyle: const TextStyle(color: Color(0xFFFFFFFF)),
                    errorStyle: const TextStyle(color: Colors.orange),
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
                  validator: _validateNonNegativeInt,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF276FBF),
                      foregroundColor: Color(0xFFFFFFFF),
                    ),
                    onPressed: _submit,
                    child: const Text('Schedule Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePositiveInt(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= (AbstractRunway.occupationTime + AbstractRunway.wakeSeparationTime)) {
      return 'Enter a number greater than ${AbstractRunway.occupationTime + AbstractRunway.wakeSeparationTime}';
    }
    return null;
  }

  String? _validateNonNegativeInt(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      return 'Enter zero or a positive number';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final durationMinutes = int.parse(_durationController.text);
    final offsetMinutes = int.parse(_offsetController.text);

    final result = RunwayEventDialogResult(
      type: _selectedType,
      duration: Duration(minutes: durationMinutes),
      offsetFromNow: Duration(minutes: offsetMinutes),
    );

    Navigator.pop(context, result);
  }
}
