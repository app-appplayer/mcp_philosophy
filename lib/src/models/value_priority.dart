import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for ValuePriority additional behavior.
extension ValuePriorityExtensions on ValuePriority {
  /// Validate ValuePriority constraints.
  void validate() {
    if (id.isEmpty) {
      throw ArgumentError.value(
          id, 'id', 'ValuePriority id must not be empty');
    }
    if (rank <= 0) {
      throw ArgumentError.value(
          rank, 'rank', 'ValuePriority rank must be > 0');
    }
  }

  /// Create a copy with modified fields.
  ValuePriority copyWith({
    String? id,
    int? rank,
    String? higherValue,
    String? lowerValue,
    String? rationale,
    List<String>? conditions,
  }) {
    return ValuePriority(
      id: id ?? this.id,
      rank: rank ?? this.rank,
      higherValue: higherValue ?? this.higherValue,
      lowerValue: lowerValue ?? this.lowerValue,
      rationale: rationale ?? this.rationale,
      conditions: conditions ?? this.conditions,
    );
  }
}
