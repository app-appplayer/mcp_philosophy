import 'package:mcp_bundle/mcp_bundle.dart';

/// Detects and resolves conflicts between Philosophy and other layers.
///
/// Tension is not a bug — it is a design feature that enables human-like
/// decision-making where values, dispositions, and experiences interact
/// and sometimes conflict.
class TensionDetector {
  const TensionDetector();

  /// Detect all tensions between the Ethos and other layer states.
  List<Tension> detect(Ethos ethos, MultiLayerContext context) {
    final tensions = <Tension>[];

    if (context.hasProfileState) {
      tensions.addAll(_detectProfileTensions(ethos, context.profileState!));
    }

    if (context.hasKnowledgeProvenance) {
      tensions.addAll(
          _detectKnowledgeTensions(ethos, context.knowledgeProvenance!));
    }

    if (context.stateWeighting != null) {
      tensions.addAll(_detectStateTensions(
        ethos,
        context.stateWeighting!.map(
            (k, v) => MapEntry(k, v is num ? v.toDouble() : 0.5)),
      ));
    }

    tensions.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return tensions;
  }

  /// Resolve a detected tension using the specified strategy.
  TensionResolution resolve(Tension tension, {ResolutionStrategy? strategy}) {
    final effectiveStrategy = strategy ?? _selectDefaultStrategy(tension);

    return switch (effectiveStrategy) {
      ResolutionStrategy.philosophyWins => TensionResolution(
          tensionId: tension.id,
          strategy: ResolutionStrategy.philosophyWins,
          outcome:
              'Philosophy directive "${tension.philosophyDirective}" takes precedence',
          confidence: 0.85,
          adjustments: {'philosophyWeight': 1.0, 'opposingWeight': 0.2},
        ),
      ResolutionStrategy.compromise => TensionResolution(
          tensionId: tension.id,
          strategy: ResolutionStrategy.compromise,
          outcome:
              'Compromise between "${tension.philosophyDirective}" and "${tension.opposingDirective}"',
          confidence: 0.6,
          adjustments: {'philosophyWeight': 0.6, 'opposingWeight': 0.4},
        ),
      ResolutionStrategy.contextDependent => TensionResolution(
          tensionId: tension.id,
          strategy: ResolutionStrategy.contextDependent,
          outcome:
              'Context-dependent resolution applied to "${tension.philosophyDirective}" vs "${tension.opposingDirective}"',
          confidence: 0.65,
          adjustments: {'philosophyWeight': 0.5, 'opposingWeight': 0.5},
        ),
      ResolutionStrategy.defer => TensionResolution(
          tensionId: tension.id,
          strategy: ResolutionStrategy.defer,
          outcome: 'Tension deferred for human review',
          confidence: 0.0,
        ),
      ResolutionStrategy.unknown => TensionResolution(
          tensionId: tension.id,
          strategy: ResolutionStrategy.defer,
          outcome: 'Unknown strategy, deferred for review',
          confidence: 0.0,
        ),
    };
  }

  List<Tension> _detectProfileTensions(
    Ethos ethos,
    Map<String, dynamic> profileState,
  ) {
    final tensions = <Tension>[];
    final profilePosture = profileState['posture']?.toString();

    if (profilePosture == null) return tensions;

    for (final attitude in ethos.directionalAttitudes) {
      final isConflicting = _isPostureConflicting(
        attitude.posture,
        profilePosture,
      );

      if (isConflicting) {
        tensions.add(Tension(
          id: 'tension-phil-profile-${attitude.id}',
          source: TensionSource(
            opposingLayer: TensionLayer.profile,
            primaryComponentId: attitude.id,
          ),
          philosophyDirective: attitude.posture,
          opposingDirective: 'Profile posture: $profilePosture',
          severity: TensionSeverity.medium,
          description:
              'Philosophy attitude "${attitude.posture}" conflicts with profile posture "$profilePosture"',
          resolutionOptions: [
            const ResolutionOption(
              strategy: ResolutionStrategy.philosophyWins,
              description: 'Override profile posture',
              estimatedConfidence: 0.8,
            ),
            const ResolutionOption(
              strategy: ResolutionStrategy.compromise,
              description: 'Blend philosophy and profile',
              estimatedConfidence: 0.6,
            ),
            const ResolutionOption(
              strategy: ResolutionStrategy.contextDependent,
              description: 'Evaluate threat level first',
              estimatedConfidence: 0.65,
            ),
          ],
          ethosComponentId: attitude.id,
        ));
      }
    }

    if (ethos.valuePriorities.isNotEmpty && profilePosture == 'defensive') {
      final topPriority = ethos.topPriority!;
      if (topPriority.higherValue.toLowerCase().contains('collaborat') ||
          topPriority.higherValue.toLowerCase().contains('openness')) {
        tensions.add(Tension(
          id: 'tension-phil-profile-vp-${topPriority.id}',
          source: TensionSource(
            opposingLayer: TensionLayer.profile,
            primaryComponentId: topPriority.id,
          ),
          philosophyDirective: '${topPriority.higherValue} is important',
          opposingDirective:
              'Defensive posture due to ${profileState['reason'] ?? 'unknown reason'}',
          severity: TensionSeverity.medium,
          description:
              'Philosophy values ${topPriority.higherValue}, but profile has defensive posture',
          resolutionOptions: [
            const ResolutionOption(
              strategy: ResolutionStrategy.philosophyWins,
              description: 'Override defensive posture',
              estimatedConfidence: 0.8,
            ),
            const ResolutionOption(
              strategy: ResolutionStrategy.compromise,
              description: 'Collaborative but cautious',
              estimatedConfidence: 0.6,
            ),
            const ResolutionOption(
              strategy: ResolutionStrategy.contextDependent,
              description: 'Evaluate threat level first',
              estimatedConfidence: 0.65,
            ),
          ],
          ethosComponentId: topPriority.id,
        ));
      }
    }

    return tensions;
  }

  List<Tension> _detectKnowledgeTensions(
    Ethos ethos,
    Map<String, dynamic> provenance,
  ) {
    final tensions = <Tension>[];

    final trustScore = provenance['trust_score'];
    if (trustScore is num && trustScore < 0.3) {
      tensions.add(Tension(
        id: 'tension-phil-knowledge-trust',
        source: const TensionSource(
          opposingLayer: TensionLayer.knowledge,
        ),
        philosophyDirective: 'Philosophy principles guide interpretation',
        opposingDirective:
            'Knowledge provenance has low trust (${trustScore.toStringAsFixed(2)})',
        severity: TensionSeverity.low,
        description:
            'Knowledge provenance shows low trust, potentially conflicting with philosophical direction',
        resolutionOptions: [
          const ResolutionOption(
            strategy: ResolutionStrategy.philosophyWins,
            description: 'Maintain philosophical direction',
            estimatedConfidence: 0.7,
          ),
          const ResolutionOption(
            strategy: ResolutionStrategy.contextDependent,
            description: 'Evaluate evidence strength',
            estimatedConfidence: 0.6,
          ),
        ],
      ));
    }

    return tensions;
  }

  List<Tension> _detectStateTensions(
    Ethos ethos,
    Map<String, double> weighting,
  ) {
    final tensions = <Tension>[];
    final urgency = weighting['urgency'] ?? 0.5;
    final riskSensitivity = weighting['riskSensitivity'] ?? 0.5;

    if (ethos.valuePriorities.isNotEmpty) {
      final topPriority = ethos.topPriority!;
      final isAccuracyFirst = topPriority.higherValue
              .toLowerCase()
              .contains('accura') ||
          topPriority.higherValue.toLowerCase().contains('understanding') ||
          topPriority.higherValue.toLowerCase().contains('truthful');

      if (isAccuracyFirst && urgency > 0.8 && riskSensitivity < 0.3) {
        tensions.add(Tension(
          id: 'tension-phil-state-urgency',
          source: TensionSource(
            opposingLayer: TensionLayer.state,
            primaryComponentId: topPriority.id,
          ),
          philosophyDirective:
              '${topPriority.higherValue} over ${topPriority.lowerValue}',
          opposingDirective:
              'High urgency ($urgency) with low risk sensitivity ($riskSensitivity)',
          severity: TensionSeverity.low,
          description:
              'Philosophy emphasizes ${topPriority.higherValue} but state indicates high urgency',
          resolutionOptions: [
            const ResolutionOption(
              strategy: ResolutionStrategy.compromise,
              description: 'Maintain direction but adjust execution tempo',
              estimatedConfidence: 0.7,
            ),
          ],
          ethosComponentId: topPriority.id,
        ));
      }
    }

    return tensions;
  }

  bool _isPostureConflicting(String philosophyPosture, String profilePosture) {
    final collaborative = ['collaborate', 'open', 'inclusive', 'understanding'];
    final defensive = ['defensive', 'guarded', 'protective', 'cautious'];

    final philLower = philosophyPosture.toLowerCase();
    final profLower = profilePosture.toLowerCase();

    final philIsCollaborative =
        collaborative.any((c) => philLower.contains(c));
    final profIsDefensive = defensive.any((d) => profLower.contains(d));

    return philIsCollaborative && profIsDefensive;
  }

  ResolutionStrategy _selectDefaultStrategy(Tension tension) {
    return switch (tension.severity) {
      TensionSeverity.critical => ResolutionStrategy.philosophyWins,
      TensionSeverity.high => ResolutionStrategy.philosophyWins,
      TensionSeverity.medium => ResolutionStrategy.contextDependent,
      TensionSeverity.low => ResolutionStrategy.compromise,
      TensionSeverity.unknown => ResolutionStrategy.defer,
    };
  }
}
