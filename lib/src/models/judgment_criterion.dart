import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for JudgmentCriterion additional behavior.
extension JudgmentCriterionExtensions on JudgmentCriterion {
  /// Validate JudgmentCriterion constraints.
  void validate() {
    if (id.isEmpty) {
      throw ArgumentError.value(
          id, 'id', 'JudgmentCriterion id must not be empty');
    }
  }

  /// Create a copy with modified fields.
  JudgmentCriterion copyWith({
    String? id,
    List<String>? conditions,
    String? preferredAction,
    String? requiredValidation,
    String? fallbackStrategy,
  }) {
    return JudgmentCriterion(
      id: id ?? this.id,
      conditions: conditions ?? this.conditions,
      preferredAction: preferredAction ?? this.preferredAction,
      requiredValidation: requiredValidation ?? this.requiredValidation,
      fallbackStrategy: fallbackStrategy ?? this.fallbackStrategy,
    );
  }
}
