import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:air_traffic_sim/main.dart';
import 'package:air_traffic_sim/ui/app_shell.dart';

void main() {
  group('AirTrafficSimApp Tests', () {
    testWidgets('App mounts and renders AppShell', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      await tester.pumpWidget(const AirTrafficSimApp());

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}