import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for EvolutionProposal additional behavior.
extension EvolutionProposalExtensions on EvolutionProposal {
  /// Create a copy with modified fields.
  EvolutionProposal copyWith({
    String? id,
    String? ethosId,
    EvolutionType? type,
    String? targetComponentId,
    String? targetComponentType,
    String? description,
    String? rationale,
    List<String>? supportingFeedbackIds,
    double? confidence,
    ProposedChange? proposedChange,
    ProposalStatus? status,
    DateTime? proposedAt,
  }) {
    return EvolutionProposal(
      id: id ?? this.id,
      ethosId: ethosId ?? this.ethosId,
      type: type ?? this.type,
      targetComponentId: targetComponentId ?? this.targetComponentId,
      targetComponentType: targetComponentType ?? this.targetComponentType,
      description: description ?? this.description,
      rationale: rationale ?? this.rationale,
      supportingFeedbackIds:
          supportingFeedbackIds ?? this.supportingFeedbackIds,
      confidence: confidence ?? this.confidence,
      proposedChange: proposedChange ?? this.proposedChange,
      status: status ?? this.status,
      proposedAt: proposedAt ?? this.proposedAt,
    );
  }
}
