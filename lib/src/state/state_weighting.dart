import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for StateWeighting additional behavior.
extension StateWeightingExtensions on StateWeighting {
  /// Whether this weighting creates potential tension with accuracy-first philosophy.
  bool get tensionWithAccuracy => urgency > 0.8 && riskSensitivity < 0.3;

  /// Whether this weighting creates potential tension with speed-first philosophy.
  bool get tensionWithSpeed => urgency < 0.2 && riskSensitivity > 0.8;

  /// Create a copy with modified fields.
  StateWeighting copyWith({
    double? urgency,
    double? riskSensitivity,
    double? confidence,
    double? emotionalIntensity,
  }) {
    return StateWeighting(
      urgency: urgency ?? this.urgency,
      riskSensitivity: riskSensitivity ?? this.riskSensitivity,
      confidence: confidence ?? this.confidence,
      emotionalIntensity: emotionalIntensity ?? this.emotionalIntensity,
    );
  }
}
