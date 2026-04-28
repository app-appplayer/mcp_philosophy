import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

void main() {
  EvolutionProposal makeProposal({
    double confidence = 0.8,
    ProposalStatus status = ProposalStatus.pending,
    List<String> feedbackIds = const ['fb-1', 'fb-2'],
  }) {
    return EvolutionProposal(
      id: 'prop-1',
      ethosId: 'ethos-1',
      type: EvolutionType.reinforce,
      targetComponentId: 'vp-1',
      targetComponentType: 'valuePriority',
      description: 'Reinforce vp-1',
      rationale: 'Consistent positive feedback',
      supportingFeedbackIds: feedbackIds,
      confidence: confidence,
      proposedChange: const ProposedChange(
        before: {'rank': 1},
        after: {'rank': 1, 'reinforced': true},
        diff: 'Mark as reinforced',
      ),
      status: status,
    );
  }

  group('EvolutionProposal', () {
    test('hasSufficientConfidence >= 0.7', () {
      expect(makeProposal(confidence: 0.7).hasSufficientConfidence, isTrue);
      expect(makeProposal(confidence: 0.9).hasSufficientConfidence, isTrue);
      expect(makeProposal(confidence: 0.5).hasSufficientConfidence, isFalse);
    });

    test('isPending', () {
      expect(makeProposal(status: ProposalStatus.pending).isPending, isTrue);
      expect(makeProposal(status: ProposalStatus.approved).isPending, isFalse);
    });

    // TC-189a: isPending returns false for all non-pending statuses
    test('isPending returns false for approved/rejected/applied', () {
      expect(makeProposal(status: ProposalStatus.approved).isPending, isFalse);
      expect(makeProposal(status: ProposalStatus.rejected).isPending, isFalse);
      expect(makeProposal(status: ProposalStatus.applied).isPending, isFalse);
    });

    test('supportCount', () {
      expect(makeProposal(feedbackIds: ['a', 'b', 'c']).supportCount, 3);
      expect(makeProposal(feedbackIds: []).supportCount, 0);
    });

    // TC-190a: supportCount returns 0 for empty supportingFeedbackIds
    test('supportCount returns 0 for empty supportingFeedbackIds', () {
      expect(makeProposal(feedbackIds: []).supportCount, 0);
    });

    test('status defaults to pending', () {
      final p = makeProposal();
      expect(p.status, ProposalStatus.pending);
    });

    // TC-192a: copyWith preserves unmodified fields
    test('copyWith modifies fields', () {
      final p = makeProposal();
      final approved = p.copyWith(status: ProposalStatus.approved);
      expect(approved.status, ProposalStatus.approved);
      expect(approved.id, p.id);
      expect(approved.confidence, p.confidence);
    });

    // TC-192b: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final p = makeProposal();
      final copied = p.copyWith();
      expect(copied.id, p.id);
      expect(copied.ethosId, p.ethosId);
      expect(copied.status, p.status);
      expect(copied.confidence, p.confidence);
    });

    // TC-192c: copyWith replaces status when provided
    test('copyWith replaces status when provided', () {
      final p = makeProposal(status: ProposalStatus.pending);
      final copied = p.copyWith(status: ProposalStatus.rejected);
      expect(copied.status, ProposalStatus.rejected);
      expect(copied.id, p.id);
    });

    test('toJson/fromJson round-trip', () {
      final p = makeProposal();
      final json = p.toJson();
      final restored = EvolutionProposal.fromJson(json);
      expect(restored.id, p.id);
      expect(restored.type, EvolutionType.reinforce);
      expect(restored.targetComponentId, 'vp-1');
      expect(restored.confidence, p.confidence);
      expect(restored.status, ProposalStatus.pending);
      expect(restored.proposedChange, isNotNull);
      expect(restored.proposedChange!.diff, 'Mark as reinforced');
    });
  });

  group('ProposedChange', () {
    test('toJson/fromJson round-trip', () {
      const pc = ProposedChange(
        before: {'rank': 1},
        after: {'rank': 1, 'reinforced': true},
        diff: 'Reinforced',
      );
      final json = pc.toJson();
      final restored = ProposedChange.fromJson(json);
      expect(restored.before, isNotNull);
      expect(restored.after?['reinforced'], true);
      expect(restored.diff, 'Reinforced');
    });
  });

  group('EvolutionRecord', () {
    test('toJson/fromJson round-trip', () {
      final record = EvolutionRecord(
        id: 'rec-1',
        ethosId: 'ethos-1',
        proposal: makeProposal(status: ProposalStatus.applied),
        finalStatus: ProposalStatus.applied,
        reviewerNote: 'Approved by domain expert',
      );
      final json = record.toJson();
      final restored = EvolutionRecord.fromJson(json);
      expect(restored.id, 'rec-1');
      expect(restored.finalStatus, ProposalStatus.applied);
      expect(restored.reviewerNote, 'Approved by domain expert');
      expect(restored.proposal.id, 'prop-1');
    });
  });

  group('EvolutionType', () {
    test('fromString falls back to unknown', () {
      expect(EvolutionType.fromString('x'), EvolutionType.unknown);
    });

    test('has 6 values', () {
      expect(EvolutionType.values, hasLength(6));
    });
  });

  group('ProposalStatus', () {
    test('fromString falls back to unknown', () {
      expect(ProposalStatus.fromString('x'), ProposalStatus.unknown);
    });
  });
}
