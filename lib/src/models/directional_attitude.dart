import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for DirectionalAttitude additional behavior.
extension DirectionalAttitudeExtensions on DirectionalAttitude {
  /// Validate DirectionalAttitude constraints.
  void validate() {
    if (id.isEmpty) {
      throw ArgumentError.value(
          id, 'id', 'DirectionalAttitude id must not be empty');
    }
  }

  /// Create a copy with modified fields.
  DirectionalAttitude copyWith({
    String? id,
    AttitudeDomain? domain,
    String? posture,
    List<String>? behavioralImplications,
  }) {
    return DirectionalAttitude(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      posture: posture ?? this.posture,
      behavioralImplications:
          behavioralImplications ?? this.behavioralImplications,
    );
  }
}
