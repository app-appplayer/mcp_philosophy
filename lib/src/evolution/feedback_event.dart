import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for FeedbackEvent additional behavior.
extension FeedbackEventExtensions on FeedbackEvent {
  /// Validate FeedbackEvent constraints.
  void validate() {
    if (id.isEmpty) {
      throw ArgumentError.value(
          id, 'id', 'FeedbackEvent id must not be empty');
    }
    if (actionId.isEmpty) {
      throw ArgumentError.value(
          actionId, 'actionId', 'FeedbackEvent actionId must not be empty');
    }
    if (ethosId.isEmpty) {
      throw ArgumentError.value(
          ethosId, 'ethosId', 'FeedbackEvent ethosId must not be empty');
    }
  }

  /// Create a copy with modified fields.
  FeedbackEvent copyWith({
    String? id,
    String? actionId,
    String? ethosId,
    String? valuePriorityId,
    String? judgmentCriterionId,
    FeedbackOutcome? outcome,
    double? outcomeScore,
    String? outcomeDescription,
    Map<String, dynamic>? contextSnapshot,
    DateTime? occurredAt,
  }) {
    return FeedbackEvent(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      ethosId: ethosId ?? this.ethosId,
      valuePriorityId: valuePriorityId ?? this.valuePriorityId,
      judgmentCriterionId: judgmentCriterionId ?? this.judgmentCriterionId,
      outcome: outcome ?? this.outcome,
      outcomeScore: outcomeScore ?? this.outcomeScore,
      outcomeDescription: outcomeDescription ?? this.outcomeDescription,
      contextSnapshot: contextSnapshot ?? this.contextSnapshot,
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }
}
