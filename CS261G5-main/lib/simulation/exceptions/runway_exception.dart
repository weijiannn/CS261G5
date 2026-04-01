/// Extend for any specific exceptions regarding runways.
abstract class RunwayException implements Exception {
  String? cause;
  int id;
  RunwayException(this.id, [this.cause]);
}