import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  late PhilosophyEvaluator evaluator;
  late Ethos ethos;

  setUp(() {
    evaluator = const PhilosophyEvaluator();
    ethos = fullTestEthos();
  });

  group('PhilosophyEvaluator', () {
    group('evaluate', () {
      test('produces guidance with all fields', () {
        final context = testContext(
          facts: {'score_trend': 'declining', 'risk': 'moderate'},
          metrics: {'evidence_sufficiency': 0.7},
        );

        final guidance = evaluator.evaluate(ethos, context);

        expect(guidance.valuePriorityApplied, isNotNull);
        expect(guidance.prohibitionChecks, isNotNull);
        expect(guidance.confidence, greaterThanOrEqualTo(0.0));
        expect(guidance.confidence, lessThanOrEqualTo(1.0));
        expect(guidance.recommendedAction, isNotEmpty);
        expect(guidance.explanation, isNotEmpty);
      });

      test('returns highest-rank value priority', () {
        final context = testContext();
        final guidance = evaluator.evaluate(ethos, context);
        expect(guidance.valuePriorityApplied!.rank, 1);
      });

      test('no prohibition violated when no content to check', () {
        final context = testContext();
        final guidance = evaluator.evaluate(ethos, context);
        expect(guidance.prohibitionViolated, isFalse);
        expect(guidance.allowsProceeding, isTrue);
      });
    });

    group('checkProhibitions', () {
      test('detects hard prohibition violation with certainty language', () {
        final context = testContext(
          proposedOutput: 'This is definitely the correct answer',
        );

        final result = evaluator.checkProhibitions(
          ethos.prohibitions,
          context,
        );

        expect(result.hasHardViolation, isTrue);
        expect(result.hardViolationIds, contains('proh-1'));
      });

      test('passes when no violation detected', () {
        final context = testContext(
          proposedOutput: 'This might be the answer',
        );

        final result = evaluator.checkProhibitions(
          ethos.prohibitions,
          context,
        );

        expect(result.hasHardViolation, isFalse);
      });

      test('passes when no content to check', () {
        final context = testContext();

        final result = evaluator.checkProhibitions(
          ethos.prohibitions,
          context,
        );

        expect(result.hasHardViolation, isFalse);
        expect(result.checks, hasLength(ethos.prohibitions.length));
      });

      // TC-060a: empty prohibitions list returns empty checks
      test('empty prohibitions list returns empty checks', () {
        final result = evaluator.checkProhibitions([], testContext());
        expect(result.checks, isEmpty);
        expect(result.hasHardViolation, isFalse);
      });

      test('detects soft violation separately from hard', () {
        final context = testContext(
          proposedOutput: 'This is definitely correct',
        );

        final result = evaluator.checkProhibitions(
          ethos.prohibitions,
          context,
        );

        expect(result.hardViolationIds, isNotEmpty);
        // Soft prohibition about jargon should not trigger on this content
      });

      test('applies exception when context matches', () {
        final prohibitions = [
          testProhibition(
            id: 'proh-ex',
            statement: 'Never present uncertain information as certain',
            exceptions: [
              const ProhibitionException(
                condition: 'domain == "emergency_triage"',
                justificationRequired: 'Life-critical',
              ),
            ],
          ),
        ];

        final context = testContext(
          facts: {'domain': 'emergency_triage'},
          proposedOutput: 'This is definitely the correct treatment',
        );

        final result = evaluator.checkProhibitions(prohibitions, context);
        final check = result.checks.first;
        expect(check.exceptionApplied, isTrue);
        expect(check.violated, isFalse);
      });
    });

    group('matchCriteria', () {
      test('matches criteria when conditions match context', () {
        final context = testContext(
          facts: {'risk': 'high'},
          metrics: {'evidence_sufficiency': 0.3},
        );

        final matched = evaluator.matchCriteria(
          ethos.judgmentCriteria,
          context,
        );

        expect(matched, isNotEmpty);
        expect(matched.first.matchStrength, greaterThan(0.0));
      });

      test('does not match when conditions do not match', () {
        final context = testContext(
          facts: {'risk': 'low'},
          metrics: {'evidence_sufficiency': 0.9},
        );

        final matched = evaluator.matchCriteria(
          ethos.judgmentCriteria,
          context,
        );

        expect(matched, isEmpty);
      });

      test('detects conflicts between matched criteria', () {
        final criteria = [
          testCriterion(
            id: 'jc-a',
            conditions: ['risk == "high"'],
            preferredAction: 'Action A',
          ),
          testCriterion(
            id: 'jc-b',
            conditions: ['risk == "high"'],
            preferredAction: 'Action B',
          ),
        ];

        final context = testContext(facts: {'risk': 'high'});
        final matched = evaluator.matchCriteria(criteria, context);

        expect(matched, hasLength(2));
        expect(matched.any((m) => m.hasConflict), isTrue);
      });

      test('sorts by match strength descending', () {
        final criteria = [
          testCriterion(
            id: 'jc-a',
            conditions: ['risk == "high"', 'nonexistent == "x"'],
            preferredAction: 'Action A',
          ),
          testCriterion(
            id: 'jc-b',
            conditions: ['risk == "high"'],
            preferredAction: 'Action A',
          ),
        ];

        final context = testContext(facts: {'risk': 'high'});
        final matched = evaluator.matchCriteria(criteria, context);

        expect(matched.length, 2);
        expect(matched.first.matchStrength,
            greaterThanOrEqualTo(matched.last.matchStrength));
      });
    });

    group('resolveConflict', () {
      test('lower rank wins by default', () {
        final a = testValuePriority(id: 'vp-a', rank: 1);
        final b = testValuePriority(id: 'vp-b', rank: 2);

        final resolution = evaluator.resolveConflict(a, b, testContext());
        expect(resolution.winner.id, 'vp-a');
        expect(resolution.loser?.id, 'vp-b');
        expect(resolution.contextDependent, isFalse);
      });

      // TC-076a: equal ranks resolved deterministically (first arg wins)
      test('equal ranks resolved deterministically (first argument wins)', () {
        final a = testValuePriority(id: 'vp-a', rank: 3);
        final b = testValuePriority(id: 'vp-b', rank: 3);

        final resolution = evaluator.resolveConflict(a, b, testContext());
        expect(resolution.winner.id, 'vp-a');
        expect(resolution.loser?.id, 'vp-b');
      });
    });

    group('confidence scoring', () {
      test('confidence is between 0.0 and 1.0', () {
        final context = testContext(
          facts: {'risk': 'high'},
          metrics: {'evidence_sufficiency': 0.3},
        );

        final guidance = evaluator.evaluate(ethos, context);
        expect(guidance.confidence, greaterThanOrEqualTo(0.0));
        expect(guidance.confidence, lessThanOrEqualTo(1.0));
      });

      test('hard violation reduces confidence significantly', () {
        final contextNoViolation = testContext(
          proposedOutput: 'This might be true',
          facts: {'risk': 'low'},
        );
        final contextWithViolation = testContext(
          proposedOutput: 'This is definitely true',
          facts: {'risk': 'low'},
        );

        final guidanceClean =
            evaluator.evaluate(ethos, contextNoViolation);
        final guidanceDirty =
            evaluator.evaluate(ethos, contextWithViolation);

        expect(guidanceDirty.confidence,
            lessThan(guidanceClean.confidence));
      });
    });
  });

  group('EvaluationContext', () {
    test('constructs with required fields', () {
      final ctx = testContext();
      expect(ctx.contextId, 'ctx-1');
    });

    test('validate() throws ArgumentError for empty contextId', () {
      expect(
        () => testContext(contextId: '').validate(),
        throwsArgumentError,
      );
    });

    // TC-089f: validate succeeds for minimally valid context
    test('validate() succeeds for minimally valid context', () {
      final ctx = testContext();
      expect(() => ctx.validate(), returnsNormally);
    });

    test('getFact returns value', () {
      final ctx = testContext(facts: {'key': 'value'});
      expect(ctx.getFact('key'), 'value');
      expect(ctx.getFact('missing'), isNull);
    });

    test('getMetric returns value', () {
      final ctx = testContext(metrics: {'score': 0.5});
      expect(ctx.getMetric('score'), 0.5);
      expect(ctx.getMetric('missing'), isNull);
    });

    test('hasProposedOutput', () {
      expect(testContext().hasProposedOutput, isFalse);
      expect(
        testContext(proposedOutput: 'text').hasProposedOutput,
        isTrue,
      );
    });

    test('toJson/fromJson round-trip', () {
      final ctx = testContext(
        facts: {'key': 'value'},
        metrics: {'score': 0.5},
        proposedAction: 'action',
      );
      final json = ctx.toJson();
      final restored = EvaluationContext.fromJson(json);
      expect(restored.contextId, ctx.contextId);
      expect(restored.facts['key'], 'value');
      expect(restored.metrics['score'], 0.5);
      expect(restored.proposedAction, 'action');
    });

    // TC-089b: copyWith preserves unmodified fields
    test('copyWith preserves unmodified fields', () {
      final ctx = testContext(facts: {'k': 'v'});
      final copied = ctx.copyWith(contextId: 'new-id');
      expect(copied.contextId, 'new-id');
      expect(copied.facts, ctx.facts);
      expect(copied.metrics, ctx.metrics);
    });

    // TC-089d: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final ctx = testContext(
        facts: {'k': 'v'},
        metrics: {'m': 1.0},
        proposedAction: 'act',
      );
      final copied = ctx.copyWith();
      expect(copied.contextId, ctx.contextId);
      expect(copied.facts, ctx.facts);
      expect(copied.metrics, ctx.metrics);
      expect(copied.proposedAction, ctx.proposedAction);
    });

    // TC-089e: copyWith replaces facts map when provided
    test('copyWith replaces facts map when provided', () {
      final ctx = testContext(facts: {'original': 'val'});
      final copied = ctx.copyWith(facts: {'new-key': 'new-val'});
      expect(copied.facts, {'new-key': 'new-val'});
      expect(copied.contextId, ctx.contextId);
    });
  });
}
