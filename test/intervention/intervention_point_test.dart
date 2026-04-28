import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

void main() {
  group('InterventionPoint', () {
    test('has all expected values', () {
      expect(InterventionPoint.values, hasLength(4));
      expect(
        InterventionPoint.values,
        containsAll([
          InterventionPoint.preGeneration,
          InterventionPoint.duringGeneration,
          InterventionPoint.postGeneration,
          InterventionPoint.unknown,
        ]),
      );
    });

    test('fromString falls back to unknown', () {
      expect(
        InterventionPoint.fromString('nonexistent'),
        InterventionPoint.unknown,
      );
    });

    test('fromString parses known values', () {
      expect(
        InterventionPoint.fromString('preGeneration'),
        InterventionPoint.preGeneration,
      );
    });
  });

  group('PipelineContext', () {
    test('constructs with required fields', () {
      final ctx = PipelineContext(
        pipelineId: 'pipe-1',
        currentPoint: InterventionPoint.preGeneration,
      );
      expect(ctx.pipelineId, 'pipe-1');
      expect(ctx.currentPoint, InterventionPoint.preGeneration);
      expect(ctx.knowledgeRetrieved, isEmpty);
    });

    // TC-126a: construction with empty maps succeeds (no constructor validation)
    test('constructs with empty maps succeeds (no constructor validation)',
        () {
      final ctx = PipelineContext(
        pipelineId: 'pipe-empty',
        currentPoint: InterventionPoint.preGeneration,
        skillContext: const {},
        stateWeighting: const {},
      );
      expect(ctx.skillContext, isEmpty);
      expect(ctx.stateWeighting, isEmpty);
    });

    test('toJson/fromJson round-trip', () {
      final ctx = PipelineContext(
        pipelineId: 'pipe-1',
        currentPoint: InterventionPoint.duringGeneration,
        candidateResponses: ['a', 'b'],
        generatedOutput: 'output',
        skillContext: {'key': 'value'},
        stateWeighting: {'urgency': 0.8},
      );
      final json = ctx.toJson();
      final restored = PipelineContext.fromJson(json);
      expect(restored.pipelineId, 'pipe-1');
      expect(restored.currentPoint, InterventionPoint.duringGeneration);
      expect(restored.candidateResponses, ['a', 'b']);
      expect(restored.generatedOutput, 'output');
      expect(restored.stateWeighting?['urgency'], 0.8);
    });

    // TC-127a: copyWith preserves unmodified fields
    test('copyWith modifies fields', () {
      final ctx = PipelineContext(
        pipelineId: 'pipe-1',
        currentPoint: InterventionPoint.preGeneration,
      );
      final copied = ctx.copyWith(generatedOutput: 'new output');
      expect(copied.generatedOutput, 'new output');
      expect(copied.pipelineId, 'pipe-1');
      expect(copied.currentPoint, ctx.currentPoint);
    });

    // TC-127b: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final ctx = PipelineContext(
        pipelineId: 'pipe-2',
        currentPoint: InterventionPoint.postGeneration,
        candidateResponses: ['x', 'y'],
        generatedOutput: 'text',
      );
      final copied = ctx.copyWith();
      expect(copied.pipelineId, ctx.pipelineId);
      expect(copied.currentPoint, ctx.currentPoint);
      expect(copied.candidateResponses, ctx.candidateResponses);
      expect(copied.generatedOutput, ctx.generatedOutput);
    });
  });
}
