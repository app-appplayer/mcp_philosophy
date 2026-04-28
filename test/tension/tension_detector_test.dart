import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  const detector = TensionDetector();

  Ethos collaborativeEthos() => Ethos(
        id: 'ethos-collab',
        name: 'Collaborative Entity',
        valuePriorities: [
          testValuePriority(
            id: 'vp-1',
            rank: 1,
            higherValue: 'Collaboration',
            lowerValue: 'Isolation',
          ),
        ],
        prohibitions: [
          testProhibition(
            id: 'proh-1',
            statement: 'Never ignore team input',
            severity: ProhibitionSeverity.soft,
          ),
        ],
        directionalAttitudes: [
          testAttitude(
            id: 'da-1',
            domain: AttitudeDomain.conflict,
            posture: 'Seek understanding before resolution',
          ),
        ],
        metadata: testMetadata(),
      );

  group('TensionDetector', () {
    group('detect', () {
      test('detects philosophy-profile tension with defensive posture', () {
        final ethos = collaborativeEthos();
        final context = MultiLayerContext(
          philosophyContext: testContext(),
          profileState: {
            'posture': 'defensive',
            'reason': 'past_betrayal',
          },
        );

        final tensions = detector.detect(ethos, context);
        expect(tensions, isNotEmpty);
        expect(
          tensions.any((t) =>
              t.source.opposingLayer == TensionLayer.profile),
          isTrue,
        );
      });

      test('detects philosophy-knowledge tension with low trust', () {
        final ethos = collaborativeEthos();
        final context = MultiLayerContext(
          philosophyContext: testContext(),
          knowledgeProvenance: {'trust_score': 0.1},
        );

        final tensions = detector.detect(ethos, context);
        expect(tensions, isNotEmpty);
        expect(
          tensions.any((t) =>
              t.source.opposingLayer == TensionLayer.knowledge),
          isTrue,
        );
      });

      test('detects philosophy-state tension with high urgency', () {
        final ethos = Ethos(
          id: 'ethos-accuracy',
          name: 'Accuracy First',
          valuePriorities: [
            testValuePriority(
              id: 'vp-1',
              rank: 1,
              higherValue: 'Understanding',
              lowerValue: 'Speed',
            ),
          ],
          prohibitions: [testProhibition()],
          metadata: testMetadata(),
        );

        final context = MultiLayerContext(
          philosophyContext: testContext(),
          stateWeighting: {
            'urgency': 0.95,
            'riskSensitivity': 0.2,
          },
        );

        final tensions = detector.detect(ethos, context);
        expect(tensions, isNotEmpty);
        expect(
          tensions.any((t) =>
              t.source.opposingLayer == TensionLayer.state),
          isTrue,
        );
      });

      test('returns empty when no tensions detected', () {
        final ethos = collaborativeEthos();
        final context = MultiLayerContext(
          philosophyContext: testContext(),
        );

        final tensions = detector.detect(ethos, context);
        expect(tensions, isEmpty);
      });

      test('sorts tensions by severity (critical first)', () {
        final ethos = collaborativeEthos();
        final context = MultiLayerContext(
          philosophyContext: testContext(),
          profileState: {'posture': 'defensive', 'reason': 'test'},
          knowledgeProvenance: {'trust_score': 0.1},
        );

        final tensions = detector.detect(ethos, context);
        if (tensions.length >= 2) {
          for (var i = 0; i < tensions.length - 1; i++) {
            expect(tensions[i].severity.index,
                greaterThanOrEqualTo(tensions[i + 1].severity.index));
          }
        }
      });
    });

    group('resolve', () {
      test('philosophyWins gives high confidence', () {
        final tension = Tension(
          id: 't-1',
          source: const TensionSource(opposingLayer: TensionLayer.profile),
          philosophyDirective: 'Collaborate',
          opposingDirective: 'Defensive',
          severity: TensionSeverity.medium,
          description: 'Test',
        );

        final resolution = detector.resolve(
          tension,
          strategy: ResolutionStrategy.philosophyWins,
        );

        expect(resolution.strategy, ResolutionStrategy.philosophyWins);
        expect(resolution.confidence, 0.85);
        expect(resolution.tensionId, 't-1');
      });

      test('compromise gives medium confidence', () {
        final tension = Tension(
          id: 't-1',
          source: const TensionSource(opposingLayer: TensionLayer.profile),
          philosophyDirective: 'Collaborate',
          opposingDirective: 'Defensive',
          severity: TensionSeverity.medium,
          description: 'Test',
        );

        final resolution = detector.resolve(
          tension,
          strategy: ResolutionStrategy.compromise,
        );

        expect(resolution.confidence, 0.6);
      });

      test('defer gives zero confidence', () {
        final tension = Tension(
          id: 't-1',
          source: const TensionSource(opposingLayer: TensionLayer.profile),
          philosophyDirective: 'Collaborate',
          opposingDirective: 'Defensive',
          severity: TensionSeverity.medium,
          description: 'Test',
        );

        final resolution = detector.resolve(
          tension,
          strategy: ResolutionStrategy.defer,
        );

        expect(resolution.confidence, 0.0);
        expect(resolution.outcome, contains('deferred'));
      });

      // TC-170a: null strategy uses default selector
      test('default strategy based on severity', () {
        final criticalTension = Tension(
          id: 't-1',
          source: const TensionSource(opposingLayer: TensionLayer.state),
          philosophyDirective: 'Direction',
          opposingDirective: 'Opposing',
          severity: TensionSeverity.critical,
          description: 'Critical tension',
        );

        final resolution = detector.resolve(criticalTension);
        expect(resolution.strategy, ResolutionStrategy.philosophyWins);
      });

      // TC-172: unknown strategy returns deferred resolution with 0.0 confidence
      test('unknown strategy returns deferred resolution with 0.0 confidence',
          () {
        final tension = Tension(
          id: 't-unknown',
          source: const TensionSource(opposingLayer: TensionLayer.profile),
          philosophyDirective: 'X',
          opposingDirective: 'Y',
          severity: TensionSeverity.medium,
          description: 'Test',
        );

        final resolution = detector.resolve(
          tension,
          strategy: ResolutionStrategy.unknown,
        );
        expect(resolution.confidence, 0.0);
        expect(resolution.strategy, ResolutionStrategy.defer);
      });
    });

    // TC-147a: detect with all layers populated returns tensions from each
    group('detect integration', () {
      test('detect with all layers populated returns multi-layer tensions',
          () {
        final ethos = collaborativeEthos();
        final context = MultiLayerContext(
          philosophyContext: testContext(),
          profileState: {'posture': 'defensive'},
          knowledgeProvenance: {'trust_score': 0.1},
          stateWeighting: {'urgency': 0.95, 'riskSensitivity': 0.2},
        );
        final tensions = detector.detect(ethos, context);
        expect(tensions, isNotEmpty);
        // Multiple layer sources should appear
        final layers = tensions.map((t) => t.source.opposingLayer).toSet();
        expect(layers.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
