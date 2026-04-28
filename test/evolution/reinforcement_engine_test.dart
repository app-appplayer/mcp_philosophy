import 'dart:math' as math;

import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  const engine = ReinforcementEngine();

  List<FeedbackEvent> makeHistory(List<double> scores) {
    return scores
        .asMap()
        .entries
        .map((e) => testFeedbackEvent(
              id: 'fb-${e.key}',
              actionId: 'act-${e.key}',
              outcomeScore: e.value,
              outcome:
                  e.value > 0 ? FeedbackOutcome.positive : FeedbackOutcome.negative,
            ))
        .toList();
  }

  group('ReinforcementEngine', () {
    test('returns null when insufficient feedback (< 3)', () {
      final event = testFeedbackEvent(id: 'fb-new');
      final history = makeHistory([0.8]);

      final result = engine.analyzeFeedback(event, history, testEthos());
      expect(result, isNull);
    });

    test('returns null when pattern strength below threshold', () {
      // Mixed scores should produce low pattern strength
      final event = testFeedbackEvent(
        id: 'fb-new',
        outcomeScore: 0.1,
        outcome: FeedbackOutcome.neutral,
      );
      final history = makeHistory([0.1, -0.1, 0.1]);

      final result = engine.analyzeFeedback(event, history, testEthos());
      expect(result, isNull);
    });

    test('generates reinforce proposal for consistent positive feedback', () {
      final event = testFeedbackEvent(
        id: 'fb-new',
        outcomeScore: 0.8,
      );
      final history = makeHistory([0.8, 0.7, 0.9]);

      final result = engine.analyzeFeedback(event, history, testEthos());
      expect(result, isNotNull);
      expect(result!.type, EvolutionType.reinforce);
      expect(result.status, ProposalStatus.pending);
      expect(result.targetComponentId, 'vp-1');
      expect(result.targetComponentType, 'valuePriority');
    });

    test('generates weaken proposal for consistent negative feedback', () {
      final event = testFeedbackEvent(
        id: 'fb-new',
        outcomeScore: -0.9,
        outcome: FeedbackOutcome.negative,
      );
      final history = makeHistory([-0.8, -0.85, -0.9]);

      final result = engine.analyzeFeedback(event, history, testEthos());
      expect(result, isNotNull);
      expect(result!.type, EvolutionType.weaken);
      expect(result.status, ProposalStatus.pending);
    });

    test('proposal status is always pending (never auto-applied)', () {
      final event = testFeedbackEvent(id: 'fb-new', outcomeScore: 0.9);
      final history = makeHistory([0.9, 0.9, 0.9]);

      final result = engine.analyzeFeedback(event, history, testEthos());
      expect(result, isNotNull);
      expect(result!.status, ProposalStatus.pending);
    });

    test('confidence increases with sample size', () {
      final event = testFeedbackEvent(id: 'fb-new', outcomeScore: 0.8);

      // Small sample
      final historySmall = makeHistory([0.8, 0.7, 0.9]);
      final resultSmall =
          engine.analyzeFeedback(event, historySmall, testEthos());

      // Large sample
      final historyLarge = makeHistory([0.8, 0.7, 0.9, 0.8, 0.7, 0.85, 0.75]);
      final resultLarge =
          engine.analyzeFeedback(event, historyLarge, testEthos());

      if (resultSmall != null && resultLarge != null) {
        expect(resultLarge.confidence,
            greaterThanOrEqualTo(resultSmall.confidence));
      }
    });

    group('pattern detection algorithm', () {
      test('matches documented calculation example', () {
        // From DDD feat-evolution Section 4.2:
        // Scores: [0.8, 0.7, 0.9, 0.6]
        // avgScore = 0.75
        // stdDev = 0.112
        // consistency = 1.0 - 0.224 = 0.776
        // strength = 0.776 * 0.75 = 0.582
        // sampleBonus = (4-3)*0.05 = 0.05
        // finalStrength = 0.632
        final event = testFeedbackEvent(id: 'fb-4', outcomeScore: 0.6);
        final history = [
          testFeedbackEvent(id: 'fb-1', actionId: 'a1', outcomeScore: 0.8),
          testFeedbackEvent(id: 'fb-2', actionId: 'a2', outcomeScore: 0.7),
          testFeedbackEvent(id: 'fb-3', actionId: 'a3', outcomeScore: 0.9),
        ];

        final result = engine.analyzeFeedback(event, history, testEthos());

        // Pattern strength should be ~0.632 which is >= 0.6 threshold
        expect(result, isNotNull);

        // Verify proposal confidence matches formula:
        // proposalConfidence = patternStrength * 0.8 + sampleSizeFactor * 0.2
        // sampleSizeFactor = 4/10 = 0.4
        // ~0.632 * 0.8 + 0.4 * 0.2 = ~0.586
        final scores = [0.8, 0.7, 0.9, 0.6];
        final avgScore =
            scores.reduce((a, b) => a + b) / scores.length;
        final variance = scores
                .map((s) => math.pow(s - avgScore, 2))
                .reduce((a, b) => a + b) /
            scores.length;
        final stdDev = math.sqrt(variance);
        final consistency = 1.0 - (stdDev / 0.5).clamp(0.0, 1.0);
        final strength = consistency * avgScore.abs();
        final sampleBonus = ((4 - 3) * 0.05).clamp(0.0, 0.15);
        final finalStrength = (strength + sampleBonus).clamp(0.0, 1.0);
        final sampleSizeFactor = (4 / 10.0).clamp(0.0, 1.0);
        final expectedConfidence =
            (finalStrength * 0.8 + sampleSizeFactor * 0.2).clamp(0.0, 1.0);

        expect(result!.confidence, closeTo(expectedConfidence, 0.01));
      });
    });

    test('finds related feedback by valuePriorityId', () {
      final event = testFeedbackEvent(
        id: 'fb-new',
        valuePriorityId: 'vp-1',
        outcomeScore: 0.8,
      );
      // Mix of related and unrelated feedback
      final history = [
        testFeedbackEvent(
          id: 'fb-1',
          actionId: 'a1',
          valuePriorityId: 'vp-1',
          outcomeScore: 0.9,
        ),
        testFeedbackEvent(
          id: 'fb-2',
          actionId: 'a2',
          valuePriorityId: 'vp-2', // different VP
          outcomeScore: -0.5,
        ),
        testFeedbackEvent(
          id: 'fb-3',
          actionId: 'a3',
          valuePriorityId: 'vp-1',
          outcomeScore: 0.7,
        ),
      ];

      final result = engine.analyzeFeedback(event, history, testEthos());
      // Should find 3 related events (fb-1, fb-3, fb-new) = exactly minFeedbackCount
      expect(result, isNotNull);
      expect(result!.type, EvolutionType.reinforce);
    });
  });

  group('ReinforcementPattern', () {
    test('toJson/fromJson round-trip', () {
      const pattern = ReinforcementPattern(
        componentId: 'vp-1',
        direction: PatternDirection.reinforcing,
        strength: 0.85,
        sampleSize: 5,
        averageOutcomeScore: 0.75,
      );
      final json = pattern.toJson();
      final restored = ReinforcementPattern.fromJson(json);
      expect(restored.componentId, 'vp-1');
      expect(restored.direction, PatternDirection.reinforcing);
      expect(restored.strength, 0.85);
      expect(restored.sampleSize, 5);
    });

    // TC-203a: construction with out-of-range strength succeeds (no constructor validation)
    test('construction with strength > 1.0 succeeds (no constructor validation)',
        () {
      const pattern = ReinforcementPattern(
        componentId: 'vp-1',
        direction: PatternDirection.mixed,
        strength: 1.5,
        sampleSize: 3,
        averageOutcomeScore: 0.5,
      );
      expect(pattern.strength, 1.5);
    });

    // TC-203b: fromJson throws on malformed JSON (missing direction)
    test('fromJson throws on malformed JSON (missing direction)', () {
      expect(
        () => ReinforcementPattern.fromJson(const {
          'componentId': 'vp-1',
          'strength': 0.5,
          'sampleSize': 3,
          'averageOutcomeScore': 0.5,
        }),
        throwsA(anyOf(isA<TypeError>(), isA<FormatException>())),
      );
    });
  });

  group('PatternDirection', () {
    // TC-204b: fromString returns correct enum for each direction
    test('fromString returns correct enum value', () {
      expect(PatternDirection.fromString('reinforcing'),
          PatternDirection.reinforcing);
      expect(PatternDirection.fromString('weakening'),
          PatternDirection.weakening);
      expect(PatternDirection.fromString('mixed'), PatternDirection.mixed);
    });

    // TC-204c: fromString falls back to unknown
    test('fromString falls back to unknown for unrecognized value', () {
      expect(PatternDirection.fromString('x'), PatternDirection.unknown);
    });

    // TC-204d: fromString is case-sensitive
    test('fromString is case-sensitive (mixed case returns unknown)', () {
      expect(PatternDirection.fromString('Reinforcing'),
          PatternDirection.unknown);
      expect(PatternDirection.fromString('REINFORCING'),
          PatternDirection.unknown);
    });
  });

  group('EvolutionRecord', () {
    // TC-209a: construction with null reviewerNote succeeds
    test('construction with null reviewerNote succeeds', () {
      final proposal = EvolutionProposal(
        id: 'p-1',
        ethosId: 'e-1',
        type: EvolutionType.reinforce,
        targetComponentId: 'vp-1',
        targetComponentType: 'valuePriority',
        description: 'Reinforce',
        rationale: 'test',
        supportingFeedbackIds: const ['fb-1', 'fb-2', 'fb-3'],
        confidence: 0.8,
        status: ProposalStatus.pending,
      );
      final record = EvolutionRecord(
        id: 'rec-1',
        ethosId: 'e-1',
        proposal: proposal,
        finalStatus: ProposalStatus.rejected,
      );
      expect(record.reviewerNote, isNull);
    });

    // TC-209b: fromJson throws on malformed JSON (missing proposal)
    test('fromJson throws on malformed JSON (missing proposal)', () {
      expect(
        () => EvolutionRecord.fromJson(const {
          'id': 'rec-1',
          'ethosId': 'e-1',
          'finalStatus': 'approved',
        }),
        throwsA(anyOf(isA<TypeError>(), isA<FormatException>())),
      );
    });
  });
}
