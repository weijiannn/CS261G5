import 'package:air_traffic_sim/ui/app_shell.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AirTrafficSimApp());
}

class AirTrafficSimApp extends StatelessWidget {
  const AirTrafficSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );

  }
}