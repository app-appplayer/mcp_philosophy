import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

void main() {
  group('InterventionResult', () {
    test('noOp factory creates empty result', () {
      final result = InterventionResult.noOp();
      expect(result.point, InterventionPoint.unknown);
      expect(result.hasInterventions, isFalse);
      expect(result.blocksDelivery, isFalse);
      expect(result.modified, isFalse);
    });

    // TC-118a: noOp always sets point=InterventionPoint.unknown
    test('noOp always sets point=InterventionPoint.unknown', () {
      final result = InterventionResult.noOp();
      expect(result.point, InterventionPoint.unknown);
      expect(result.hasInterventions, isFalse);
      expect(result.prohibitionViolated, isFalse);
    });

    // TC-119a: hasInterventions returns false for empty list
    test('hasInterventions returns false for empty intervention list', () {
      final result = InterventionResult(
        point: InterventionPoint.preGeneration,
        interventions: const [],
      );
      expect(result.hasInterventions, isFalse);
    });

    test('blocksDelivery reflects prohibitionViolated', () {
      final result = InterventionResult(
        point: InterventionPoint.postGeneration,
        prohibitionViolated: true,
        prohibitionViolationIds: ['proh-1'],
      );
      expect(result.blocksDelivery, isTrue);
    });

    // TC-120a: blocksDelivery returns false when prohibitionViolated=false
    test('blocksDelivery returns false when prohibitionViolated=false', () {
      final result = InterventionResult(
        point: InterventionPoint.postGeneration,
        prohibitionViolated: false,
      );
      expect(result.blocksDelivery, isFalse);
    });

    test('toJson/fromJson round-trip', () {
      final result = InterventionResult(
        point: InterventionPoint.preGeneration,
        interventions: [
          const AppliedIntervention(
            id: 'intv-1',
            type: InterventionType.knowledgeRank,
            description: 'Ranked knowledge',
            rationale: 'Value priority',
            ethosComponentId: 'vp-1',
          ),
        ],
        modified: true,
      );
      final json = result.toJson();
      final restored = InterventionResult.fromJson(json);
      expect(restored.point, InterventionPoint.preGeneration);
      expect(restored.interventions, hasLength(1));
      expect(restored.interventions.first.type, InterventionType.knowledgeRank);
      expect(restored.modified, isTrue);
    });
  });

  group('InterventionType', () {
    test('has all 12 values (11 + unknown)', () {
      expect(InterventionType.values, hasLength(12));
    });

    test('fromString falls back to unknown', () {
      expect(
        InterventionType.fromString('nonexistent'),
        InterventionType.unknown,
      );
    });
  });

  group('AppliedIntervention', () {
    // TC-122a: toJson/fromJson round-trip
    test('toJson/fromJson round-trip', () {
      const ai = AppliedIntervention(
        id: 'intv-1',
        type: InterventionType.prohibitionBlock,
        description: 'Blocked output',
        rationale: 'Hard prohibition',
        ethosComponentId: 'proh-1',
        before: {'output': 'bad text'},
        after: {'output': null},
      );
      final json = ai.toJson();
      final restored = AppliedIntervention.fromJson(json);
      expect(restored.id, 'intv-1');
      expect(restored.type, InterventionType.prohibitionBlock);
      expect(restored.ethosComponentId, 'proh-1');
      expect(restored.before, isNotNull);
    });
  });

  group('PreGenerationResult', () {
    // TC-103a: empty interventions has hasInterventions=false
    test('with empty interventions has hasInterventions=false', () {
      final result = PreGenerationResult(
        interventions: const [],
      );
      expect(result.point, InterventionPoint.preGeneration);
      expect(result.hasInterventions, isFalse);
      expect(result.filteredKnowledgeIds, isNull);
    });

    // TC-103b: toJson returns base InterventionResult fields
    test('toJson returns base InterventionResult fields', () {
      final result = PreGenerationResult(
        interventions: const [
          AppliedIntervention(
            id: 'intv-1',
            type: InterventionType.knowledgeRank,
            description: 'Ranked knowledge',
            rationale: 'Value priority',
          ),
        ],
        filteredKnowledgeIds: const ['k-1'],
        modified: true,
      );
      final json = result.toJson();
      expect(json['point'], 'preGeneration');
      expect(json['interventions'], hasLength(1));
      expect(json['modified'], isTrue);
    });
  });

  group('DuringGenerationResult', () {
    // TC-108a: empty interventions has hasInterventions=false
    test('with empty interventions has hasInterventions=false', () {
      final result = DuringGenerationResult(
        interventions: const [],
      );
      expect(result.point, InterventionPoint.duringGeneration);
      expect(result.hasInterventions, isFalse);
      expect(result.candidateRanking, isNull);
    });

    // TC-108b: toJson returns base InterventionResult fields
    test('toJson returns base InterventionResult fields', () {
      final result = DuringGenerationResult(
        interventions: const [
          AppliedIntervention(
            id: 'intv-2',
            type: InterventionType.candidateReRank,
            description: 'Re-ranked',
            rationale: 'Priority order',
          ),
        ],
        candidateRanking: const [1, 0],
        modified: true,
      );
      final json = result.toJson();
      expect(json['point'], 'duringGeneration');
      expect(json['interventions'], hasLength(1));
      expect(json['modified'], isTrue);
    });
  });

  group('PostGenerationResult', () {
    // TC-117a: no violations has hasInterventions=false
    test('with no violations has hasInterventions=false', () {
      final result = PostGenerationResult(
        interventions: const [],
        prohibitionViolated: false,
        prohibitionCheckResult: ProhibitionCheckResult.allPassed(const []),
        evidenceSufficiency: 0.9,
        evidenceSufficient: true,
      );
      expect(result.point, InterventionPoint.postGeneration);
      expect(result.hasInterventions, isFalse);
      expect(result.blocksDelivery, isFalse);
    });

    // TC-117b: toJson returns base InterventionResult fields
    test('toJson returns base InterventionResult fields', () {
      final result = PostGenerationResult(
        interventions: const [
          AppliedIntervention(
            id: 'intv-3',
            type: InterventionType.prohibitionBlock,
            description: 'Checked',
            rationale: 'Hard prohibition',
          ),
        ],
        prohibitionViolated: false,
        prohibitionCheckResult: ProhibitionCheckResult.allPassed(const []),
        evidenceSufficiency: 0.8,
        evidenceSufficient: true,
      );
      final json = result.toJson();
      expect(json['point'], 'postGeneration');
      expect(json['interventions'], hasLength(1));
      expect(json['prohibitionViolated'], isFalse);
    });
  });
}
