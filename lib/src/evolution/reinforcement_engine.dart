import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mcp_bundle/mcp_bundle.dart';

/// Direction of a detected reinforcement pattern.
enum PatternDirection {
  /// Consistently positive outcomes.
  reinforcing,

  /// Consistently negative outcomes.
  weakening,

  /// No clear pattern.
  mixed,

  /// Forward compatibility.
  unknown;

  static PatternDirection fromString(String value) {
    return PatternDirection.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PatternDirection.unknown,
    );
  }
}

/// A detected reinforcement pattern from feedback history.
@immutable
class ReinforcementPattern {
  final String componentId;
  final PatternDirection direction;

  /// Pattern strength (0.0-1.0).
  final double strength;

  /// Number of feedback events.
  final int sampleSize;

  /// Average outcome score.
  final double averageOutcomeScore;

  const ReinforcementPattern({
    required this.componentId,
    required this.direction,
    required this.strength,
    required this.sampleSize,
    required this.averageOutcomeScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'componentId': componentId,
      'direction': direction.name,
      'strength': strength,
      'sampleSize': sampleSize,
      'averageOutcomeScore': averageOutcomeScore,
    };
  }

  factory ReinforcementPattern.fromJson(Map<String, dynamic> json) {
    return ReinforcementPattern(
      componentId: json['componentId'] as String,
      direction: PatternDirection.fromString(json['direction'] as String),
      strength: (json['strength'] as num).toDouble(),
      sampleSize: json['sampleSize'] as int,
      averageOutcomeScore: (json['averageOutcomeScore'] as num).toDouble(),
    );
  }
}

/// Engine that analyzes feedback to detect reinforcement patterns
/// and propose philosophy evolution.
///
/// IMPORTANT: Proposals must NEVER be auto-applied. They must be
/// presented for explicit human approval (NFR-SEC-002).
class ReinforcementEngine {
  /// Minimum number of feedback events required before proposing evolution.
  static const int minFeedbackCount = 3;

  /// Minimum pattern strength to generate a proposal.
  static const double minPatternStrength = 0.6;

  const ReinforcementEngine();

  /// Analyze a feedback event and determine if an evolution proposal is warranted.
  EvolutionProposal? analyzeFeedback(
    FeedbackEvent event,
    List<FeedbackEvent> history,
    Ethos currentEthos,
  ) {
    final relatedFeedback = _findRelatedFeedback(event, history);

    if (relatedFeedback.length < minFeedbackCount) return null;

    final pattern = _detectPattern(relatedFeedback);
    if (pattern == null || pattern.strength < minPatternStrength) return null;

    return _generateProposal(event, pattern, currentEthos);
  }

  List<FeedbackEvent> _findRelatedFeedback(
    FeedbackEvent event,
    List<FeedbackEvent> history,
  ) {
    final allEvents = [...history, event];

    if (event.hasValuePriorityLink) {
      return allEvents
          .where((e) => e.valuePriorityId == event.valuePriorityId)
          .toList();
    }

    if (event.hasCriterionLink) {
      return allEvents
          .where((e) => e.judgmentCriterionId == event.judgmentCriterionId)
          .toList();
    }

    return allEvents.where((e) => e.ethosId == event.ethosId).toList();
  }

  ReinforcementPattern? _detectPattern(List<FeedbackEvent> feedback) {
    if (feedback.isEmpty) return null;

    final componentId = feedback.first.valuePriorityId ??
        feedback.first.judgmentCriterionId ??
        feedback.first.ethosId;

    final avgScore = feedback
            .map((e) => e.outcomeScore)
            .reduce((a, b) => a + b) /
        feedback.length;

    final PatternDirection direction;
    if (avgScore > 0.2) {
      direction = PatternDirection.reinforcing;
    } else if (avgScore < -0.2) {
      direction = PatternDirection.weakening;
    } else {
      direction = PatternDirection.mixed;
    }

    final variance = feedback
            .map((e) => math.pow(e.outcomeScore - avgScore, 2))
            .reduce((a, b) => a + b) /
        feedback.length;
    final stdDev = math.sqrt(variance);
    final consistency = 1.0 - (stdDev / 0.5).clamp(0.0, 1.0);

    final strength = consistency * avgScore.abs();

    final sampleBonus =
        ((feedback.length - minFeedbackCount) * 0.05).clamp(0.0, 0.15);
    final finalStrength = (strength + sampleBonus).clamp(0.0, 1.0);

    return ReinforcementPattern(
      componentId: componentId,
      direction: direction,
      strength: finalStrength,
      sampleSize: feedback.length,
      averageOutcomeScore: avgScore,
    );
  }

  EvolutionProposal _generateProposal(
    FeedbackEvent trigger,
    ReinforcementPattern pattern,
    Ethos currentEthos,
  ) {
    final isValuePriority = trigger.hasValuePriorityLink;
    final targetId = trigger.valuePriorityId ??
        trigger.judgmentCriterionId ??
        trigger.ethosId;
    final targetType =
        isValuePriority ? 'valuePriority' : 'judgmentCriterion';

    final EvolutionType type;
    final String description;

    switch (pattern.direction) {
      case PatternDirection.reinforcing:
        type = EvolutionType.reinforce;
        description = 'Reinforce "$targetId" ($targetType)';
      case PatternDirection.weakening:
        type = EvolutionType.weaken;
        description = 'Weaken "$targetId" ($targetType)';
      case PatternDirection.mixed:
      case PatternDirection.unknown:
        type = EvolutionType.refine;
        description = 'Refine "$targetId" ($targetType)';
    }

    final sampleSizeFactor = (pattern.sampleSize / 10.0).clamp(0.0, 1.0);
    final proposalConfidence =
        pattern.strength * 0.8 + sampleSizeFactor * 0.2;

    return EvolutionProposal(
      id: 'prop-${trigger.id}-${DateTime.now().millisecondsSinceEpoch}',
      ethosId: trigger.ethosId,
      type: type,
      targetComponentId: targetId,
      targetComponentType: targetType,
      description: description,
      rationale:
          '${pattern.sampleSize} feedback events with avg score ${pattern.averageOutcomeScore.toStringAsFixed(2)}, pattern strength ${pattern.strength.toStringAsFixed(3)}',
      supportingFeedbackIds: [],
      confidence: proposalConfidence.clamp(0.0, 1.0),
      proposedChange: ProposedChange(
        diff: description,
      ),
      status: ProposalStatus.pending,
    );
  }
}

/// A record of an evolution event for audit and history.
@immutable
class EvolutionRecord {
  final String id;
  final String ethosId;
  final EvolutionProposal proposal;
  final ProposalStatus finalStatus;
  final String? reviewerNote;
  final DateTime recordedAt;

  EvolutionRecord({
    required this.id,
    required this.ethosId,
    required this.proposal,
    required this.finalStatus,
    this.reviewerNote,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ethosId': ethosId,
      'proposal': proposal.toJson(),
      'finalStatus': finalStatus.name,
      if (reviewerNote != null) 'reviewerNote': reviewerNote,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory EvolutionRecord.fromJson(Map<String, dynamic> json) {
    return EvolutionRecord(
      id: json['id'] as String,
      ethosId: json['ethosId'] as String,
      proposal: EvolutionProposal.fromJson(
          json['proposal'] as Map<String, dynamic>),
      finalStatus: ProposalStatus.fromString(json['finalStatus'] as String),
      reviewerNote: json['reviewerNote'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : null,
    );
  }
}
