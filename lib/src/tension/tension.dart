import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for Tension additional behavior.
extension TensionExtensions on Tension {
  /// Create a copy with modified fields.
  Tension copyWith({
    String? id,
    TensionSource? source,
    String? philosophyDirective,
    String? opposingDirective,
    TensionSeverity? severity,
    String? description,
    List<ResolutionOption>? resolutionOptions,
    String? ethosComponentId,
    DateTime? detectedAt,
  }) {
    return Tension(
      id: id ?? this.id,
      source: source ?? this.source,
      philosophyDirective: philosophyDirective ?? this.philosophyDirective,
      opposingDirective: opposingDirective ?? this.opposingDirective,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      resolutionOptions: resolutionOptions ?? this.resolutionOptions,
      ethosComponentId: ethosComponentId ?? this.ethosComponentId,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }
}
