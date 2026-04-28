import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('JudgmentCriterion', () {
    // TC-040: Construction
    test('constructs with required fields', () {
      final jc = testCriterion();
      expect(jc.id, 'jc-1');
      expect(jc.conditions, ['risk == "high"']);
      expect(jc.preferredAction, 'Conservative approach');
    });

    // TC-040a: construction with empty conditions (no constructor validation)
    test('construction with empty conditions list succeeds (no constructor validation)',
        () {
      final jc = testCriterion(conditions: []);
      expect(jc.conditions, isEmpty);
    });

    // TC-041: JSON round-trip
    test('toJson/fromJson round-trip', () {
      final jc = testCriterion(
        fallbackStrategy: 'Present known facts only',
      );
      final json = jc.toJson();
      final restored = JudgmentCriterion.fromJson(json);
      expect(restored.id, jc.id);
      expect(restored.conditions, jc.conditions);
      expect(restored.preferredAction, jc.preferredAction);
      expect(restored.fallbackStrategy, jc.fallbackStrategy);
    });

    // TC-042: hasFallback
    test('hasFallback returns true when fallbackStrategy present', () {
      final jc = testCriterion(fallbackStrategy: 'Fallback');
      expect(jc.hasFallback, isTrue);
    });

    test('hasFallback returns false when no fallbackStrategy', () {
      final jc = testCriterion();
      expect(jc.hasFallback, isFalse);
    });

    // TC-042b: hasFallback returns false when null
    test('hasFallback returns false when fallbackStrategy is null', () {
      final jc = testCriterion();
      expect(jc.hasFallback, isFalse);
    });

    // TC-043: requiresValidation
    test('requiresValidation returns true when requiredValidation present', () {
      final jc = JudgmentCriterion(
        id: 'jc-1',
        conditions: ['test'],
        preferredAction: 'Action',
        requiredValidation: 'Validate this',
      );
      expect(jc.requiresValidation, isTrue);
    });

    // TC-043b: requiresValidation returns false when null
    test('requiresValidation returns false when requiredValidation is null',
        () {
      final jc = testCriterion();
      expect(jc.requiresValidation, isFalse);
    });

    // TC-042a: validate throws on empty id
    test('validate() throws ArgumentError when id is empty', () {
      expect(
        () => testCriterion(id: '').validate(),
        throwsArgumentError,
      );
    });

    // TC-042c: validate succeeds for minimally valid criterion
    test('validate() succeeds for minimally valid criterion', () {
      final jc = testCriterion();
      expect(() => jc.validate(), returnsNormally);
    });

    // TC-043a: copyWith preserves unmodified fields
    test('copyWith modifies fields and preserves others', () {
      final jc = testCriterion();
      final copied = jc.copyWith(preferredAction: 'New action');
      expect(copied.preferredAction, 'New action');
      expect(copied.id, jc.id);
      expect(copied.conditions, jc.conditions);
    });

    // TC-043c: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final jc = testCriterion(fallbackStrategy: 'fallback');
      final copied = jc.copyWith();
      expect(copied.id, jc.id);
      expect(copied.conditions, jc.conditions);
      expect(copied.preferredAction, jc.preferredAction);
      expect(copied.fallbackStrategy, jc.fallbackStrategy);
    });

    // TC-043d: copyWith replaces conditions list when provided
    test('copyWith replaces conditions list when provided', () {
      final jc = testCriterion();
      final copied = jc.copyWith(conditions: ['new-cond']);
      expect(copied.conditions, ['new-cond']);
      expect(copied.id, jc.id);
    });
  });
}
