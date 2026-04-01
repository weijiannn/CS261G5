// Operational status of runways
enum RunwayStatus {
  available,
  occupied,
  wait, // Used for runways that are waiting to become available after a landing but are not yet available due to wake separation
  maintenance,
  inspection,
  snowClearance,
  closure;

  // Get the string name.
  String get name {
    switch (this) {
      case RunwayStatus.available:
        return "Available";
      case RunwayStatus.occupied:
        return "Occupied";
      case RunwayStatus.wait:
        return "Waiting";
      case RunwayStatus.maintenance:
        return "Maintenance";
      case RunwayStatus.inspection:
        return "Inspection";
      case RunwayStatus.snowClearance:
        return "Snow Clearance";
      case RunwayStatus.closure:
        return "Closure";
    }
  }

  // Get all string names.
  static List<String> get allNames =>
    RunwayStatus.values.map((e) => e.name).toList();

  // Convert from string to enum.
  static RunwayStatus fromString(String value) {
    switch (value) {
      case "Available":
        return RunwayStatus.available;
      case "Occupied":
        return RunwayStatus.occupied;
      case "Waiting":
        return RunwayStatus.wait;
      case "Maintenance":
        return RunwayStatus.maintenance;
      case "Inspection":
        return RunwayStatus.inspection;
      case "Snow Clearance":
        return RunwayStatus.snowClearance;
      case "Closure":
        return RunwayStatus.closure;
      default:
        throw ArgumentError("Unknown RunwayStatus: $value");
    }
  }

    
}
