/// Represents mode of runways.
/// Note that [RunwayMode.mixed] is ONLY to be used upon instantiation of runways
/// and should not be used during the simulation run.
enum RunwayMode {
  landing,
  takeOff,
  mixed;

  // Get the string name.
  String get name {
    switch (this) {
      case RunwayMode.landing:
        return "Landing";
      case RunwayMode.takeOff:
        return "Take Off";
      case RunwayMode.mixed:
        return "Mixed";
    }
  }

  // Get all string names.
  static List<String> get allNames =>
  RunwayMode.values.map((e) => e.name).toList();
}