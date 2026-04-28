import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  late InterventionEngine engine;
  late Ethos ethos;

  setUp(() {
    engine = InterventionEngine(evaluator: const PhilosophyEvaluator());
    ethos = fullTestEthos();
  });

  group('InterventionEngine', () {
    group('preGeneration', () {
      test('filters and ranks knowledge by value priorities', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.preGeneration,
          knowledgeRetrieved: {
            'fact-1': {'content': 'High relevance', 'relevance': 0.9},
            'fact-2': {'content': 'Low relevance', 'relevance': 0.1},
            'fact-3': {'content': 'Medium relevance', 'relevance': 0.6},
          },
          skillContext: {'availableApproaches': ['a', 'b']},
          profileContext: {'currentPosture': 'neutral'},
        );

        final result = engine.intervene(
          InterventionPoint.preGeneration,
          context,
          ethos,
        );

        expect(result, isA<PreGenerationResult>());
        final preResult = result as PreGenerationResult;
        expect(preResult.modified, isTrue);
        expect(preResult.hasInterventions, isTrue);
        expect(preResult.filteredKnowledgeIds, contains('fact-2'));
        expect(preResult.rankedKnowledgeOrder, isNotNull);
        expect(preResult.rankedKnowledgeOrder!.first, 'fact-1');
      });

      test('selects skill approach via judgment criteria', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.preGeneration,
          knowledgeRetrieved: {'risk': 'high'},
          skillContext: {'availableApproaches': ['conservative', 'aggressive']},
        );

        final result =
            engine.intervene(InterventionPoint.preGeneration, context, ethos)
                as PreGenerationResult;

        // Judgment criteria matches risk == "high" from knowledge
        expect(result.selectedSkillApproach, isNotNull);
      });

      test('activates profile posture from directional attitudes', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.preGeneration,
          profileContext: {'currentPosture': 'neutral'},
        );

        final result =
            engine.intervene(InterventionPoint.preGeneration, context, ethos)
                as PreGenerationResult;

        expect(result.activatedProfilePosture, isNotNull);
      });
    });

    group('duringGeneration', () {
      test('re-ranks candidate responses', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.duringGeneration,
          candidateResponses: ['Response A', 'Response B', 'Response C'],
        );

        final result =
            engine.intervene(InterventionPoint.duringGeneration, context, ethos)
                as DuringGenerationResult;

        expect(result.modified, isTrue);
        expect(result.candidateRanking, isNotNull);
        expect(result.candidateRanking, hasLength(3));
      });

      test('adjusts expression based on directional attitudes', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.duringGeneration,
        );

        final result =
            engine.intervene(InterventionPoint.duringGeneration, context, ethos)
                as DuringGenerationResult;

        expect(result.expressionAdjustments, isNotNull);
        expect(result.expressionAdjustments!['attitudeDomain'], 'uncertainty');
      });
    });

    group('postGeneration', () {
      test('blocks delivery on hard prohibition violation', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.postGeneration,
          generatedOutput: 'This is definitely the correct answer always',
          knowledgeRetrieved: {'fact-1': 'data'},
        );

        final result =
            engine.intervene(InterventionPoint.postGeneration, context, ethos)
                as PostGenerationResult;

        expect(result.blocksDelivery, isTrue);
        expect(result.prohibitionViolated, isTrue);
        expect(result.prohibitionCheckResult.hasHardViolation, isTrue);
      });

      test('allows delivery when no violation', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.postGeneration,
          generatedOutput: 'This might be the answer based on evidence',
          knowledgeRetrieved: {
            'f1': 'd1',
            'f2': 'd2',
            'f3': 'd3',
            'f4': 'd4',
            'f5': 'd5',
          },
        );

        final result =
            engine.intervene(InterventionPoint.postGeneration, context, ethos)
                as PostGenerationResult;

        expect(result.blocksDelivery, isFalse);
        expect(result.evidenceSufficient, isTrue);
      });

      test('detects insufficient evidence', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.postGeneration,
          generatedOutput: 'Some output',
          knowledgeRetrieved: {'fact-1': 'only one'},
        );

        final result =
            engine.intervene(InterventionPoint.postGeneration, context, ethos)
                as PostGenerationResult;

        expect(result.evidenceSufficiency, lessThan(0.5));
        expect(result.evidenceSufficient, isFalse);
      });

      test('aligns tone when profile context available', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.postGeneration,
          generatedOutput: 'Some output',
          profileContext: {'posture': 'neutral'},
        );

        final result =
            engine.intervene(InterventionPoint.postGeneration, context, ethos)
                as PostGenerationResult;

        expect(result.toneAdjustments, isNotNull);
      });
    });

    group('unknown point', () {
      test('returns noOp for unknown intervention point', () {
        final context = PipelineContext(
          pipelineId: 'pipe-1',
          currentPoint: InterventionPoint.unknown,
        );

        final result = engine.intervene(InterventionPoint.unknown, context, ethos);
        expect(result.hasInterventions, isFalse);
        expect(result.modified, isFalse);
      });
    });
  });
}
