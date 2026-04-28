import 'package:meta/meta.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

/// Pre-generation intervention result.
@immutable
class PreGenerationResult extends InterventionResult {
  /// IDs of filtered-out knowledge.
  final List<String>? filteredKnowledgeIds;

  /// New knowledge ranking.
  final List<String>? rankedKnowledgeOrder;

  /// Chosen skill approach.
  final String? selectedSkillApproach;

  /// Activated profile posture.
  final String? activatedProfilePosture;

  PreGenerationResult({
    required super.interventions,
    super.prohibitionViolated,
    super.prohibitionViolationIds,
    super.modified,
    super.modifications,
    super.appliedAt,
    this.filteredKnowledgeIds,
    this.rankedKnowledgeOrder,
    this.selectedSkillApproach,
    this.activatedProfilePosture,
  }) : super(point: InterventionPoint.preGeneration);
}

/// During-generation intervention result.
@immutable
class DuringGenerationResult extends InterventionResult {
  /// New candidate order.
  final List<int>? candidateRanking;

  /// Expression changes.
  final Map<String, dynamic>? expressionAdjustments;

  /// Structure changes.
  final Map<String, dynamic>? structureChanges;

  DuringGenerationResult({
    required super.interventions,
    super.prohibitionViolated,
    super.prohibitionViolationIds,
    super.modified,
    super.modifications,
    super.appliedAt,
    this.candidateRanking,
    this.expressionAdjustments,
    this.structureChanges,
  }) : super(point: InterventionPoint.duringGeneration);
}

/// Post-generation intervention result.
@immutable
class PostGenerationResult extends InterventionResult {
  final ProhibitionCheckResult prohibitionCheckResult;

  /// Evidence sufficiency score (0.0-1.0).
  final double evidenceSufficiency;

  /// Whether evidence meets threshold.
  final bool evidenceSufficient;

  /// Tone alignment changes.
  final Map<String, dynamic>? toneAdjustments;

  PostGenerationResult({
    required super.interventions,
    required super.prohibitionViolated,
    super.prohibitionViolationIds,
    super.modified,
    super.modifications,
    super.appliedAt,
    required this.prohibitionCheckResult,
    required this.evidenceSufficiency,
    required this.evidenceSufficient,
    this.toneAdjustments,
  }) : super(point: InterventionPoint.postGeneration);
}
