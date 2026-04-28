import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('ValuePriority', () {
    // TC-024: Construction with all fields
    test('constructs with all fields', () {
      final vp = testValuePriority(
        conditions: ['emergency'],
      );
      expect(vp.id, 'vp-1');
      expect(vp.rank, 1);
      expect(vp.higherValue, 'Understanding');
      expect(vp.lowerValue, 'Speed');
      expect(vp.conditions, ['emergency']);
    });

    // TC-024a: Construction with empty id succeeds (no constructor validation)
    test('construction with empty id succeeds (no constructor validation)',
        () {
      final vp = testValuePriority(id: '');
      expect(vp.id, '');
    });

    // TC-026a: display with empty strings returns " > "
    test('display with empty strings returns " > " (no crash)', () {
      final vp = testValuePriority(higherValue: '', lowerValue: '');
      expect(vp.display, ' > ');
    });

    // TC-025: JSON round-trip
    test('toJson/fromJson round-trip', () {
      final vp = testValuePriority(conditions: ['context_a']);
      final json = vp.toJson();
      final restored = ValuePriority.fromJson(json);
      expect(restored.id, vp.id);
      expect(restored.rank, vp.rank);
      expect(restored.higherValue, vp.higherValue);
      expect(restored.lowerValue, vp.lowerValue);
      expect(restored.rationale, vp.rationale);
      expect(restored.conditions, vp.conditions);
    });

    // TC-026: display
    test('display returns "higherValue > lowerValue"', () {
      final vp = testValuePriority();
      expect(vp.display, 'Understanding > Speed');
    });

    // TC-027: isConditional true
    test('isConditional returns true when conditions present', () {
      final vp = testValuePriority(conditions: ['emergency']);
      expect(vp.isConditional, isTrue);
    });

    // TC-028: isConditional false
    test('isConditional returns false when conditions is null', () {
      final vp = testValuePriority();
      expect(vp.isConditional, isFalse);
    });

    test('isConditional returns false when conditions is empty', () {
      final vp = testValuePriority(conditions: []);
      expect(vp.isConditional, isFalse);
    });

    // TC-029: rank <= 0 (validate() extension)
    test('validate() throws ArgumentError when rank is 0', () {
      expect(
        () => testValuePriority(rank: 0).validate(),
        throwsArgumentError,
      );
    });

    test('validate() throws ArgumentError when rank is negative', () {
      expect(
        () => testValuePriority(rank: -1).validate(),
        throwsArgumentError,
      );
    });

    // TC-030: empty id (validate() extension)
    test('validate() throws ArgumentError when id is empty', () {
      expect(
        () => testValuePriority(id: '').validate(),
        throwsArgumentError,
      );
    });

    // TC-030a: copyWith preserves unmodified fields
    test('copyWith modifies rank and preserves unmodified fields', () {
      final vp = testValuePriority(rank: 1);
      final copied = vp.copyWith(rank: 2);
      expect(copied.rank, 2);
      expect(copied.id, vp.id);
      expect(copied.higherValue, vp.higherValue);
      expect(copied.lowerValue, vp.lowerValue);
      expect(copied.rationale, vp.rationale);
    });

    // TC-030b: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final vp = testValuePriority(conditions: ['ctx-a']);
      final copied = vp.copyWith();
      expect(copied.id, vp.id);
      expect(copied.rank, vp.rank);
      expect(copied.higherValue, vp.higherValue);
      expect(copied.lowerValue, vp.lowerValue);
      expect(copied.conditions, vp.conditions);
    });

    // TC-030c: copyWith replaces conditions list when provided
    test('copyWith replaces conditions list when provided', () {
      final vp = testValuePriority(conditions: ['original']);
      final copied = vp.copyWith(conditions: ['replaced']);
      expect(copied.conditions, ['replaced']);
      expect(copied.id, vp.id);
    });

    test('equality by id, rank, higherValue, lowerValue', () {
      final a = testValuePriority();
      final b = testValuePriority();
      expect(a.id, equals(b.id));
      expect(a.rank, equals(b.rank));
      expect(a.higherValue, equals(b.higherValue));
      expect(a.lowerValue, equals(b.lowerValue));
    });
  });
}
