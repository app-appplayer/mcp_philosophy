import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('Ethos', () {
    // TC-001: Construction with all required fields
    test('constructs with all required fields', () {
      final ethos = testEthos();
      expect(ethos.id, 'test-ethos-001');
      expect(ethos.name, 'Test Ethos');
      expect(ethos.valuePriorities, hasLength(1));
      expect(ethos.prohibitions, hasLength(1));
    });

    // TC-002: Construction with optional fields
    test('constructs with optional fields', () {
      final ethos = fullTestEthos();
      expect(ethos.judgmentCriteria, hasLength(1));
      expect(ethos.directionalAttitudes, hasLength(2));
      expect(ethos.scopes, hasLength(1));
    });

    // TC-003: JSON round-trip
    test('toJson/fromJson round-trip preserves all fields', () {
      final ethos = fullTestEthos();
      final json = ethos.toJson();
      final restored = Ethos.fromJson(json);
      expect(restored.id, ethos.id);
      expect(restored.name, ethos.name);
      expect(restored.valuePriorities.length, ethos.valuePriorities.length);
      expect(restored.prohibitions.length, ethos.prohibitions.length);
      expect(restored.judgmentCriteria.length, ethos.judgmentCriteria.length);
      expect(restored.directionalAttitudes.length,
          ethos.directionalAttitudes.length);
      expect(restored.metadata.version, ethos.metadata.version);
      expect(restored.scopes?.length, ethos.scopes?.length);
    });

    // TC-004: copyWith preserves unmodified fields
    test('copyWith preserves unmodified fields', () {
      final ethos = testEthos();
      final copied = ethos.copyWith(name: 'New Name');
      expect(copied.id, ethos.id);
      expect(copied.name, 'New Name');
      expect(copied.valuePriorities, ethos.valuePriorities);
    });

    // TC-004a: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final ethos = fullTestEthos();
      final copied = ethos.copyWith();
      expect(copied.id, ethos.id);
      expect(copied.name, ethos.name);
      expect(copied.valuePriorities.length, ethos.valuePriorities.length);
      expect(copied.prohibitions.length, ethos.prohibitions.length);
      expect(copied.metadata.version, ethos.metadata.version);
    });

    // TC-004b: copyWith replaces valuePriorities list entirely when provided
    test('copyWith replaces valuePriorities list entirely when provided', () {
      final ethos = testEthos();
      final newPriorities = [
        testValuePriority(id: 'new-vp', rank: 1, higherValue: 'New'),
      ];
      final copied = ethos.copyWith(valuePriorities: newPriorities);
      expect(copied.valuePriorities, hasLength(1));
      expect(copied.valuePriorities.first.id, 'new-vp');
      expect(copied.valuePriorities.first.higherValue, 'New');
    });

    // TC-005: topPriority returns rank-1
    test('topPriority returns first priority', () {
      final ethos = fullTestEthos();
      expect(ethos.topPriority, isNotNull);
      expect(ethos.topPriority!.rank, 1);
    });

    // TC-007: hardProhibitions filters correctly
    test('hardProhibitions filters by severity=hard', () {
      final ethos = fullTestEthos();
      expect(ethos.hardProhibitions, hasLength(1));
      expect(ethos.hardProhibitions.first.severity, ProhibitionSeverity.hard);
    });

    // TC-007a: hardProhibitions returns empty list when no hard prohibitions exist
    test('hardProhibitions returns empty list when no hard prohibitions exist',
        () {
      final ethos = testEthos(prohibitions: [
        testProhibition(severity: ProhibitionSeverity.soft),
      ]);
      expect(ethos.hardProhibitions, isEmpty);
    });

    // TC-008: softProhibitions filters correctly
    test('softProhibitions filters by severity=soft', () {
      final ethos = fullTestEthos();
      expect(ethos.softProhibitions, hasLength(1));
      expect(ethos.softProhibitions.first.severity, ProhibitionSeverity.soft);
    });

    // TC-008a: softProhibitions returns empty list when no soft prohibitions exist
    test('softProhibitions returns empty list when no soft prohibitions exist',
        () {
      final ethos = testEthos(prohibitions: [
        testProhibition(severity: ProhibitionSeverity.hard),
      ]);
      expect(ethos.softProhibitions, isEmpty);
    });

    // TC-009: criteriaForDomain
    test('criteriaForDomain returns matching criteria', () {
      final ethos = fullTestEthos();
      final criteria = ethos.criteriaForDomain('risk');
      expect(criteria, hasLength(1));
    });

    // TC-009a: criteriaForDomain returns empty list when no criteria match
    test('criteriaForDomain returns empty list when no criteria match', () {
      final ethos = fullTestEthos();
      final criteria = ethos.criteriaForDomain('nonexistent-domain');
      expect(criteria, isEmpty);
    });

    // TC-009b: criteriaForDomain returns empty list for ethos without criteria
    test('criteriaForDomain returns empty list when judgmentCriteria is empty',
        () {
      final ethos = testEthos(judgmentCriteria: []);
      final criteria = ethos.criteriaForDomain('any');
      expect(criteria, isEmpty);
    });

    // TC-010: attitudeFor
    test('attitudeFor returns correct attitude by domain', () {
      final ethos = fullTestEthos();
      final attitude = ethos.attitudeFor(AttitudeDomain.uncertainty);
      expect(attitude, isNotNull);
      expect(attitude!.domain, AttitudeDomain.uncertainty);
    });

    // TC-010a: attitudeFor returns null for missing domain
    test('attitudeFor returns null for missing domain', () {
      final ethos = testEthos();
      final attitude = ethos.attitudeFor(AttitudeDomain.conflict);
      expect(attitude, isNull);
    });

    // TC-010b: attitudeFor returns null when directionalAttitudes is empty
    test('attitudeFor returns null when directionalAttitudes is empty', () {
      final ethos = testEthos(directionalAttitudes: []);
      final attitude = ethos.attitudeFor(AttitudeDomain.uncertainty);
      expect(attitude, isNull);
    });

    // TC-011: isApplicableTo returns true when scopes is null
    test('isApplicableTo returns true when scopes is null (global)', () {
      final ethos = testEthos(scopes: null);
      expect(ethos.isApplicableTo('any-domain'), isTrue);
    });

    // TC-012: isApplicableTo returns true for matching domain
    test('isApplicableTo returns true for matching domain', () {
      final ethos = fullTestEthos();
      expect(ethos.isApplicableTo('education'), isTrue);
    });

    // TC-013: isApplicableTo returns false for non-matching domain
    test('isApplicableTo returns false for non-matching domain', () {
      final ethos = fullTestEthos();
      expect(ethos.isApplicableTo('finance'), isFalse);
    });

    // TC-014 ~ TC-018: Error cases (validate() extension)
    test('validate() throws ArgumentError when id is empty', () {
      expect(
        () => testEthos(id: '').validate(),
        throwsArgumentError,
      );
    });

    test('validate() throws ArgumentError when name is empty', () {
      expect(
        () => testEthos(name: '').validate(),
        throwsArgumentError,
      );
    });

    test('validate() throws ArgumentError when valuePriorities is empty', () {
      expect(
        () => testEthos(valuePriorities: []).validate(),
        throwsArgumentError,
      );
    });

    test('validate() throws ArgumentError when prohibitions is empty', () {
      expect(
        () => testEthos(prohibitions: []).validate(),
        throwsArgumentError,
      );
    });

    test('validate() throws ArgumentError when duplicate ranks exist', () {
      expect(
        () => testEthos(valuePriorities: [
          testValuePriority(id: 'vp-1', rank: 1),
          testValuePriority(id: 'vp-2', rank: 1),
        ]).validate(),
        throwsArgumentError,
      );
    });

    // TC-019 ~ TC-023: Ethos composition
    group('mergeWith', () {
      test('combines valuePriorities with re-ranking', () {
        final base = testEthos(
          id: 'base',
          valuePriorities: [testValuePriority(id: 'vp-b', rank: 1)],
        );
        final other = testEthos(
          id: 'other',
          valuePriorities: [testValuePriority(id: 'vp-o', rank: 1)],
        );

        final merged = base.mergeWith(
          other,
          resolution: const ConflictResolution(
            strategy: ConflictStrategy.merge,
          ),
        );

        expect(merged.valuePriorities, hasLength(2));
        final ranks =
            merged.valuePriorities.map((vp) => vp.rank).toSet();
        expect(ranks.length, 2);
      });

      test('creates union of prohibitions', () {
        final base = testEthos(
          id: 'base',
          prohibitions: [testProhibition(id: 'p-1')],
        );
        final other = testEthos(
          id: 'other',
          prohibitions: [testProhibition(id: 'p-2', statement: 'Do not Y')],
        );

        final merged = base.mergeWith(
          other,
          resolution: const ConflictResolution(
            strategy: ConflictStrategy.merge,
          ),
        );

        expect(merged.prohibitions.length, greaterThanOrEqualTo(2));
      });

      test('other overrides judgmentCriteria on conflict', () {
        final base = testEthos(
          id: 'base',
          judgmentCriteria: [
            testCriterion(id: 'jc-1', preferredAction: 'Action A')
          ],
        );
        final other = testEthos(
          id: 'other',
          judgmentCriteria: [
            testCriterion(id: 'jc-1', preferredAction: 'Action B')
          ],
        );

        final merged = base.mergeWith(
          other,
          resolution: const ConflictResolution(
            strategy: ConflictStrategy.merge,
          ),
        );

        expect(merged.judgmentCriteria, hasLength(1));
        expect(merged.judgmentCriteria.first.preferredAction, 'Action B');
      });

      test('other overrides directionalAttitudes on same domain', () {
        final base = testEthos(
          id: 'base',
          directionalAttitudes: [
            testAttitude(id: 'da-1', posture: 'Base posture')
          ],
        );
        final other = testEthos(
          id: 'other',
          directionalAttitudes: [
            testAttitude(id: 'da-2', posture: 'Other posture')
          ],
        );

        final merged = base.mergeWith(
          other,
          resolution: const ConflictResolution(
            strategy: ConflictStrategy.merge,
          ),
        );

        // Same domain (uncertainty) - other overrides
        final attitudes = merged.directionalAttitudes
            .where((a) => a.domain == AttitudeDomain.uncertainty)
            .toList();
        expect(attitudes, hasLength(1));
        expect(attitudes.first.posture, 'Other posture');
      });

      test('throws EthosValidationException on reject strategy with conflict',
          () {
        final base = testEthos(
          id: 'base',
          valuePriorities: [testValuePriority(id: 'vp-1', rank: 1)],
        );
        final other = testEthos(
          id: 'other',
          valuePriorities: [testValuePriority(id: 'vp-2', rank: 1)],
        );

        expect(
          () => base.mergeWith(
            other,
            resolution: const ConflictResolution(
              strategy: ConflictStrategy.reject,
            ),
          ),
          throwsA(isA<EthosValidationException>()),
        );
      });
    });

    test('equality by id', () {
      final a = testEthos(id: 'same-id');
      final b = testEthos(id: 'same-id', name: 'Different');
      expect(a.id, equals(b.id));
    });
  });

  group('EthosScope', () {
    test('toJson/fromJson round-trip', () {
      const scope = EthosScope(
        domain: 'education',
        description: 'K-12',
        tags: ['math'],
      );
      final json = scope.toJson();
      final restored = EthosScope.fromJson(json);
      expect(restored.domain, scope.domain);
      expect(restored.description, scope.description);
      expect(restored.tags, scope.tags);
    });
  });

  group('ConflictResolution', () {
    // TC-051a
    test('toJson/fromJson round-trip', () {
      const cr = ConflictResolution(
        strategy: ConflictStrategy.merge,
        preferredEthosId: 'ethos-1',
      );
      final json = cr.toJson();
      final restored = ConflictResolution.fromJson(json);
      expect(restored.strategy, ConflictStrategy.merge);
      expect(restored.preferredEthosId, 'ethos-1');
    });

    // TC-051d: construction with minimal fields (strategy only)
    test('construction with minimal fields (strategy only)', () {
      const cr = ConflictResolution(strategy: ConflictStrategy.preferHigher);
      expect(cr.strategy, ConflictStrategy.preferHigher);
      expect(cr.preferredEthosId, isNull);
    });

    // TC-051e: fromJson throws on malformed JSON (missing strategy)
    test('fromJson throws on malformed JSON (missing strategy)', () {
      expect(
        () => ConflictResolution.fromJson(const {'preferredEthosId': 'x'}),
        throwsA(anyOf(isA<TypeError>(), isA<FormatException>())),
      );
    });
  });

  // TC-051: ConflictStrategy enum forward compatibility
  group('ConflictStrategy', () {
    // TC-051b
    test('fromString returns correct enum value', () {
      expect(ConflictStrategy.fromString('merge'), ConflictStrategy.merge);
      expect(
          ConflictStrategy.fromString('reject'), ConflictStrategy.reject);
      expect(ConflictStrategy.fromString('preferHigher'),
          ConflictStrategy.preferHigher);
      expect(ConflictStrategy.fromString('preferLower'),
          ConflictStrategy.preferLower);
    });

    // TC-051c
    test('fromString falls back to unknown for unrecognized value', () {
      expect(
        ConflictStrategy.fromString('nonexistent'),
        ConflictStrategy.unknown,
      );
    });

    // TC-051f: case-sensitive (mixed case returns unknown)
    test('fromString is case-sensitive and returns unknown for mixed case',
        () {
      expect(ConflictStrategy.fromString('Merge'), ConflictStrategy.unknown);
      expect(ConflictStrategy.fromString('MERGE'), ConflictStrategy.unknown);
    });
  });
}
