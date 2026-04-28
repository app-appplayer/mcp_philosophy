import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Prohibition', () {
    // TC-031: hard severity
    test('constructs with severity=hard', () {
      final p = testProhibition(severity: ProhibitionSeverity.hard);
      expect(p.severity, ProhibitionSeverity.hard);
      expect(p.isHard, isTrue);
    });

    // TC-031a: construction with empty statement (no constructor validation)
    test('construction with empty statement succeeds (no constructor validation)',
        () {
      final p = testProhibition(statement: '');
      expect(p.statement, '');
    });

    // TC-032: soft severity
    test('constructs with severity=soft', () {
      final p = testProhibition(severity: ProhibitionSeverity.soft);
      expect(p.severity, ProhibitionSeverity.soft);
      expect(p.isHard, isFalse);
    });

    // TC-033: JSON round-trip
    test('toJson/fromJson round-trip', () {
      final p = testProhibition(
        exceptions: [
          const ProhibitionException(
            condition: 'emergency',
            justificationRequired: 'Life-critical',
          ),
        ],
      );
      final json = p.toJson();
      final restored = Prohibition.fromJson(json);
      expect(restored.id, p.id);
      expect(restored.statement, p.statement);
      expect(restored.severity, p.severity);
      expect(restored.exceptions, hasLength(1));
    });

    // TC-034: isHard
    test('isHard returns true for hard severity', () {
      final p = testProhibition(severity: ProhibitionSeverity.hard);
      expect(p.isHard, isTrue);
    });

    // TC-034a: isHard returns false for soft severity
    test('isHard returns false for soft severity', () {
      final p = testProhibition(severity: ProhibitionSeverity.soft);
      expect(p.isHard, isFalse);
    });

    // TC-035: hasExceptions true
    test('hasExceptions returns true when exceptions present', () {
      final p = testProhibition(
        exceptions: [
          const ProhibitionException(
            condition: 'emergency',
            justificationRequired: 'Required',
          ),
        ],
      );
      expect(p.hasExceptions, isTrue);
    });

    // TC-036: hasExceptions false
    test('hasExceptions returns false when no exceptions', () {
      final p = testProhibition();
      expect(p.hasExceptions, isFalse);
    });

    // TC-037: hasApplicableException
    test('hasApplicableException returns true for matching context', () {
      final p = testProhibition(
        exceptions: [
          const ProhibitionException(
            condition: 'emergency',
            justificationRequired: 'Life-critical',
          ),
        ],
      );
      expect(p.hasApplicableException('This is an emergency situation'), isTrue);
    });

    // TC-037b
    test('hasApplicableException returns false for non-matching context', () {
      final p = testProhibition(
        exceptions: [
          const ProhibitionException(
            condition: 'emergency',
            justificationRequired: 'Life-critical',
          ),
        ],
      );
      expect(p.hasApplicableException('normal situation'), isFalse);
    });

    // TC-037a: returns false when exceptions is null/empty
    test('hasApplicableException returns false when exceptions is null', () {
      final p = testProhibition();
      expect(p.hasApplicableException('any context'), isFalse);
    });

    // TC-038: empty statement (validate() extension)
    test('validate() throws ArgumentError when statement is empty', () {
      expect(
        () => testProhibition(statement: '').validate(),
        throwsArgumentError,
      );
    });

    test('validate() throws ArgumentError when id is empty', () {
      expect(
        () => testProhibition(id: '').validate(),
        throwsArgumentError,
      );
    });

    // TC-038a: validate() succeeds for minimally valid prohibition
    test('validate() succeeds for minimally valid prohibition', () {
      final p = testProhibition();
      expect(() => p.validate(), returnsNormally);
    });

    // TC-038b: validate() succeeds for prohibition with exceptions list
    test('validate() succeeds for prohibition with exceptions list', () {
      final p = testProhibition(exceptions: [
        const ProhibitionException(
          condition: 'emergency',
          justificationRequired: 'Life-critical',
        ),
      ]);
      expect(() => p.validate(), returnsNormally);
    });

    // TC-038c: copyWith preserves unmodified fields
    test('copyWith modifies severity and preserves other fields', () {
      final p = testProhibition(severity: ProhibitionSeverity.hard);
      final copied = p.copyWith(severity: ProhibitionSeverity.soft);
      expect(copied.severity, ProhibitionSeverity.soft);
      expect(copied.id, p.id);
      expect(copied.statement, p.statement);
      expect(copied.rationale, p.rationale);
    });

    // TC-038d: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final p = testProhibition(exceptions: [
        const ProhibitionException(
          condition: 'ctx',
          justificationRequired: 'reason',
        ),
      ]);
      final copied = p.copyWith();
      expect(copied.id, p.id);
      expect(copied.statement, p.statement);
      expect(copied.severity, p.severity);
      expect(copied.exceptions?.length, p.exceptions?.length);
    });

    // TC-038e: copyWith replaces exceptions list when provided
    test('copyWith replaces exceptions list when provided', () {
      final p = testProhibition();
      final newExceptions = [
        const ProhibitionException(
          condition: 'new-cond',
          justificationRequired: 'new-reason',
        ),
      ];
      final copied = p.copyWith(exceptions: newExceptions);
      expect(copied.exceptions, hasLength(1));
      expect(copied.exceptions!.first.condition, 'new-cond');
    });
  });

  // TC-039: ProhibitionException JSON round-trip
  group('ProhibitionException', () {
    test('toJson/fromJson round-trip', () {
      const pe = ProhibitionException(
        condition: 'domain == "emergency"',
        justificationRequired: 'Life-critical decisions',
      );
      final json = pe.toJson();
      final restored = ProhibitionException.fromJson(json);
      expect(restored.condition, pe.condition);
      expect(restored.justificationRequired, pe.justificationRequired);
    });
  });

  // TC-049: ProhibitionSeverity enum forward compatibility
  group('ProhibitionSeverity', () {
    test('fromString falls back to unknown for unrecognized value', () {
      expect(
        ProhibitionSeverity.fromString('nonexistent'),
        ProhibitionSeverity.unknown,
      );
    });
  });
}
