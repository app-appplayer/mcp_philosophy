import 'package:mcp_bundle/mcp_bundle.dart';

/// Extensions for EthosMetadata additional behavior.
extension EthosMetadataExtensions on EthosMetadata {
  /// Create a copy with modified fields.
  EthosMetadata copyWith({
    String? version,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? context,
    List<String>? tags,
  }) {
    return EthosMetadata(
      version: version ?? this.version,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      context: context ?? this.context,
      tags: tags ?? this.tags,
    );
  }
}
