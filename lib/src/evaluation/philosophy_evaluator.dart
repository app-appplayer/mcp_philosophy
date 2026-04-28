import 'package:mcp_bundle/mcp_bundle.dart';

import 'conflict_resolver.dart';

/// Backward-compatible alias for PhilosophyEvaluationContext.
///
/// mcp_bundle names this type [PhilosophyEvaluationContext] to avoid
/// naming conflicts. Within mcp_philosophy, we use the shorter alias.
typedef EvaluationContext = PhilosophyEvaluationContext;

/// Extensions for PhilosophyEvaluationContext additional behavior.
extension EvaluationContextExtensions on PhilosophyEvaluationContext {
  /// Validate context constraints.
  void validate() {
    if (contextId.isEmpty) {
      throw ArgumentError.value(
          contextId, 'contextId', 'contextId must not be empty');
    }
  }

  /// Create a copy with modified fields.
  PhilosophyEvaluationContext copyWith({
    String? contextId,
    Map<String, dynamic>? facts,
    Map<String, double>? metrics,
    String? proposedAction,
    String? proposedOutput,
    Map<String, dynamic>? profileState,
    Map<String, dynamic>? stateWeighting,
    DateTime? evaluatedAt,
  }) {
    return PhilosophyEvaluationContext(
      contextId: contextId ?? this.contextId,
      facts: facts ?? this.facts,
      metrics: metrics ?? this.metrics,
      proposedAction: proposedAction ?? this.proposedAction,
      proposedOutput: proposedOutput ?? this.proposedOutput,
      profileState: profileState ?? this.profileState,
      stateWeighting: stateWeighting ?? this.stateWeighting,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    );
  }
}

/// The core evaluation engine that applies an Ethos against a runtime
/// context to produce actionable [PhilosophyGuidance].
class PhilosophyEvaluator {
  final ConflictResolver _conflictResolver;

  const PhilosophyEvaluator({
    ConflictResolver? conflictResolver,
  }) : _conflictResolver = conflictResolver ?? const ConflictResolver();

  /// Evaluate an Ethos against a context to produce guidance.
  PhilosophyGuidance evaluate(
      Ethos ethos, PhilosophyEvaluationContext context) {
    final prohibitionResult = checkProhibitions(ethos.prohibitions, context);
    final matchedCriteria = matchCriteria(ethos.judgmentCriteria, context);
    final appliedPriority =
        _resolveApplicablePriority(ethos.valuePriorities, context);
    final attitude =
        _resolveAttitude(ethos.directionalAttitudes, context);
    final confidence =
        _computeConfidence(prohibitionResult, matchedCriteria, context, ethos);

    return PhilosophyGuidance(
      valuePriorityApplied: appliedPriority,
      prohibitionChecks: prohibitionResult,
      matchedCriteria: matchedCriteria,
      directionalAttitude: attitude,
      recommendedAction:
          _deriveAction(matchedCriteria, appliedPriority, attitude),
      confidence: confidence,
      explanation:
          _buildExplanation(appliedPriority, matchedCriteria, attitude),
      prohibitionViolated: prohibitionResult.hasHardViolation,
    );
  }

  /// Check all prohibitions against a context/request.
  ProhibitionCheckResult checkProhibitions(
    List<Prohibition> prohibitions,
    PhilosophyEvaluationContext context,
  ) {
    final checks = <ProhibitionCheck>[];

    for (final prohibition in prohibitions) {
      final contentToCheck = context.proposedOutput ?? context.proposedAction;

      if (contentToCheck == null) {
        checks.add(ProhibitionCheck(
          prohibitionId: prohibition.id,
          violated: false,
          severity: prohibition.severity,
        ));
        continue;
      }

      final contentLower = contentToCheck.toLowerCase();

      final potentiallyViolated = _detectViolation(
        prohibition.statement,
        contentLower,
        context,
      );

      if (potentiallyViolated) {
        final hasException = prohibition.hasExceptions &&
            _checkProhibitionExceptions(prohibition, context);

        if (hasException) {
          checks.add(ProhibitionCheck(
            prohibitionId: prohibition.id,
            violated: false,
            severity: prohibition.severity,
            exceptionApplied: true,
            appliedExceptionCondition: prohibition.exceptions!
                .firstWhere((e) => _exceptionMatches(e, context))
                .condition,
          ));
        } else {
          checks.add(ProhibitionCheck(
            prohibitionId: prohibition.id,
            violated: true,
            severity: prohibition.severity,
            violationDetail:
                'Content may violate: "${prohibition.statement}"',
          ));
        }
      } else {
        checks.add(ProhibitionCheck(
          prohibitionId: prohibition.id,
          violated: false,
          severity: prohibition.severity,
        ));
      }
    }

    return ProhibitionCheckResults.withViolations(checks);
  }

  /// Find all judgment criteria whose conditions match the context.
  List<MatchedCriterion> matchCriteria(
    List<JudgmentCriterion> criteria,
    PhilosophyEvaluationContext context,
  ) {
    final matched = <MatchedCriterion>[];

    for (final criterion in criteria) {
      final strength = _evaluateConditions(criterion.conditions, context);
      if (strength > 0.0) {
        matched.add(MatchedCriterion(
          criterionId: criterion.id,
          preferredAction: criterion.preferredAction,
          matchStrength: strength,
        ));
      }
    }

    for (var i = 0; i < matched.length; i++) {
      for (var j = i + 1; j < matched.length; j++) {
        if (matched[i].preferredAction != matched[j].preferredAction) {
          matched[i] = MatchedCriterion(
            criterionId: matched[i].criterionId,
            preferredAction: matched[i].preferredAction,
            matchStrength: matched[i].matchStrength,
            hasConflict: true,
            conflictWith: matched[j].criterionId,
            conflictAnnotation:
                'Conflicts with ${matched[j].criterionId}: different preferred actions',
          );
          matched[j] = MatchedCriterion(
            criterionId: matched[j].criterionId,
            preferredAction: matched[j].preferredAction,
            matchStrength: matched[j].matchStrength,
            hasConflict: true,
            conflictWith: matched[i].criterionId,
            conflictAnnotation:
                'Conflicts with ${matched[i].criterionId}: different preferred actions',
          );
        }
      }
    }

    matched.sort((a, b) => b.matchStrength.compareTo(a.matchStrength));
    return matched;
  }

  /// Resolve value conflict between two priorities.
  ValueResolution resolveConflict(
    ValuePriority a,
    ValuePriority b,
    PhilosophyEvaluationContext context,
  ) {
    return _conflictResolver.resolve(a, b, context);
  }

  ValuePriority? _resolveApplicablePriority(
    List<ValuePriority> priorities,
    PhilosophyEvaluationContext context,
  ) {
    if (priorities.isEmpty) return null;
    final sorted = List<ValuePriority>.from(priorities)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return sorted.first;
  }

  DirectionalAttitude? _resolveAttitude(
    List<DirectionalAttitude> attitudes,
    PhilosophyEvaluationContext context,
  ) {
    if (attitudes.isEmpty) return null;

    for (final attitude in attitudes) {
      final domainName = attitude.domain.name;
      for (final value in context.facts.values) {
        if (value
            .toString()
            .toLowerCase()
            .contains(domainName.toLowerCase())) {
          return attitude;
        }
      }
    }

    return attitudes.first;
  }

  double _computeConfidence(
    ProhibitionCheckResult prohibitionResult,
    List<MatchedCriterion> matchedCriteria,
    PhilosophyEvaluationContext context,
    Ethos ethos,
  ) {
    final evidenceCount = context.facts.values.where((v) => v != null).length;
    final expectedCount = ethos.judgmentCriteria
        .fold<int>(0, (sum, jc) => sum + jc.conditions.length);
    final baseScore = expectedCount > 0
        ? (evidenceCount / expectedCount).clamp(0.0, 1.0)
        : 0.5;

    double criterionBonus = 0.0;
    if (matchedCriteria.isNotEmpty) {
      final avgStrength = matchedCriteria
              .map((c) => c.matchStrength)
              .reduce((a, b) => a + b) /
          matchedCriteria.length;
      criterionBonus = avgStrength * 0.2;
    }

    final prohibitionPenalty =
        prohibitionResult.hardViolationIds.length * 0.5 +
            prohibitionResult.softViolationIds.length * 0.1;

    final conflictCount =
        matchedCriteria.where((c) => c.hasConflict).length;
    final conflictPenalty = conflictCount * 0.15;

    return (baseScore + criterionBonus - prohibitionPenalty - conflictPenalty)
        .clamp(0.0, 1.0);
  }

  String _deriveAction(
    List<MatchedCriterion> matchedCriteria,
    ValuePriority? appliedPriority,
    DirectionalAttitude? attitude,
  ) {
    final parts = <String>[];

    if (matchedCriteria.isNotEmpty) {
      parts.add(matchedCriteria.first.preferredAction);
    }

    if (appliedPriority != null && parts.isEmpty) {
      parts.add(
          'Apply ${appliedPriority.higherValue}-first approach over ${appliedPriority.lowerValue}');
    }

    if (attitude != null && parts.isEmpty) {
      parts.add('${attitude.posture} (${attitude.domain.name} domain)');
    }

    return parts.isEmpty ? 'No specific action recommended' : parts.join('. ');
  }

  String _buildExplanation(
    ValuePriority? appliedPriority,
    List<MatchedCriterion> matchedCriteria,
    DirectionalAttitude? attitude,
  ) {
    final parts = <String>[];

    if (appliedPriority != null) {
      parts.add(
          '${appliedPriority.higherValue} prioritized over ${appliedPriority.lowerValue} (rank ${appliedPriority.rank})');
    }

    if (matchedCriteria.isNotEmpty) {
      parts.add('${matchedCriteria.length} judgment criteria matched');
    }

    if (attitude != null) {
      parts.add('Directional attitude: ${attitude.posture}');
    }

    return parts.isEmpty ? 'No specific evaluation applied' : parts.join('. ');
  }

  bool _detectViolation(
    String prohibitionStatement,
    String contentLower,
    PhilosophyEvaluationContext context,
  ) {
    final statementLower = prohibitionStatement.toLowerCase();

    if (statementLower.contains('uncertain') &&
        statementLower.contains('certain')) {
      final certaintyMarkers = [
        'definitely',
        'absolutely',
        'certainly',
        'without doubt',
        'undeniably',
        'always',
        'never',
      ];
      return certaintyMarkers.any((m) => contentLower.contains(m));
    }

    if (statementLower.contains('hide') &&
        statementLower.contains('limitation')) {
      final hideMarkers = ['no limitation', 'perfect', 'flawless'];
      return hideMarkers.any((m) => contentLower.contains(m));
    }

    return false;
  }

  bool _checkProhibitionExceptions(
    Prohibition prohibition,
    PhilosophyEvaluationContext context,
  ) {
    if (prohibition.exceptions == null) return false;
    return prohibition.exceptions!.any((e) => _exceptionMatches(e, context));
  }

  bool _exceptionMatches(
    ProhibitionException exception,
    PhilosophyEvaluationContext context,
  ) {
    for (final entry in context.facts.entries) {
      if (exception.condition.contains(entry.key) &&
          exception.condition.contains(entry.value.toString())) {
        return true;
      }
    }
    return false;
  }

  double _evaluateConditions(
    List<String> conditions,
    PhilosophyEvaluationContext context,
  ) {
    if (conditions.isEmpty) return 0.0;

    int matchCount = 0;
    for (final condition in conditions) {
      if (_conditionMatches(condition, context)) {
        matchCount++;
      }
    }

    return matchCount / conditions.length;
  }

  bool _conditionMatches(
      String condition, PhilosophyEvaluationContext context) {
    final eqMatch = RegExp(r'(\w+)\s*==\s*"(\w+)"').firstMatch(condition);
    if (eqMatch != null) {
      final key = eqMatch.group(1)!;
      final value = eqMatch.group(2)!;
      return context.facts[key]?.toString() == value;
    }

    final ltMatch =
        RegExp(r'(\w+)\s*<\s*([\d.]+)').firstMatch(condition);
    if (ltMatch != null) {
      final key = ltMatch.group(1)!;
      final threshold = double.tryParse(ltMatch.group(2)!);
      final metricValue = context.metrics[key];
      if (threshold != null && metricValue != null) {
        return metricValue < threshold;
      }
    }

    final gtMatch =
        RegExp(r'(\w+)\s*>\s*([\d.]+)').firstMatch(condition);
    if (gtMatch != null) {
      final key = gtMatch.group(1)!;
      final threshold = double.tryParse(gtMatch.group(2)!);
      final metricValue = context.metrics[key];
      if (threshold != null && metricValue != null) {
        return metricValue > threshold;
      }
    }

    return false;
  }
}

/// Helper for creating ProhibitionCheckResult with computed violation data.
///
/// Dart extensions cannot add static/factory methods, so this utility class
/// provides the [withViolations] factory that mcp_bundle's contract type lacks.
class ProhibitionCheckResults {
  ProhibitionCheckResults._();

  /// Create a ProhibitionCheckResult with violations computed from checks.
  static ProhibitionCheckResult withViolations(List<ProhibitionCheck> checks) {
    final hardIds = checks
        .where((c) => c.violated && c.severity == ProhibitionSeverity.hard)
        .map((c) => c.prohibitionId)
        .toList();
    final softIds = checks
        .where((c) => c.violated && c.severity == ProhibitionSeverity.soft)
        .map((c) => c.prohibitionId)
        .toList();
    return ProhibitionCheckResult(
      checks: checks,
      hasHardViolation: hardIds.isNotEmpty,
      hardViolationIds: hardIds,
      softViolationIds: softIds,
    );
  }
}
