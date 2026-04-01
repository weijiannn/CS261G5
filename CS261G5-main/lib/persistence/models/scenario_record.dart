class ScenarioRecord {
  final String id;
  final String name;
  final String generationModel;
  final String? description;
  final String? configJson;
  final String? notes;
  final DateTime createdAt;

  const ScenarioRecord({
    required this.id,
    required this.name,
    this.generationModel = 'Uniform',
    this.description,
    this.configJson,
    this.notes,
    required this.createdAt,
  });
}
