import 'package:mcp_bundle/mcp_bundle.dart';

/// Resolves value conflicts between two priorities.
///
/// Lower rank number = higher priority. Conditional priorities
/// may override rank-based resolution when context matches.
class ConflictResolver {
  const ConflictResolver();

  /// Resolve a value conflict by rank order.
  ValueResolution resolve(
    ValuePriority a,
    ValuePriority b,
    PhilosophyEvaluationContext context,
  ) {
    final aApplies = _checkConditions(a.conditions, context);
    final bApplies = _checkConditions(b.conditions, context);

    if (a.isConditional && b.isConditional) {
      if (aApplies && !bApplies) {
        return ValueResolution(
          winner: a,
          loser: b,
          rationale:
              '${a.higherValue} wins: conditional context matched for ${a.id}',
          contextDependent: true,
          appliedCondition: a.conditions!.first,
        );
      }
      if (bApplies && !aApplies) {
        return ValueResolution(
          winner: b,
          loser: a,
          rationale:
              '${b.higherValue} wins: conditional context matched for ${b.id}',
          contextDependent: true,
          appliedCondition: b.conditions!.first,
        );
      }
    }

    if (a.isConditional && aApplies && !b.isConditional) {
      return ValueResolution(
        winner: a,
        loser: b,
        rationale:
            '${a.higherValue} wins: conditional override in current context',
        contextDependent: true,
        appliedCondition: a.conditions!.first,
      );
    }
    if (b.isConditional && bApplies && !a.isConditional) {
      return ValueResolution(
        winner: b,
        loser: a,
        rationale:
            '${b.higherValue} wins: conditional override in current context',
        contextDependent: true,
        appliedCondition: b.conditions!.first,
      );
    }

    final winner = a.rank <= b.rank ? a : b;
    final loser = a.rank <= b.rank ? b : a;
    return ValueResolution(
      winner: winner,
      loser: loser,
      rationale:
          '${winner.higherValue} prioritized over ${loser.higherValue} by rank order',
    );
  }

  bool _checkConditions(
      List<String>? conditions, PhilosophyEvaluationContext context) {
    if (conditions == null || conditions.isEmpty) return false;
    return conditions.any((condition) {
      for (final entry in context.facts.entries) {
        if (condition.contains(entry.key) &&
            condition.contains(entry.value.toString())) {
          return true;
        }
      }
      return false;
    });
  }
}
