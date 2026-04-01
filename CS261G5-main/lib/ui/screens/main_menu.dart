import 'package:air_traffic_sim/ui/app_shell.dart';
import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  final void Function(int index, {Object? arguments}) onNavigate;

  const MainMenu({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF183059),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final isSmall = width < 900;
          final isVerySmall = width < 600;

          final horizontalPadding = isVerySmall ? 20.0 : (isSmall ? 32.0 : 64.0);
          final topPadding = isVerySmall ? 24.0 : (isSmall ? 40.0 : 80.0);

          final titleFontSize = isVerySmall
              ? 48.0
              : isSmall
                  ? 72.0
                  : 120.0;

          final buttonHeight = isVerySmall
              ? 64.0
              : isSmall
                  ? 74.0
                  : 90.0;

          final buttonTextSize = isVerySmall
              ? 18.0
              : isSmall
                  ? 20.0
                  : 22.0;

          Widget buildMenuButtons() {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmall ? double.infinity : 800,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuButton(
                    text: "Configure Simulation",
                    height: buttonHeight,
                    fontSize: buttonTextSize,
                    onPressed: () => onNavigate(AppTab.configuration),
                  ),
                  const SizedBox(height: 30),
                  _menuButton(
                    text: "View Simulation",
                    height: buttonHeight,
                    fontSize: buttonTextSize,
                    onPressed: () => onNavigate(AppTab.results),
                  ),
                  const SizedBox(height: 30),
                  _menuButton(
                    text: "Compare Simulations",
                    height: buttonHeight,
                    fontSize: buttonTextSize,
                    onPressed: () => onNavigate(AppTab.compare),
                  ),
                ],
              ),
            );
          }

          Widget buildTitle() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  'Airport',
                  textAlign: isSmall ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFFFF),
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulator',
                  textAlign: isSmall ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFFFF),
                    height: 0.95,
                  ),
                ),
              ],
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: FractionallySizedBox(
                  widthFactor: isVerySmall ? 0.9 : (isSmall ? 0.8 : 0.7),
                  heightFactor: isVerySmall ? 0.25 : (isSmall ? 0.3 : 0.4),
                  child: Transform.scale(
                    scale: isVerySmall ? 1.0 : (isSmall ? 1.2 : 1.5),
                    alignment: Alignment.bottomLeft,
                    child: Image.asset(
                      'assets/images/main_menu_plane.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomLeft,
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: height - topPadding - 24,
                    ),
                    child: isSmall
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              buildTitle(),
                              const SizedBox(height: 40),
                              buildMenuButtons(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: buildTitle()),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 0),
                                  child: buildMenuButtons(),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuButton({
    required String text,
    required double height,
    required double fontSize,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(height),
          textStyle: TextStyle(fontSize: fontSize),
          backgroundColor: const Color(0xFF276FBF),
          foregroundColor: const Color(0xFFFFFFFF),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}