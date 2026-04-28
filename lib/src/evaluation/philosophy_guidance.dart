import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for PhilosophyGuidance additional behavior.
extension PhilosophyGuidanceExtensions on PhilosophyGuidance {
  /// Create a copy with modified fields.
  PhilosophyGuidance copyWith({
    ValuePriority? valuePriorityApplied,
    ProhibitionCheckResult? prohibitionChecks,
    List<MatchedCriterion>? matchedCriteria,
    DirectionalAttitude? directionalAttitude,
    String? recommendedAction,
    double? confidence,
    String? explanation,
    bool? prohibitionViolated,
  }) {
    return PhilosophyGuidance(
      valuePriorityApplied: valuePriorityApplied ?? this.valuePriorityApplied,
      prohibitionChecks: prohibitionChecks ?? this.prohibitionChecks,
      matchedCriteria: matchedCriteria ?? this.matchedCriteria,
      directionalAttitude: directionalAttitude ?? this.directionalAttitude,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      confidence: confidence ?? this.confidence,
      explanation: explanation ?? this.explanation,
      prohibitionViolated: prohibitionViolated ?? this.prohibitionViolated,
    );
  }
}
