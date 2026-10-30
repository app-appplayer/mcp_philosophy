import 'package:mcp_bundle/mcp_bundle.dart';

/// Persistence port for [FeedbackEvent]s.
///
/// The engine decides patterns from past feedback; this port lets that
/// history outlive the process.
abstract class FeedbackHistoryStore {
  /// Record [event].
  Future<void> append(FeedbackEvent event);

  /// Past events, oldest first. With [limit], only the latest [limit].
  Future<List<FeedbackEvent>> recent({int? limit});
}

/// Persistence port for [EvolutionProposal]s.
abstract class ProposalStore {
  /// Insert or replace [proposal] by id.
  Future<void> save(EvolutionProposal proposal);

  /// The proposal with [id], or null.
  Future<EvolutionProposal?> get(String id);

  /// Stored proposals, oldest first, optionally narrowed.
  Future<List<EvolutionProposal>> list({
    ProposalStatus? status,
    String? ethosId,
  });
}

/// Default number of feedback events a store keeps.
const int defaultMaxFeedbackEvents = 500;

/// Default number of resolved proposals a store keeps.
const int defaultMaxResolvedProposals = 200;

/// Oldest first by `occurredAt`; events at the same instant keep their
/// given order.
List<FeedbackEvent> _oldestFirst(List<FeedbackEvent> all) {
  final indexed = [for (var i = 0; i < all.length; i++) (i, all[i])]
    ..sort((a, b) {
      final byTime = a.$2.occurredAt.compareTo(b.$2.occurredAt);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return [for (final e in indexed) e.$2];
}

List<FeedbackEvent> _latest(List<FeedbackEvent> all, int? limit) {
  final ordered = _oldestFirst(all);
  if (limit == null || ordered.length <= limit) return ordered;
  return ordered.sublist(ordered.length - limit);
}

List<EvolutionProposal> _narrow(
  List<EvolutionProposal> all,
  ProposalStatus? status,
  String? ethosId,
) =>
    all
        .where((p) =>
            (status == null || p.status == status) &&
            (ethosId == null || p.ethosId == ethosId))
        .toList();

/// Process-memory [FeedbackHistoryStore]; the default.
///
/// Keeps at most [maxEvents] events; the oldest are dropped first.
class InMemoryFeedbackHistoryStore implements FeedbackHistoryStore {
  final int maxEvents;
  List<FeedbackEvent> _events = [];

  InMemoryFeedbackHistoryStore({this.maxEvents = defaultMaxFeedbackEvents})
      : assert(maxEvents > 0);

  @override
  Future<void> append(FeedbackEvent event) async {
    _events.add(event);
    if (_events.length > maxEvents) _events = _latest(_events, maxEvents);
  }

  @override
  Future<List<FeedbackEvent>> recent({int? limit}) async =>
      _latest(List.of(_events), limit);
}

/// Process-memory [ProposalStore]; the default.
class InMemoryProposalStore implements ProposalStore {
  final Map<String, EvolutionProposal> _byId = {};

  @override
  Future<void> save(EvolutionProposal proposal) async =>
      _byId[proposal.id] = proposal;

  @override
  Future<EvolutionProposal?> get(String id) async => _byId[id];

  @override
  Future<List<EvolutionProposal>> list({
    ProposalStatus? status,
    String? ethosId,
  }) async {
    final all = _byId.values.toList()
      ..sort((a, b) => a.proposedAt.compareTo(b.proposedAt));
    return _narrow(all, status, ethosId);
  }
}

/// [FeedbackHistoryStore] over a [KvStoragePort].
///
/// Keys are `<namespace>:<occurredAt microseconds, 16 digits>:<id>`, so the
/// key order is the time order and the newest events are picked from the key
/// list without reading values. At most [maxEvents] are kept, and one
/// [recent] call reads at most that many.
class KvFeedbackHistoryStore implements FeedbackHistoryStore {
  static final RegExp _timePart = RegExp(r'^\d{16}:');

  final KvStoragePort _storage;
  final String _namespace;
  final int maxEvents;

  KvFeedbackHistoryStore({
    required KvStoragePort storage,
    String namespace = 'philosophy.feedback',
    this.maxEvents = defaultMaxFeedbackEvents,
  })  : assert(maxEvents > 0),
        _storage = storage,
        _namespace = namespace;

  String get _prefix => '$_namespace:';

  /// Keys of this store in time order, oldest first.
  Future<List<String>> _orderedKeys() async {
    final keys = [
      for (final key in await _storage.keys(prefix: _prefix))
        if (_timePart.hasMatch(key.substring(_prefix.length))) key,
    ]..sort();
    return keys;
  }

  @override
  Future<void> append(FeedbackEvent event) async {
    final micros = event.occurredAt.toUtc().microsecondsSinceEpoch
        .clamp(0, 9999999999999999);
    final stamp = micros.toString().padLeft(16, '0');
    await _storage.set('$_prefix$stamp:${event.id}', event.toJson());
    final keys = await _orderedKeys();
    if (keys.length <= maxEvents) return;
    for (final key in keys.take(keys.length - maxEvents)) {
      await _storage.remove(key);
    }
  }

  @override
  Future<List<FeedbackEvent>> recent({int? limit}) async {
    final keys = await _orderedKeys();
    final take = limit == null || limit > maxEvents ? maxEvents : limit;
    final newest = keys.length > take ? keys.sublist(keys.length - take) : keys;
    final events = <FeedbackEvent>[];
    for (final key in newest) {
      final raw = await _storage.get(key);
      if (raw is Map) {
        events.add(FeedbackEvent.fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    return events;
  }
}

/// [ProposalStore] over a [KvStoragePort]; keys `<namespace>:<id>`.
///
/// Proposals still waiting for a person (`pending`, `approved`) are never
/// removed. Once more than [maxResolved] proposals are resolved, the oldest
/// resolved ones are removed.
class KvProposalStore implements ProposalStore {
  final KvStoragePort _storage;
  final String _namespace;
  final int maxResolved;

  KvProposalStore({
    required KvStoragePort storage,
    String namespace = 'philosophy.proposal',
    this.maxResolved = defaultMaxResolvedProposals,
  })  : assert(maxResolved >= 0),
        _storage = storage,
        _namespace = namespace;

  static bool _isOpen(ProposalStatus s) =>
      s == ProposalStatus.pending || s == ProposalStatus.approved;

  @override
  Future<void> save(EvolutionProposal proposal) async {
    await _storage.set('$_namespace:${proposal.id}', proposal.toJson());
    if (_isOpen(proposal.status)) return;
    final resolved = [
      for (final p in await list())
        if (!_isOpen(p.status)) p,
    ];
    if (resolved.length <= maxResolved) return;
    for (final p in resolved.take(resolved.length - maxResolved)) {
      await _storage.remove('$_namespace:${p.id}');
    }
  }

  @override
  Future<EvolutionProposal?> get(String id) async {
    final raw = await _storage.get('$_namespace:$id');
    if (raw is! Map) return null;
    return EvolutionProposal.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<EvolutionProposal>> list({
    ProposalStatus? status,
    String? ethosId,
  }) async {
    final all = <EvolutionProposal>[];
    for (final key in await _storage.keys(prefix: '$_namespace:')) {
      final raw = await _storage.get(key);
      if (raw is Map) {
        all.add(EvolutionProposal.fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    all.sort((a, b) => a.proposedAt.compareTo(b.proposedAt));
    return _narrow(all, status, ethosId);
  }
}
