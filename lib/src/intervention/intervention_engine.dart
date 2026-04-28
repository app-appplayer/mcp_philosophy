import 'package:mcp_bundle/mcp_bundle.dart';

import '../evaluation/philosophy_evaluator.dart';
import 'intervention_result.dart';

/// The pipeline intervention engine that applies Philosophy at three stages.
///
/// This is where Philosophy acts as a Control Axis — actively shaping
/// pipeline behavior rather than passively storing values.
class InterventionEngine {
  final PhilosophyEvaluator _evaluator;

  const InterventionEngine({
    required PhilosophyEvaluator evaluator,
  }) : _evaluator = evaluator;

  /// Execute intervention at the given pipeline point.
  InterventionResult intervene(
    InterventionPoint point,
    PipelineContext pipelineContext,
    Ethos ethos,
  ) {
    return switch (point) {
      InterventionPoint.preGeneration =>
        _preGenerate(pipelineContext, ethos),
      InterventionPoint.duringGeneration =>
        _duringGenerate(pipelineContext, ethos),
      InterventionPoint.postGeneration =>
        _postGenerate(pipelineContext, ethos),
      InterventionPoint.unknown => InterventionResult.noOp(),
    };
  }

  /// Pre-generation: filter knowledge, select approach, activate posture.
  PreGenerationResult _preGenerate(PipelineContext context, Ethos ethos) {
    final interventions = <AppliedIntervention>[];
    final topPriority = ethos.topPriority;

    List<String>? filteredIds;
    List<String>? rankedOrder;
    if (context.knowledgeRetrieved.isNotEmpty && topPriority != null) {
      final entries = context.knowledgeRetrieved.entries.toList();

      entries.sort((a, b) {
        final aRelevance = _extractRelevance(a.value);
        final bRelevance = _extractRelevance(b.value);
        return bRelevance.compareTo(aRelevance);
      });

      filteredIds = entries
          .where((e) => _extractRelevance(e.value) < 0.3)
          .map((e) => e.key)
          .toList();

      rankedOrder = entries
          .where((e) => _extractRelevance(e.value) >= 0.3)
          .map((e) => e.key)
          .toList();

      interventions.add(AppliedIntervention(
        id: 'intv-pre-knowledge-${context.pipelineId}',
        type: InterventionType.knowledgeRank,
        description:
            'Re-ranked knowledge by ${topPriority.display} priority',
        rationale:
            'ValuePriority ${topPriority.id}: ${topPriority.display}',
        ethosComponentId: topPriority.id,
      ));
    }

    String? selectedApproach;
    if (context.skillContext != null) {
      final evalContext = PhilosophyEvaluationContext(
        contextId: 'pre-gen-${context.pipelineId}',
        facts: context.knowledgeRetrieved,
      );
      final matched = _evaluator.matchCriteria(
          ethos.judgmentCriteria, evalContext);

      if (matched.isNotEmpty) {
        selectedApproach = matched.first.preferredAction;
        interventions.add(AppliedIntervention(
          id: 'intv-pre-skill-${context.pipelineId}',
          type: InterventionType.skillSelection,
          description: 'Selected approach: $selectedApproach',
          rationale:
              'JudgmentCriterion ${matched.first.criterionId} matched',
          ethosComponentId: matched.first.criterionId,
        ));
      }
    }

    String? activatedPosture;
    if (context.profileContext != null &&
        ethos.directionalAttitudes.isNotEmpty) {
      final attitude = ethos.directionalAttitudes.first;
      activatedPosture = attitude.posture;
      interventions.add(AppliedIntervention(
        id: 'intv-pre-profile-${context.pipelineId}',
        type: InterventionType.profileActivation,
        description:
            'Activated posture: ${attitude.posture}',
        rationale:
            'DirectionalAttitude ${attitude.id}: ${attitude.domain.name}',
        ethosComponentId: attitude.id,
      ));
    }

    return PreGenerationResult(
      interventions: interventions,
      modified: interventions.isNotEmpty,
      filteredKnowledgeIds: filteredIds,
      rankedKnowledgeOrder: rankedOrder,
      selectedSkillApproach: selectedApproach,
      activatedProfilePosture: activatedPosture,
    );
  }

  /// During-generation: re-rank candidates, adjust expression, modify structure.
  DuringGenerationResult _duringGenerate(
      PipelineContext context, Ethos ethos) {
    final interventions = <AppliedIntervention>[];
    final topPriority = ethos.topPriority;

    List<int>? candidateRanking;
    if (context.candidateResponses != null &&
        context.candidateResponses!.isNotEmpty &&
        topPriority != null) {
      candidateRanking = List.generate(
          context.candidateResponses!.length, (i) => i);

      interventions.add(AppliedIntervention(
        id: 'intv-during-rank-${context.pipelineId}',
        type: InterventionType.candidateReRank,
        description:
            'Candidates evaluated against ${topPriority.display} priority',
        rationale:
            'ValuePriority ${topPriority.id}: ${topPriority.display}',
        ethosComponentId: topPriority.id,
      ));
    }

    Map<String, dynamic>? expressionAdjustments;
    if (ethos.directionalAttitudes.isNotEmpty) {
      final attitude = ethos.directionalAttitudes.first;
      expressionAdjustments = {
        'attitudeDomain': attitude.domain.name,
        'posture': attitude.posture,
        'implications': attitude.behavioralImplications,
      };

      interventions.add(AppliedIntervention(
        id: 'intv-during-expr-${context.pipelineId}',
        type: InterventionType.expressionAdjust,
        description:
            'Expression adjusted per ${attitude.domain.name} attitude',
        rationale:
            'DirectionalAttitude ${attitude.id}: ${attitude.posture}',
        ethosComponentId: attitude.id,
      ));
    }

    return DuringGenerationResult(
      interventions: interventions,
      modified: interventions.isNotEmpty,
      candidateRanking: candidateRanking,
      expressionAdjustments: expressionAdjustments,
    );
  }

  /// Post-generation: check prohibitions, verify evidence, align tone.
  PostGenerationResult _postGenerate(PipelineContext context, Ethos ethos) {
    final interventions = <AppliedIntervention>[];

    final evalContext = PhilosophyEvaluationContext(
      contextId: 'post-gen-${context.pipelineId}',
      proposedOutput: context.generatedOutput,
      facts: context.knowledgeRetrieved,
    );

    final prohibitionResult =
        _evaluator.checkProhibitions(ethos.prohibitions, evalContext);

    if (prohibitionResult.hasHardViolation) {
      for (final id in prohibitionResult.hardViolationIds) {
        interventions.add(AppliedIntervention(
          id: 'intv-post-block-$id-${context.pipelineId}',
          type: InterventionType.prohibitionBlock,
          description: 'Output blocked: hard prohibition $id violated',
          rationale: 'Prohibition $id violated in generated output',
          ethosComponentId: id,
        ));
      }
    }

    for (final id in prohibitionResult.softViolationIds) {
      interventions.add(AppliedIntervention(
        id: 'intv-post-warn-$id-${context.pipelineId}',
        type: InterventionType.prohibitionWarn,
        description: 'Warning: soft prohibition $id violated',
        rationale: 'Soft prohibition $id violated in generated output',
        ethosComponentId: id,
      ));
    }

    final evidenceCount = context.knowledgeRetrieved.length;
    final evidenceSufficiency =
        evidenceCount > 0 ? (evidenceCount / 5.0).clamp(0.0, 1.0) : 0.0;
    final evidenceSufficient = evidenceSufficiency >= 0.5;

    if (!evidenceSufficient) {
      interventions.add(AppliedIntervention(
        id: 'intv-post-evidence-${context.pipelineId}',
        type: InterventionType.evidenceVerify,
        description:
            'Evidence insufficiency detected (${evidenceSufficiency.toStringAsFixed(2)})',
        rationale: 'Conservative stance applied due to insufficient evidence',
      ));
    }

    Map<String, dynamic>? toneAdjustments;
    if (context.profileContext != null &&
        ethos.directionalAttitudes.isNotEmpty) {
      toneAdjustments = {
        'alignedWith': ethos.directionalAttitudes.first.posture,
      };
      interventions.add(AppliedIntervention(
        id: 'intv-post-tone-${context.pipelineId}',
        type: InterventionType.toneAlign,
        description: 'Tone aligned with philosophy direction',
        rationale:
            'Directional attitude: ${ethos.directionalAttitudes.first.posture}',
        ethosComponentId: ethos.directionalAttitudes.first.id,
      ));
    }

    return PostGenerationResult(
      interventions: interventions,
      prohibitionViolated: prohibitionResult.hasHardViolation,
      prohibitionViolationIds: prohibitionResult.hardViolationIds,
      modified: interventions.isNotEmpty,
      prohibitionCheckResult: prohibitionResult,
      evidenceSufficiency: evidenceSufficiency,
      evidenceSufficient: evidenceSufficient,
      toneAdjustments: toneAdjustments,
    );
  }

  double _extractRelevance(dynamic value) {
    if (value is Map<String, dynamic>) {
      final relevance = value['relevance'];
      if (relevance is num) return relevance.toDouble();
    }
    return 0.5;
  }
}
