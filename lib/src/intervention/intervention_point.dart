import 'package:mcp_bundle/mcp_bundle.dart';

extension PipelineContextExtensions on PipelineContext {
  /// Create a copy with modified fields.
  PipelineContext copyWith({
    String? pipelineId,
    InterventionPoint? currentPoint,
    Map<String, dynamic>? knowledgeRetrieved,
    List<String>? candidateResponses,
    String? generatedOutput,
    Map<String, dynamic>? skillContext,
    Map<String, dynamic>? profileContext,
    Map<String, double>? stateWeighting,
    DateTime? timestamp,
  }) {
    return PipelineContext(
      pipelineId: pipelineId ?? this.pipelineId,
      currentPoint: currentPoint ?? this.currentPoint,
      knowledgeRetrieved: knowledgeRetrieved ?? this.knowledgeRetrieved,
      candidateResponses: candidateResponses ?? this.candidateResponses,
      generatedOutput: generatedOutput ?? this.generatedOutput,
      skillContext: skillContext ?? this.skillContext,
      profileContext: profileContext ?? this.profileContext,
      stateWeighting: stateWeighting ?? this.stateWeighting,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
