import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('ProhibitionCheckRequest', () {
    test('isValid when proposedAction provided', () {
      final req = ProhibitionCheckRequest(proposedAction: 'action');
      expect(req.isValid, isTrue);
    });

    test('isValid when proposedOutput provided', () {
      final req = ProhibitionCheckRequest(proposedOutput: 'output');
      expect(req.isValid, isTrue);
    });

    test('isValid is false when neither provided', () {
      final req = ProhibitionCheckRequest();
      expect(req.isValid, isFalse);
    });

    test('toJson/fromJson round-trip', () {
      final req = ProhibitionCheckRequest(
        proposedAction: 'action',
        proposedOutput: 'output',
        context: {'key': 'value'},
      );
      final json = req.toJson();
      final restored = ProhibitionCheckRequest.fromJson(json);
      expect(restored.proposedAction, 'action');
      expect(restored.proposedOutput, 'output');
    });
  });

  group('MultiLayerContext', () {
    test('constructs with required fields', () {
      final ctx = MultiLayerContext(
        philosophyContext: testContext(),
      );
      expect(ctx.hasProfileState, isFalse);
      expect(ctx.hasKnowledgeProvenance, isFalse);
    });

    test('hasProfileState returns true when not empty', () {
      final ctx = MultiLayerContext(
        philosophyContext: testContext(),
        profileState: {'posture': 'defensive'},
      );
      expect(ctx.hasProfileState, isTrue);
    });

    test('hasProfileState returns false for empty map', () {
      final ctx = MultiLayerContext(
        philosophyContext: testContext(),
        profileState: const {},
      );
      expect(ctx.hasProfileState, isFalse);
    });

    test('hasKnowledgeProvenance returns true when not empty', () {
      final ctx = MultiLayerContext(
        philosophyContext: testContext(),
        knowledgeProvenance: {'source': 'verified'},
      );
      expect(ctx.hasKnowledgeProvenance, isTrue);
    });

    test('toJson/fromJson round-trip', () {
      final ctx = MultiLayerContext(
        philosophyContext: testContext(),
        profileState: {'posture': 'neutral'},
        stateWeighting: {'urgency': 0.5},
      );
      final json = ctx.toJson();
      final restored = MultiLayerContext.fromJson(json);
      expect(restored.philosophyContext.contextId, 'ctx-1');
      expect(restored.profileState?['posture'], 'neutral');
    });
  });

  group('PhilosophyPort', () {
    test('detectTensions throws UnsupportedError by default', () {
      final port = _TestPhilosophyPort();
      expect(
        () => port.detectTensions(
          MultiLayerContext(philosophyContext: testContext()),
        ),
        throwsUnsupportedError,
      );
    });

    test('proposeFeedback throws UnsupportedError by default', () {
      final port = _TestPhilosophyPort();
      expect(
        () => port.proposeFeedback(testFeedbackEvent()),
        throwsUnsupportedError,
      );
    });
  });
}

/// Minimal port implementation for testing default method behavior.
class _TestPhilosophyPort extends PhilosophyPort {
  @override
  Future<ProhibitionCheckResult> checkProhibitions(
      ProhibitionCheckRequest request) async {
    return ProhibitionCheckResult.allPassed(const []);
  }

  @override
  Future<PhilosophyGuidance> evaluate(EvaluationContext context) async {
    throw UnimplementedError();
  }

  @override
  Future<Ethos> getEthos() async {
    throw UnimplementedError();
  }

  @override
  Future<InterventionResult> intervene(
      InterventionPoint point, PipelineContext context) async {
    throw UnimplementedError();
  }
}
