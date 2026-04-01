import 'package:flutter/material.dart';

/// Shared three‑column dashboard layout used by the real‑time screen.
class DashboardLayout extends StatelessWidget {
  final Widget leftColumn;
  final Widget centerColumn;
  final Widget rightColumn;

  const DashboardLayout({
    super.key,
    required this.leftColumn,
    required this.centerColumn,
    required this.rightColumn,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fall back to vertical layout on very narrow screens.
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: leftColumn,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: centerColumn,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: rightColumn,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: leftColumn,
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: centerColumn,
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: rightColumn,
            ),
          ],
        );
      },
    );
  }
}