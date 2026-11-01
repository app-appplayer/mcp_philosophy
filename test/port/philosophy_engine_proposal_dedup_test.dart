/// One open proposal per target: fresh evidence for a change nobody has
/// decided yet updates the pending proposal instead of adding another.
library;

import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

FeedbackEvent fb(String id, String vp, int minute, {double score = 0.9}) =>
    FeedbackEvent(
      id: id,
      actionId: 'a',
      ethosId: 'test-ethos-full',
      valuePriorityId: vp,
      outcome:
          score >= 0 ? FeedbackOutcome.positive : FeedbackOutcome.negative,
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
  late PhilosophyEngine engine;
  late Published published;

  setUp(() async {
    final store = KvEthosStoreAdapter(storage: InMemoryKvStoragePort());
    final ethos = fullTestEthos();
    await store.putEthos(EthosRecord(
      id: ethos.id,
      name: ethos.name,
      version: '1.0.0',
      payload: ethos.toJson(),
      createdAt: testTime,
      active: true,
    ));
    await store.activateEthos(ethos.id);
    published = Published();
    engine = PhilosophyEngine(
      ethosStore: store,
      events: published,
      autoSeedEthos: false,
    );
  });

  Future<EvolutionProposal> feed(String vp, int from, int to) async {
    EvolutionProposal? last;
    for (var i = from; i <= to; i++) {
      last = await engine.proposeFeedback(fb('$vp-$i', vp, i));
    }
    return last!;
  }

  test('more events for the same target update the pending proposal',
      () async {
    final first = await feed('vp-2', 1, 3);
    final later = await feed('vp-2', 4, 6);

    final all = await engine.listProposals();
    expect(all, hasLength(1));
    expect(all.single.id, first.id);
    expect(later.id, first.id);
    expect(all.single.proposedAt, first.proposedAt);
    expect(all.single.rationale, contains('6 feedback events'));
    expect(all.single.supportingFeedbackIds,
        ['vp-2-3', 'vp-2-4', 'vp-2-5', 'vp-2-6']);
    expect(all.single.status, ProposalStatus.pending);
  });

  test('the proposed event is published once, when the proposal is created',
      () async {
    await feed('vp-2', 1, 6);
    expect(
        published.events.where((e) => e.type == 'philosophy.feedback_proposed'),
        hasLength(1));
  });

  test('a different target gets its own proposal', () async {
    await feed('vp-2', 1, 3);
    await feed('vp-1', 1, 3);
    final all = await engine.listProposals();
    expect(all.map((p) => p.targetComponentId).toSet(), hasLength(2));
  });

  test('after a person decides, new evidence opens a new pending proposal',
      () async {
    final first = await feed('vp-2', 1, 3);
    await engine.rejectProposal(first.id, rejectedBy: 'reviewer');
    final again = await feed('vp-2', 4, 4);

    expect(again.id, isNot(first.id));
    final pending = await engine.listProposals(status: ProposalStatus.pending);
    expect(pending.map((p) => p.id), [again.id]);
    expect(
        (await engine.listProposals(status: ProposalStatus.rejected))
            .map((p) => p.id),
        [first.id]);
  });
}
