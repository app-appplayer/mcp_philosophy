/// In-memory and Kv implementations of the feedback-history and proposal
/// stores.
library;

import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

/// In-memory KV that counts value reads and key scans.
class _CountingKv implements KvStoragePort {
  final InMemoryKvStoragePort _inner = InMemoryKvStoragePort();
  int gets = 0;
  int keyScans = 0;

  @override
  Future<void> set(String key, dynamic value) => _inner.set(key, value);

  @override
  Future<dynamic> get(String key) {
    gets++;
    return _inner.get(key);
  }

  @override
  Future<void> remove(String key) => _inner.remove(key);

  @override
  Future<bool> exists(String key) => _inner.exists(key);

  @override
  Future<List<String>> keys({String? prefix}) {
    keyScans++;
    return _inner.keys(prefix: prefix);
  }

  @override
  Future<void> clear() => _inner.clear();
}

FeedbackEvent fb(String id, int minute) => FeedbackEvent(
      id: id,
      actionId: 'a',
      ethosId: 'e',
      valuePriorityId: 'vp-1',
      outcome: FeedbackOutcome.positive,
      outcomeScore: 0.9,
      occurredAt: testTime.add(Duration(minutes: minute)),
    );

EvolutionProposal prop(String id,
        {String ethosId = 'e',
        ProposalStatus status = ProposalStatus.pending,
        int minute = 0}) =>
    EvolutionProposal(
      id: id,
      ethosId: ethosId,
      type: EvolutionType.reinforce,
      targetComponentId: 'vp-1',
      targetComponentType: 'valuePriority',
      description: 'd',
      rationale: 'r',
      confidence: 0.8,
      status: status,
      proposedAt: testTime.add(Duration(minutes: minute)),
    );

void main() {
  final histories = <String, FeedbackHistoryStore Function()>{
    'in memory': InMemoryFeedbackHistoryStore.new,
    'kv': () => KvFeedbackHistoryStore(storage: InMemoryKvStoragePort()),
  };
  for (final entry in histories.entries) {
    group('FeedbackHistoryStore (${entry.key})', () {
      late FeedbackHistoryStore store;
      setUp(() => store = entry.value());

      test('returns events oldest first', () async {
        await store.append(fb('b', 2));
        await store.append(fb('a', 1));
        await store.append(fb('c', 3));
        expect((await store.recent()).map((e) => e.id), ['a', 'b', 'c']);
      });

      test('limit keeps the latest events', () async {
        for (var i = 0; i < 5; i++) {
          await store.append(fb('e$i', i));
        }
        expect((await store.recent(limit: 2)).map((e) => e.id), ['e3', 'e4']);
      });

      test('empty store gives an empty list', () async {
        expect(await store.recent(), isEmpty);
      });
    });
  }

  final proposals = <String, ProposalStore Function()>{
    'in memory': InMemoryProposalStore.new,
    'kv': () => KvProposalStore(storage: InMemoryKvStoragePort()),
  };
  for (final entry in proposals.entries) {
    group('ProposalStore (${entry.key})', () {
      late ProposalStore store;
      setUp(() => store = entry.value());

      test('save replaces by id and get reads it back', () async {
        await store.save(prop('p1'));
        await store.save(prop('p1', status: ProposalStatus.rejected));
        expect((await store.get('p1'))!.status, ProposalStatus.rejected);
        expect(await store.list(), hasLength(1));
        expect(await store.get('none'), isNull);
      });

      test('list narrows by status and ethos, oldest first', () async {
        await store.save(prop('p2', minute: 2));
        await store.save(prop('p1', minute: 1));
        await store.save(prop('p3',
            ethosId: 'other', status: ProposalStatus.applied, minute: 3));
        expect((await store.list()).map((p) => p.id), ['p1', 'p2', 'p3']);
        expect(
            (await store.list(status: ProposalStatus.pending)).map((p) => p.id),
            ['p1', 'p2']);
        expect((await store.list(ethosId: 'other')).map((p) => p.id), ['p3']);
      });
    });
  }

  group('retention', () {
    test('feedback history drops the oldest beyond maxEvents (Kv)', () async {
      final kv = InMemoryKvStoragePort();
      final store = KvFeedbackHistoryStore(storage: kv, maxEvents: 3);
      for (var i = 0; i < 6; i++) {
        await store.append(fb('e$i', i));
      }
      expect((await store.recent()).map((e) => e.id), ['e3', 'e4', 'e5']);
      expect(await kv.keys(prefix: 'philosophy.feedback:'), hasLength(3));
    });

    test('an out-of-order older event is the one dropped (Kv)', () async {
      final store = KvFeedbackHistoryStore(
          storage: InMemoryKvStoragePort(), maxEvents: 2);
      await store.append(fb('b', 2));
      await store.append(fb('c', 3));
      await store.append(fb('a', 1));
      expect((await store.recent()).map((e) => e.id), ['b', 'c']);
    });

    test('recent reads only the newest values (Kv)', () async {
      final kv = _CountingKv();
      final store = KvFeedbackHistoryStore(storage: kv, maxEvents: 50);
      for (var i = 0; i < 50; i++) {
        await store.append(fb('e$i', i));
      }
      kv.gets = 0;
      await store.recent(limit: 5);
      expect(kv.gets, 5);
      kv.gets = 0;
      await store.recent(limit: 1000);
      expect(kv.gets, 50);
    });

    test('default bound applies without configuration', () async {
      final kv = InMemoryKvStoragePort();
      final store = KvFeedbackHistoryStore(storage: kv);
      for (var i = 0; i < defaultMaxFeedbackEvents + 5; i++) {
        await store.append(fb('e$i', i));
      }
      expect(await kv.keys(prefix: 'philosophy.feedback:'),
          hasLength(defaultMaxFeedbackEvents));
    });

    test('in-memory history keeps the newest maxEvents', () async {
      final store = InMemoryFeedbackHistoryStore(maxEvents: 2);
      for (var i = 0; i < 4; i++) {
        await store.append(fb('e$i', i));
      }
      expect((await store.recent()).map((e) => e.id), ['e2', 'e3']);
    });

    test('an event dated before the epoch is stored and ordered first (Kv)',
        () async {
      final store = KvFeedbackHistoryStore(storage: InMemoryKvStoragePort());
      await store.append(fb('now', 5));
      await store.append(FeedbackEvent(
        id: 'old',
        actionId: 'a',
        ethosId: 'e',
        valuePriorityId: 'vp-1',
        outcome: FeedbackOutcome.positive,
        outcomeScore: 0.9,
        occurredAt: DateTime.utc(1960),
      ));
      expect((await store.recent()).map((e) => e.id), ['old', 'now']);
    });

    test('keys that are not time-shaped are ignored (Kv)', () async {
      final kv = InMemoryKvStoragePort();
      await kv.set('philosophy.feedback:legacy', fb('x', 1).toJson());
      final store = KvFeedbackHistoryStore(storage: kv);
      await store.append(fb('a', 2));
      expect((await store.recent()).map((e) => e.id), ['a']);
    });

    test('resolved proposals are capped, open ones never removed', () async {
      final kv = InMemoryKvStoragePort();
      final store = KvProposalStore(storage: kv, maxResolved: 2);
      await store.save(prop('open1', minute: 0));
      await store
          .save(prop('open2', minute: 1, status: ProposalStatus.approved));
      for (var i = 0; i < 4; i++) {
        await store
            .save(prop('r$i', minute: 10 + i, status: ProposalStatus.applied));
      }
      expect((await store.list()).map((p) => p.id),
          ['open1', 'open2', 'r2', 'r3']);
    });

    test('saving an open proposal does not scan the store (Kv)', () async {
      final kv = _CountingKv();
      final store = KvProposalStore(storage: kv, maxResolved: 2);
      for (var i = 0; i < 5; i++) {
        await store.save(prop('p$i', minute: i));
      }
      expect(kv.keyScans, 0);
    });
  });

  test('a Kv store written by one instance is read by another', () async {
    final kv = InMemoryKvStoragePort();
    await KvFeedbackHistoryStore(storage: kv).append(fb('a', 1));
    await KvProposalStore(storage: kv).save(prop('p1'));
    expect((await KvFeedbackHistoryStore(storage: kv).recent()).single.id, 'a');
    expect((await KvProposalStore(storage: kv).get('p1'))!.id, 'p1');
  });

  test('the two Kv stores do not read each other\'s keys', () async {
    final kv = InMemoryKvStoragePort();
    await KvFeedbackHistoryStore(storage: kv).append(fb('a', 1));
    expect(await KvProposalStore(storage: kv).list(), isEmpty);
  });
}
