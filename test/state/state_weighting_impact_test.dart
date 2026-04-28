import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

void main() {
  group('StateWeightingImpact', () {
    test('hadEffect returns true when adjustments exist', () {
      final impact = StateWeightingImpact(
        appliedWeighting: const StateWeighting(),
        adjustments: const {'confidence': 0.05},
        summary: 'Test',
      );
      expect(impact.hadEffect, isTrue);
    });

    test('hadEffect returns false when adjustments empty', () {
      final impact = StateWeightingImpact(
        appliedWeighting: const StateWeighting(),
        adjustments: const {},
        summary: 'No effect',
      );
      expect(impact.hadEffect, isFalse);
    });

    test('defaults directionPreserved and prohibitionsPreserved to true', () {
      final impact = StateWeightingImpact(
        appliedWeighting: const StateWeighting(),
        adjustments: const {},
        summary: 'Test',
      );
      expect(impact.directionPreserved, isTrue);
      expect(impact.prohibitionsPreserved, isTrue);
    });

    test('toJson/fromJson round-trip', () {
      final impact = StateWeightingImpact(
        appliedWeighting: const StateWeighting(urgency: 0.9),
        adjustments: const {
          'confidence': 0.05,
          'thoroughness': -0.12,
        },
        summary: 'Urgency reduced thoroughness',
        directionPreserved: true,
        prohibitionsPreserved: true,
      );
      final json = impact.toJson();
      final restored = StateWeightingImpact.fromJson(json);
      expect(restored.appliedWeighting.urgency, 0.9);
      expect(restored.adjustments['confidence'], 0.05);
      expect(restored.adjustments['thoroughness'], -0.12);
      expect(restored.summary, 'Urgency reduced thoroughness');
      expect(restored.directionPreserved, isTrue);
      expect(restored.prohibitionsPreserved, isTrue);
    });
  });
}
