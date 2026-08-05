/// A single pathology prediction inside `result_json.findings`.
class Finding {
  const Finding({required this.label, required this.probability});

  final String label;
  final double probability;

  factory Finding.fromJson(Map<String, dynamic> json) {
    return Finding(
      label: json['label'] as String,
      probability: (json['probability'] as num).toDouble(),
    );
  }
}

/// Mirrors the backend `InferenceResultOut` schema, with `result_json`
/// unpacked into typed fields for the UI.
class InferenceResult {
  const InferenceResult({
    required this.id,
    required this.examId,
    required this.modelVersion,
    required this.findings,
    required this.createdAt,
  });

  final String id;
  final String examId;
  final String modelVersion;
  final List<Finding> findings;
  final DateTime createdAt;

  factory InferenceResult.fromJson(Map<String, dynamic> json) {
    final resultJson = json['result_json'] as Map<String, dynamic>;
    final rawFindings = resultJson['findings'] as List<dynamic>? ?? const [];
    return InferenceResult(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      modelVersion: json['model_version'] as String,
      findings: rawFindings
          .map((f) => Finding.fromJson(f as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
