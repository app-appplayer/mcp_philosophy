import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('FeedbackEvent', () {
    test('constructs with required fields', () {
      final fe = testFeedbackEvent();
      expect(fe.id, 'fb-1');
      expect(fe.actionId, 'act-1');
      expect(fe.ethosId, 'test-ethos-001');
      expect(fe.outcomeScore, 0.8);
    });

    test('outcomeScore stores value as-is (no clamping at contract layer)', () {
      final fe = testFeedbackEvent(outcomeScore: 2.0);
      expect(fe.outcomeScore, 2.0);

      final fe2 = testFeedbackEvent(id: 'fb-2', outcomeScore: -2.0);
      expect(fe2.outcomeScore, -2.0);
    });

    test('hasValuePriorityLink returns true when set', () {
      final fe = testFeedbackEvent(valuePriorityId: 'vp-1');
      expect(fe.hasValuePriorityLink, isTrue);
    });

    test('hasValuePriorityLink returns false when null', () {
      final fe = testFeedbackEvent(valuePriorityId: null);
      expect(fe.hasValuePriorityLink, isFalse);
    });

    test('isPositive/isNegative', () {
      final positive = testFeedbackEvent(outcome: FeedbackOutcome.positive);
      expect(positive.isPositive, isTrue);
      expect(positive.isNegative, isFalse);

      final negative = testFeedbackEvent(
        id: 'fb-2',
        outcome: FeedbackOutcome.negative,
        outcomeScore: -0.5,
      );
      expect(negative.isNegative, isTrue);
      expect(negative.isPositive, isFalse);
    });

    // TC-179a: isPositive returns false for neutral/mixed outcomes
    test('isPositive returns false for neutral and mixed outcomes', () {
      final neutral = testFeedbackEvent(
          id: 'n', outcome: FeedbackOutcome.neutral, outcomeScore: 0);
      expect(neutral.isPositive, isFalse);

      final mixed = testFeedbackEvent(
          id: 'm', outcome: FeedbackOutcome.mixed, outcomeScore: 0.1);
      expect(mixed.isPositive, isFalse);
    });

    // TC-180a: isNegative returns false for positive/neutral/mixed outcomes
    test('isNegative returns false for positive, neutral, and mixed outcomes',
        () {
      final pos = testFeedbackEvent(outcome: FeedbackOutcome.positive);
      final neu = testFeedbackEvent(
          id: 'n', outcome: FeedbackOutcome.neutral, outcomeScore: 0);
      final mix = testFeedbackEvent(
          id: 'm', outcome: FeedbackOutcome.mixed, outcomeScore: 0.1);
      expect(pos.isNegative, isFalse);
      expect(neu.isNegative, isFalse);
      expect(mix.isNegative, isFalse);
    });

    test('validate() throws ArgumentError when id is empty', () {
      expect(() => testFeedbackEvent(id: '').validate(), throwsArgumentError);
    });

    test('validate() throws ArgumentError when actionId is empty', () {
      expect(
          () => testFeedbackEvent(actionId: '').validate(), throwsArgumentError);
    });

    test('validate() throws ArgumentError when ethosId is empty', () {
      expect(
          () => testFeedbackEvent(ethosId: '').validate(), throwsArgumentError);
    });

    // TC-184c: validate succeeds for minimally valid event
    test('validate() succeeds for minimally valid event', () {
      final fe = testFeedbackEvent();
      expect(() => fe.validate(), returnsNormally);
    });

    test('toJson/fromJson round-trip', () {
      final fe = testFeedbackEvent();
      final json = fe.toJson();
      final restored = FeedbackEvent.fromJson(json);
      expect(restored.id, fe.id);
      expect(restored.actionId, fe.actionId);
      expect(restored.ethosId, fe.ethosId);
      expect(restored.valuePriorityId, fe.valuePriorityId);
      expect(restored.outcome, fe.outcome);
      expect(restored.outcomeScore, fe.outcomeScore);
    });

    // TC-185a: copyWith preserves unmodified fields
    test('copyWith modifies outcomeScore and preserves other fields', () {
      final fe = testFeedbackEvent();
      final copied = fe.copyWith(outcomeScore: 0.5);
      expect(copied.outcomeScore, 0.5);
      expect(copied.id, fe.id);
      expect(copied.actionId, fe.actionId);
      expect(copied.ethosId, fe.ethosId);
    });

    // TC-185b: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final fe = testFeedbackEvent();
      final copied = fe.copyWith();
      expect(copied.id, fe.id);
      expect(copied.actionId, fe.actionId);
      expect(copied.ethosId, fe.ethosId);
      expect(copied.outcome, fe.outcome);
      expect(copied.outcomeScore, fe.outcomeScore);
    });

    // TC-185c: copyWith replaces outcome when provided
    test('copyWith replaces outcome when provided', () {
      final fe = testFeedbackEvent(outcome: FeedbackOutcome.positive);
      final copied = fe.copyWith(outcome: FeedbackOutcome.negative);
      expect(copied.outcome, FeedbackOutcome.negative);
      expect(copied.id, fe.id);
    });

    test('equality by id', () {
      final a = testFeedbackEvent(id: 'same');
      final b = testFeedbackEvent(id: 'same', outcomeScore: 0.1);
      expect(a.id, equals(b.id));
    });
  });

  group('FeedbackOutcome', () {
    test('fromString falls back to unknown', () {
      expect(
        FeedbackOutcome.fromString('nonexistent'),
        FeedbackOutcome.unknown,
      );
    });
  });
}
