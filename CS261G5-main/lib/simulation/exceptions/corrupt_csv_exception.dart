/// Extend for any specific exceptions regarding runways.
class CorruptCsvException implements Exception {
  String? cause;
  int id;
  CorruptCsvException(this.id, [this.cause]);
}