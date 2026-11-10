/// Persisted feedback history, stored proposals, and applying a proposal a
/// human approved.
library;

import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

FeedbackEvent fb(String id, String vp, double score, int minute) =>
    FeedbackEvent(
      id: id,
      actionId: 'a',
      ethosId: 'test-ethos-full',
      valuePriorityId: vp,
      outcome: score >= 0 ? FeedbackOutcome.positive : FeedbackOutcome.negative,
      outcomeScore: score,
      occurredAt: testTime.add(Duration(minutes: minute)),
    );

class Published implements EventPort {
  final List<PortEvent> events = [];

  @override
  Future<void> publish(PortEvent event) async => events.add(event);

  @override
  Stream<PortEvent> subscribe(String eventType) => const Stream.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late InMemoryKvStoragePort kv;
  late KvEthosStoreAdapter ethosStore;

  Future<void> seed() async {
    final ethos = fullTestEthos();
    await ethosStore.putEthos(EthosRecord(
      id: ethos.id,
      name: ethos.name,
      version: '1.0.0',
      payload: ethos.toJson(),
      createdAt: testTime,
      active: true,
    ));
    await ethosStore.activateEthos(ethos.id);
  }

  PhilosophyEngine engine({
    FeedbackHistoryStore? history,
    ProposalStore? proposals,
    EventPort? events,
    int? historyLimit,
  }) =>
      PhilosophyEngine(
        ethosStore: ethosStore,
        feedbackHistory: history,
        proposals: proposals,
        events: events,
        historyLimit: historyLimit,
        autoSeedEthos: false,
      );

  Future<EvolutionProposal> proposalFor(PhilosophyEngine e, String vp,
      {double score = 0.9}) async {
    EvolutionProposal? p;
    for (var i = 0; i < 3; i++) {
      p = await e.proposeFeedback(fb('$vp-$i', vp, score, i));
    }
    return p!;
  }

  setUp(() async {
    kv = InMemoryKvStoragePort();
    ethosStore = KvEthosStoreAdapter(storage: kv);
    await seed();
  });

  group('history counting', () {
    test('two events are not enough for a proposal; the third is', () async {
      final e = engine();
      expect(await e.proposeFeedback(fb('a', 'vp-2', 0.9, 1)), isNull);
      expect(await e.proposeFeedback(fb('b', 'vp-2', 0.9, 2)), isNull);
      expect(await e.proposeFeedback(fb('c', 'vp-2', 0.9, 3)), isNotNull);
    });

    test('history in a Kv store survives a new engine', () async {
      final first = engine(history: KvFeedbackHistoryStore(storage: kv));
      await first.proposeFeedback(fb('a', 'vp-2', 0.9, 1));
      await first.proposeFeedback(fb('b', 'vp-2', 0.9, 2));

      final restarted = engine(history: KvFeedbackHistoryStore(storage: kv));
      expect(
          await restarted.proposeFeedback(fb('c', 'vp-2', 0.9, 3)), isNotNull);
    });

    test('without a shared store a new engine starts empty', () async {
      await engine().proposeFeedback(fb('a', 'vp-2', 0.9, 1));
      await engine().proposeFeedback(fb('b', 'vp-2', 0.9, 2));
      expect(await engine().proposeFeedback(fb('c', 'vp-2', 0.9, 3)), isNull);
    });

    test('historyLimit bounds the old events that count', () async {
      final e = engine(historyLimit: 1);
      await e.proposeFeedback(fb('a', 'vp-2', 0.9, 1));
      await e.proposeFeedback(fb('b', 'vp-2', 0.9, 2));
      expect(await e.proposeFeedback(fb('c', 'vp-2', 0.9, 3)), isNull);
    });
  });

  group('stored proposals', () {
    test('a generated proposal is stored pending and listed', () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-2');
      final listed = await e.listProposals(status: ProposalStatus.pending);
      expect(listed.map((x) => x.id), [p.id]);
    });

    test('proposals in a Kv store survive a new engine', () async {
      final p = await proposalFor(
          engine(proposals: KvProposalStore(storage: kv)), 'vp-2');
      final again = engine(proposals: KvProposalStore(storage: kv));
      expect((await again.listProposals()).single.id, p.id);
    });
  });

  group('applyProposal', () {
    Future<List<String>> orderOf(EthosRecord r) async =>
        (Ethos.fromJson(r.payload).valuePriorities
              ..sort((a, b) => a.rank.compareTo(b.rank)))
            .map((v) => v.id)
            .toList();

    test('reinforce moves the priority up and stores a new inactive ethos',
        () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-2');
      expect(p.type, EvolutionType.reinforce);

      final record = await e.applyProposal(p.id, approvedBy: 'user:jsha');
      expect(await orderOf(record), ['vp-2', 'vp-1']);
      expect(record.active, isFalse);
      expect(record.id, 'test-ethos-full.evo.${p.id}');
      final prov = record.payload['provenance'] as Map;
      expect(prov['kind'], 'derived');
      expect(prov['serves'], 'vp-2');
      expect(prov['derivedFrom'], 'test-ethos-full');
      expect(prov['proposalId'], p.id);
      expect(prov['approvedBy'], 'user:jsha');
      expect(DateTime.tryParse(prov['approvedAt'] as String), isNotNull);
    });

    test('ranks are renumbered 1..n', () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-2');
      final record = await e.applyProposal(p.id, approvedBy: 'u');
      final ranks = Ethos.fromJson(record.payload)
          .valuePriorities
          .map((v) => v.rank)
          .toList()
        ..sort();
      expect(ranks, [1, 2]);
    });

    test('the source ethos and the active pointer are not touched', () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-2');
      await e.applyProposal(p.id, approvedBy: 'u');
      final source = await ethosStore.getEthos('test-ethos-full');
      expect(
          Ethos.fromJson(source!.payload)
              .valuePriorities
              .firstWhere((v) => v.id == 'vp-1')
              .rank,
          1);
      expect(await ethosStore.getActiveEthosId(), 'test-ethos-full');
    });

    test('the proposal becomes applied and cannot be applied twice', () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-2');
      await e.applyProposal(p.id, approvedBy: 'u');
      expect((await e.listProposals()).single.status, ProposalStatus.applied);
      expect(() => e.applyProposal(p.id, approvedBy: 'u'), throwsStateError);
    });

    test('weaken moves the priority down', () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-1', score: -0.9);
      expect(p.type, EvolutionType.weaken);
      final record = await e.applyProposal(p.id, approvedBy: 'u');
      expect(await orderOf(record), ['vp-2', 'vp-1']);
    });

    test('an approver is required', () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-2');
      expect(
          () => e.applyProposal(p.id, approvedBy: '  '), throwsArgumentError);
      expect((await e.listProposals()).single.status, ProposalStatus.pending);
    });

    test('an unknown proposal throws', () async {
      expect(() => engine().applyProposal('nope', approvedBy: 'u'),
          throwsStateError);
    });

    test(
        'a move with nowhere to go is not proposed: reinforce at the top, '
        'weaken at the bottom', () async {
      final history = InMemoryFeedbackHistoryStore();
      final e = engine(history: history);
      EvolutionProposal? top;
      for (var i = 0; i < 3; i++) {
        top = await e.proposeFeedback(fb('top-$i', 'vp-1', 0.9, i));
      }
      expect(top, isNull);
      EvolutionProposal? bottom;
      for (var i = 0; i < 3; i++) {
        bottom = await e.proposeFeedback(fb('bot-$i', 'vp-2', -0.9, i));
      }
      expect(bottom, isNull);
      expect(await e.listProposals(), isEmpty);
      // The feedback itself is kept: history is not conditional on a
      // proposal.
      expect(await history.recent(limit: 10), hasLength(6));
    });

    test('a hand-made proposal that cannot move is refused, not applied',
        () async {
      final store = InMemoryProposalStore();
      await store.save(EvolutionProposal(
        id: 'p-top',
        ethosId: 'test-ethos-full',
        type: EvolutionType.reinforce,
        targetComponentId: 'vp-1',
        targetComponentType: 'valuePriority',
        description: 'd',
        rationale: 'r',
        confidence: 0.9,
      ));
      final e = engine(proposals: store);
      expect(() => e.applyProposal('p-top', approvedBy: 'u'), throwsStateError);
      expect((await e.listProposals()).single.status, ProposalStatus.pending);
    });

    test('a proposal with no mechanical meaning is unsupported', () async {
      final store = InMemoryProposalStore();
      await store.save(EvolutionProposal(
        id: 'p-crit',
        ethosId: 'test-ethos-full',
        type: EvolutionType.refine,
        targetComponentId: 'jc-1',
        targetComponentType: 'judgmentCriterion',
        description: 'd',
        rationale: 'r',
        confidence: 0.9,
      ));
      expect(
          () =>
              engine(proposals: store).applyProposal('p-crit', approvedBy: 'u'),
          throwsUnsupportedError);
    });

    test('the event port hears about an applied proposal', () async {
      final events = Published();
      final e = engine(events: events);
      final p = await proposalFor(e, 'vp-2');
      await e.applyProposal(p.id, approvedBy: 'u');
      expect(events.events.last.type, 'philosophy.proposal_applied');
      expect(events.events.last.payload['proposalId'], p.id);
    });
  });

  group('rejectProposal', () {
    test('marks it rejected, needs a reviewer, and closes it', () async {
      final e = engine();
      final p = await proposalFor(e, 'vp-2');
      expect(() => e.rejectProposal(p.id, rejectedBy: ''), throwsArgumentError);
      final r = await e.rejectProposal(p.id, rejectedBy: 'user:jsha');
      expect(r.status, ProposalStatus.rejected);
      expect(() => e.applyProposal(p.id, approvedBy: 'u'), throwsStateError);
    });
  });
}
