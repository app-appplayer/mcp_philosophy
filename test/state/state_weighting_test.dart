import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

void main() {
  group('StateWeighting', () {
    test('default values are all 0.5', () {
      const sw = StateWeighting();
      expect(sw.urgency, 0.5);
      expect(sw.riskSensitivity, 0.5);
      expect(sw.confidence, 0.5);
      expect(sw.emotionalIntensity, 0.5);
    });

    test('neutral static const', () {
      expect(StateWeighting.neutral.urgency, 0.5);
      expect(StateWeighting.neutral.riskSensitivity, 0.5);
    });

    test('hasExtremes detects high values (> 0.8)', () {
      const sw = StateWeighting(urgency: 0.9);
      expect(sw.hasExtremes, isTrue);
    });

    test('hasExtremes detects low values (< 0.2)', () {
      const sw = StateWeighting(confidence: 0.1);
      expect(sw.hasExtremes, isTrue);
    });

    test('hasExtremes is false for neutral values', () {
      const sw = StateWeighting();
      expect(sw.hasExtremes, isFalse);
    });

    // TC-226
    test('tensionWithAccuracy when urgency high and risk low', () {
      const sw = StateWeighting(urgency: 0.9, riskSensitivity: 0.2);
      expect(sw.tensionWithAccuracy, isTrue);
    });

    // TC-226a: boundary at exactly urgency=0.8
    test('tensionWithAccuracy false at exactly urgency=0.8', () {
      const sw = StateWeighting(urgency: 0.8, riskSensitivity: 0.2);
      expect(sw.tensionWithAccuracy, isFalse);
    });

    // TC-226b: neutral state
    test('tensionWithAccuracy is false for neutral state', () {
      const sw = StateWeighting();
      expect(sw.tensionWithAccuracy, isFalse);
    });

    // TC-227
    test('tensionWithSpeed when urgency low and risk high', () {
      const sw = StateWeighting(urgency: 0.1, riskSensitivity: 0.9);
      expect(sw.tensionWithSpeed, isTrue);
    });

    // TC-227a: boundary at exactly urgency=0.2
    test('tensionWithSpeed false at exactly urgency=0.2', () {
      const sw = StateWeighting(urgency: 0.2, riskSensitivity: 0.9);
      expect(sw.tensionWithSpeed, isFalse);
    });

    // TC-227b: neutral state
    test('tensionWithSpeed is false for neutral state', () {
      const sw = StateWeighting();
      expect(sw.tensionWithSpeed, isFalse);
    });

    // mcp_bundle const constructor does not enforce range assertions.
    // Validation is not enforced at the contract layer for StateWeighting.
    test('accepts values outside [0.0, 1.0] at contract layer', () {
      final sw1 = StateWeighting(urgency: -0.1);
      expect(sw1.urgency, -0.1);
      final sw2 = StateWeighting(urgency: 1.1);
      expect(sw2.urgency, 1.1);
    });

    // TC-229
    test('copyWith modifies fields', () {
      const sw = StateWeighting();
      final copied = sw.copyWith(urgency: 0.9);
      expect(copied.urgency, 0.9);
      expect(copied.riskSensitivity, 0.5);
    });

    // TC-229a: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      const sw = StateWeighting(urgency: 0.7, confidence: 0.3);
      final copied = sw.copyWith();
      expect(copied.urgency, sw.urgency);
      expect(copied.riskSensitivity, sw.riskSensitivity);
      expect(copied.confidence, sw.confidence);
      expect(copied.emotionalIntensity, sw.emotionalIntensity);
    });

    // TC-229b: copyWith accepts out-of-range values (no validation at contract layer)
    test('copyWith accepts out-of-range values (no contract-layer validation)',
        () {
      const sw = StateWeighting();
      final copied = sw.copyWith(urgency: 1.5);
      expect(copied.urgency, 1.5);
    });

    test('toJson/fromJson round-trip', () {
      const sw = StateWeighting(
        urgency: 0.95,
        riskSensitivity: 0.3,
        confidence: 0.7,
        emotionalIntensity: 0.2,
      );
      final json = sw.toJson();
      final restored = StateWeighting.fromJson(json);
      expect(restored.urgency, 0.95);
      expect(restored.riskSensitivity, 0.3);
      expect(restored.confidence, 0.7);
      expect(restored.emotionalIntensity, 0.2);
    });

    test('fromJson uses defaults for missing values', () {
      final sw = StateWeighting.fromJson(const {});
      expect(sw.urgency, 0.5);
      expect(sw.riskSensitivity, 0.5);
    });

    test('equality', () {
      const a = StateWeighting(urgency: 0.8);
      const b = StateWeighting(urgency: 0.8);
      expect(a, equals(b));
    });
  });
}
