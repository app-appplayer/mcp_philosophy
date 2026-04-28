import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

void main() {
  group('Tension', () {
    Tension makeTension({
      TensionSeverity severity = TensionSeverity.medium,
      List<ResolutionOption> options = const [],
    }) {
      return Tension(
        id: 'tension-1',
        source: const TensionSource(opposingLayer: TensionLayer.profile),
        philosophyDirective: 'Collaborate',
        opposingDirective: 'Defensive posture',
        severity: severity,
        description: 'Test tension',
        resolutionOptions: options,
        ethosComponentId: 'da-1',
      );
    }

    // TC-163
    test('isCritical returns true for critical severity', () {
      final t = makeTension(severity: TensionSeverity.critical);
      expect(t.isCritical, isTrue);
    });

    // TC-163a: isCritical returns false for non-critical severities
    test('isCritical returns false for non-critical severity', () {
      final t = makeTension(severity: TensionSeverity.low);
      expect(t.isCritical, isFalse);
    });

    test('isCritical returns false for medium and high severity', () {
      for (final s in [TensionSeverity.medium, TensionSeverity.high]) {
        final t = makeTension(severity: s);
        expect(t.isCritical, isFalse);
      }
    });

    test('isResolvable returns true when options present', () {
      final t = makeTension(options: [
        const ResolutionOption(
          strategy: ResolutionStrategy.compromise,
          description: 'Compromise',
          estimatedConfidence: 0.6,
        ),
      ]);
      expect(t.isResolvable, isTrue);
    });

    test('isResolvable returns false when no options', () {
      final t = makeTension();
      expect(t.isResolvable, isFalse);
    });

    // TC-166a: copyWith preserves unmodified fields
    test('copyWith modifies severity and preserves other fields', () {
      final t = makeTension(severity: TensionSeverity.low);
      final copied = t.copyWith(severity: TensionSeverity.high);
      expect(copied.severity, TensionSeverity.high);
      expect(copied.id, t.id);
      expect(copied.philosophyDirective, t.philosophyDirective);
      expect(copied.opposingDirective, t.opposingDirective);
    });

    // TC-166b: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final t = makeTension(options: [
        const ResolutionOption(
          strategy: ResolutionStrategy.compromise,
          description: 'Compromise',
          estimatedConfidence: 0.6,
        ),
      ]);
      final copied = t.copyWith();
      expect(copied.id, t.id);
      expect(copied.severity, t.severity);
      expect(copied.resolutionOptions.length, t.resolutionOptions.length);
    });

    // TC-166c: copyWith replaces resolutionOptions list when provided
    test('copyWith replaces resolutionOptions list when provided', () {
      final t = makeTension();
      final copied = t.copyWith(resolutionOptions: const [
        ResolutionOption(
          strategy: ResolutionStrategy.philosophyWins,
          description: 'New option',
          estimatedConfidence: 0.9,
        ),
      ]);
      expect(copied.resolutionOptions, hasLength(1));
      expect(copied.resolutionOptions.first.strategy,
          ResolutionStrategy.philosophyWins);
    });

    test('toJson/fromJson round-trip', () {
      final t = makeTension(
        options: [
          const ResolutionOption(
            strategy: ResolutionStrategy.philosophyWins,
            description: 'Override',
            estimatedConfidence: 0.8,
          ),
        ],
      );
      final json = t.toJson();
      final restored = Tension.fromJson(json);
      expect(restored.id, t.id);
      expect(restored.source.opposingLayer, TensionLayer.profile);
      expect(restored.severity, TensionSeverity.medium);
      expect(restored.resolutionOptions, hasLength(1));
      expect(restored.ethosComponentId, 'da-1');
    });

    test('equality by id', () {
      final a = makeTension();
      final b = makeTension(severity: TensionSeverity.critical);
      expect(a.id, equals(b.id));
    });
  });

  group('TensionSource', () {
    test('toJson/fromJson round-trip', () {
      const source = TensionSource(
        opposingLayer: TensionLayer.knowledge,
        primaryComponentId: 'vp-1',
        opposingComponentId: 'k-1',
      );
      final json = source.toJson();
      final restored = TensionSource.fromJson(json);
      expect(restored.primaryLayer, TensionLayer.philosophy);
      expect(restored.opposingLayer, TensionLayer.knowledge);
      expect(restored.primaryComponentId, 'vp-1');
    });
  });

  group('TensionSeverity', () {
    test('fromString falls back to unknown', () {
      expect(TensionSeverity.fromString('x'), TensionSeverity.unknown);
    });
  });

  group('TensionLayer', () {
    test('fromString falls back to unknown', () {
      expect(TensionLayer.fromString('x'), TensionLayer.unknown);
    });
  });
}
