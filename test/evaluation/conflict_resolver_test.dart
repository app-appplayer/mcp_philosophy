import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  const resolver = ConflictResolver();

  group('ConflictResolver', () {
    test('lower rank wins by default', () {
      final a = testValuePriority(id: 'vp-a', rank: 1);
      final b = testValuePriority(id: 'vp-b', rank: 2);

      final result = resolver.resolve(a, b, testContext());
      expect(result.winner.id, 'vp-a');
      expect(result.loser?.id, 'vp-b');
      expect(result.contextDependent, isFalse);
    });

    test('higher rank loses', () {
      final a = testValuePriority(id: 'vp-a', rank: 3);
      final b = testValuePriority(id: 'vp-b', rank: 1);

      final result = resolver.resolve(a, b, testContext());
      expect(result.winner.id, 'vp-b');
      expect(result.loser?.id, 'vp-a');
    });

    test('conditional priority wins when context matches (both conditional)',
        () {
      final a = testValuePriority(
        id: 'vp-a',
        rank: 2,
        conditions: ['domain == "emergency"'],
      );
      final b = testValuePriority(
        id: 'vp-b',
        rank: 1,
        conditions: ['domain == "normal"'],
      );

      final context = testContext(facts: {'domain': 'emergency'});
      final result = resolver.resolve(a, b, context);
      expect(result.winner.id, 'vp-a');
      expect(result.contextDependent, isTrue);
    });

    test('conditional priority overrides non-conditional when context matches',
        () {
      final a = testValuePriority(
        id: 'vp-a',
        rank: 2,
        conditions: ['domain == "emergency"'],
      );
      final b = testValuePriority(id: 'vp-b', rank: 1);

      final context = testContext(facts: {'domain': 'emergency'});
      final result = resolver.resolve(a, b, context);
      expect(result.winner.id, 'vp-a');
      expect(result.contextDependent, isTrue);
    });

    test('falls back to rank when conditional does not match', () {
      final a = testValuePriority(
        id: 'vp-a',
        rank: 2,
        conditions: ['domain == "emergency"'],
      );
      final b = testValuePriority(id: 'vp-b', rank: 1);

      final context = testContext(facts: {'domain': 'education'});
      final result = resolver.resolve(a, b, context);
      expect(result.winner.id, 'vp-b');
      expect(result.contextDependent, isFalse);
    });

    // TC-080c: equal ranks -> deterministic (first argument wins)
    test('equal ranks returns first argument as winner (deterministic)', () {
      final a = testValuePriority(id: 'vp-a', rank: 5);
      final b = testValuePriority(id: 'vp-b', rank: 5);

      final result = resolver.resolve(a, b, testContext());
      expect(result.winner.id, 'vp-a');
      expect(result.loser?.id, 'vp-b');
      expect(result.contextDependent, isFalse);
    });
  });

  group('ValueResolution', () {
    test('toJson/fromJson round-trip', () {
      final vr = ValueResolution(
        winner: testValuePriority(id: 'vp-1'),
        loser: testValuePriority(id: 'vp-2', rank: 2),
        rationale: 'Rank order',
        contextDependent: true,
        appliedCondition: 'emergency',
      );
      final json = vr.toJson();
      final restored = ValueResolution.fromJson(json);
      expect(restored.winner.id, 'vp-1');
      expect(restored.loser?.id, 'vp-2');
      expect(restored.contextDependent, isTrue);
      expect(restored.appliedCondition, 'emergency');
    });
  });
}
