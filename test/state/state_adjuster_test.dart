import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  const adjuster = StateAdjuster();

  PhilosophyGuidance makeGuidance({double confidence = 0.8}) {
    return PhilosophyGuidance(
      valuePriorityApplied: testValuePriority(),
      prohibitionChecks: ProhibitionCheckResult.allPassed(const []),
      recommendedAction: 'Test action',
      confidence: confidence,
      explanation: 'Test explanation',
      prohibitionViolated: false,
    );
  }

  group('StateAdjuster', () {
    test('adjusts confidence based on state confidence', () {
      final guidance = makeGuidance(confidence: 0.8);
      const stateWeighting = StateWeighting(confidence: 0.9);

      final (adjusted, impact) =
          adjuster.adjustGuidance(guidance, stateWeighting);

      // (0.9 - 0.5) * 0.2 = 0.08 boost
      expect(adjusted.confidence, closeTo(0.88, 0.01));
      expect(impact.adjustments['confidence'], closeTo(0.08, 0.01));
    });

    test('reduces confidence for low state confidence', () {
      final guidance = makeGuidance(confidence: 0.8);
      const stateWeighting = StateWeighting(confidence: 0.1);

      final (adjusted, _) = adjuster.adjustGuidance(guidance, stateWeighting);

      // (0.1 - 0.5) * 0.2 = -0.08
      expect(adjusted.confidence, closeTo(0.72, 0.01));
    });

    test('direction is always preserved', () {
      final guidance = makeGuidance();
      const stateWeighting = StateWeighting(urgency: 0.95);

      final (adjusted, impact) =
          adjuster.adjustGuidance(guidance, stateWeighting);

      expect(adjusted.valuePriorityApplied, guidance.valuePriorityApplied);
      expect(impact.directionPreserved, isTrue);
    });

    test('prohibitions are always preserved', () {
      final guidance = makeGuidance();
      const stateWeighting = StateWeighting(urgency: 0.95);

      final (adjusted, impact) =
          adjuster.adjustGuidance(guidance, stateWeighting);

      expect(adjusted.prohibitionViolated, guidance.prohibitionViolated);
      expect(impact.prohibitionsPreserved, isTrue);
    });

    test('thoroughness adjustment from urgency', () {
      final guidance = makeGuidance();
      const stateWeighting = StateWeighting(urgency: 0.95);

      final (_, impact) = adjuster.adjustGuidance(guidance, stateWeighting);

      // (0.5 - 0.95) * 0.3 = -0.135
      expect(impact.adjustments['thoroughness'], closeTo(-0.135, 0.01));
    });

    test('caution adjustment from risk sensitivity', () {
      final guidance = makeGuidance();
      const stateWeighting = StateWeighting(riskSensitivity: 0.9);

      final (_, impact) = adjuster.adjustGuidance(guidance, stateWeighting);

      // (0.9 - 0.5) * 0.4 = 0.16
      expect(impact.adjustments['caution'], closeTo(0.16, 0.01));
    });

    test('expression adjustment from emotional intensity', () {
      final guidance = makeGuidance();
      const stateWeighting = StateWeighting(emotionalIntensity: 0.9);

      final (_, impact) = adjuster.adjustGuidance(guidance, stateWeighting);

      // (0.9 - 0.5) * 0.3 = 0.12
      expect(impact.adjustments['expression'], closeTo(0.12, 0.01));
    });

    test('neutral weighting produces no significant adjustments', () {
      final guidance = makeGuidance(confidence: 0.8);
      const stateWeighting = StateWeighting();

      final (adjusted, impact) =
          adjuster.adjustGuidance(guidance, stateWeighting);

      // All adjustments should be 0.0 for neutral (0.5) weights
      expect(impact.adjustments['confidence'], closeTo(0.0, 0.001));
      expect(impact.adjustments['thoroughness'], closeTo(0.0, 0.001));
      expect(impact.adjustments['caution'], closeTo(0.0, 0.001));
      expect(impact.adjustments['expression'], closeTo(0.0, 0.001));
      expect(adjusted.confidence, closeTo(0.8, 0.001));
    });

    test('confidence clamped to [0.0, 1.0]', () {
      final guidance = makeGuidance(confidence: 0.99);
      const stateWeighting = StateWeighting(confidence: 1.0);

      final (adjusted, _) = adjuster.adjustGuidance(guidance, stateWeighting);

      // 0.99 + 0.1 = 1.09 -> clamped to 1.0
      expect(adjusted.confidence, lessThanOrEqualTo(1.0));
    });

    test('hadEffect is true when adjustments exist', () {
      final guidance = makeGuidance();
      const stateWeighting = StateWeighting(urgency: 0.9);

      final (_, impact) = adjuster.adjustGuidance(guidance, stateWeighting);

      expect(impact.hadEffect, isTrue);
    });

    test('documented example: urgency=0.95, riskSensitivity=0.3', () {
      final guidance = makeGuidance(confidence: 0.8);
      const stateWeighting = StateWeighting(
        urgency: 0.95,
        riskSensitivity: 0.3,
        confidence: 0.5,
        emotionalIntensity: 0.5,
      );

      final (adjusted, impact) =
          adjuster.adjustGuidance(guidance, stateWeighting);

      expect(impact.adjustments['confidence'], closeTo(0.0, 0.01));
      expect(impact.adjustments['thoroughness'], closeTo(-0.135, 0.01));
      expect(impact.adjustments['caution'], closeTo(-0.08, 0.01));
      expect(impact.adjustments['expression'], closeTo(0.0, 0.01));
      expect(adjusted.confidence, closeTo(0.8, 0.01));
      expect(impact.directionPreserved, isTrue);
      expect(impact.prohibitionsPreserved, isTrue);
      expect(impact.summary, contains('Direction preserved'));
    });
  });
}
