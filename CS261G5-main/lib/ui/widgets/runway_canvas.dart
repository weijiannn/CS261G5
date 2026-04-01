import 'dart:math';

import 'package:air_traffic_sim/ui/models/runway_config_ui.dart';
import 'package:flutter/material.dart';

class RunwayCanvas extends StatelessWidget {
  final List<RunwayConfigUI> runways;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int) onEdit;

  const RunwayCanvas({
    super.key,
    required this.runways,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasHeight = constraints.maxHeight;
        final canvasWidth = constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF276FBF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(10, (index) {
                    if (index >= runways.length) {
                      return SizedBox(
                        width: canvasWidth * 0.08,
                        height: canvasHeight,
                      );
                    }

                    return SizedBox(
                      width: canvasWidth * 0.08,
                      height: canvasHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => onEdit(index),
                            child: _RunwayGraphic(
                              index: index,
                              runway: runways[index],
                              canvasHeight: canvasHeight,
                              canvasWidth: canvasWidth,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _DeleteRunwayButton(
                              onTap: () => onRemove(index),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Color(0xFF183059),
                  foregroundColor: Color(0xFFFFFFFF),
                  onPressed: onAdd,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RunwayGraphic extends StatefulWidget {
  final int index;
  final RunwayConfigUI runway;
  final double canvasHeight;
  final double canvasWidth;

  const _RunwayGraphic({
    required this.index,
    required this.runway,
    required this.canvasHeight,
    required this.canvasWidth,
  });

  @override
  State<_RunwayGraphic> createState() => _RunwayGraphicState();
}

class _RunwayGraphicState extends State<_RunwayGraphic> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final runwayHeight = widget.canvasHeight;
    final runwayWidth = widget.canvasWidth * 0.08;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: runwayWidth,
        height: runwayHeight,
        decoration: BoxDecoration(
          color: widget.runway.isInvalid
              ? Colors.red
              : hovering
                  ? const Color.fromARGB(255, 100, 100, 100)
                  : Color.fromARGB(255, 50, 50, 50),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: hovering
              ? const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black26,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            "- - - - - - - - ${widget.runway.runwayIdController.text.trim().isEmpty ? '${(widget.index + 1).toString().padLeft(2, '0')}L' : widget.runway.runwayIdController.text.trim() + widget.runway.mode[0]} - - - - - - - -",
            style: TextStyle(
              fontSize: min(runwayHeight * 0.06, runwayWidth * 0.8),
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteRunwayButton extends StatefulWidget {
  final VoidCallback onTap;

  const _DeleteRunwayButton({
    required this.onTap,
  });

  @override
  State<_DeleteRunwayButton> createState() => _DeleteRunwayButtonState();
}

class _DeleteRunwayButtonState extends State<_DeleteRunwayButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: hovering ? Colors.red.shade900 : Colors.red.shade700,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(5),
            boxShadow: hovering
                ? const [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black26,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: const Icon(
            Icons.close,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}