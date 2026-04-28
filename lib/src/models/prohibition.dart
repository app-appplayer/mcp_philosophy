import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for Prohibition additional behavior.
extension ProhibitionExtensions on Prohibition {
  /// Validate Prohibition constraints.
  void validate() {
    if (id.isEmpty) {
      throw ArgumentError.value(
          id, 'id', 'Prohibition id must not be empty');
    }
    if (statement.isEmpty) {
      throw ArgumentError.value(
          statement, 'statement', 'Prohibition statement must not be empty');
    }
  }

  /// Check if an exception applies given a justification context.
  bool hasApplicableException(String context) {
    if (!hasExceptions) return false;
    return exceptions!.any(
      (e) => context.contains(e.condition),
    );
  }

  /// Create a copy with modified fields.
  Prohibition copyWith({
    String? id,
    String? statement,
    ProhibitionSeverity? severity,
    String? rationale,
    List<ProhibitionException>? exceptions,
  }) {
    return Prohibition(
      id: id ?? this.id,
      statement: statement ?? this.statement,
      severity: severity ?? this.severity,
      rationale: rationale ?? this.rationale,
      exceptions: exceptions ?? this.exceptions,
    );
  }
}
