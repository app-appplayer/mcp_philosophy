import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

void main() {
  group('TensionResolution', () {
    test('toJson/fromJson round-trip', () {
      final tr = TensionResolution(
        tensionId: 't-1',
        strategy: ResolutionStrategy.compromise,
        outcome: 'Compromised',
        confidence: 0.65,
        adjustments: {'philosophyWeight': 0.6, 'opposingWeight': 0.4},
      );
      final json = tr.toJson();
      final restored = TensionResolution.fromJson(json);
      expect(restored.tensionId, 't-1');
      expect(restored.strategy, ResolutionStrategy.compromise);
      expect(restored.confidence, 0.65);
      expect(restored.adjustments?['philosophyWeight'], 0.6);
    });
  });

  group('ResolutionOption', () {
    test('toJson/fromJson round-trip', () {
      const opt = ResolutionOption(
        strategy: ResolutionStrategy.contextDependent,
        description: 'Evaluate context',
        estimatedConfidence: 0.7,
      );
      final json = opt.toJson();
      final restored = ResolutionOption.fromJson(json);
      expect(restored.strategy, ResolutionStrategy.contextDependent);
      expect(restored.description, 'Evaluate context');
      expect(restored.estimatedConfidence, 0.7);
    });
  });

  group('ResolutionStrategy', () {
    test('fromString falls back to unknown', () {
      expect(
        ResolutionStrategy.fromString('nonexistent'),
        ResolutionStrategy.unknown,
      );
    });

    test('fromString parses known values', () {
      expect(
        ResolutionStrategy.fromString('philosophyWins'),
        ResolutionStrategy.philosophyWins,
      );
    });
  });
}
