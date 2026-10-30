import 'package:mcp_bundle/mcp_bundle.dart';

import '../default_ethos_seeder.dart';
import '../evaluation/philosophy_evaluator.dart';
import '../evolution/evolution_proposal.dart';
import '../evolution/evolution_stores.dart';
import '../evolution/reinforcement_engine.dart';
import '../intervention/intervention_engine.dart';
import '../tension/tension_detector.dart';

/// Sole [PhilosophyPort] implementation in `mcp_philosophy`.
///
/// Consumes:
/// - [EthosStorePort] (required) — active ethos resolution and persistence.
/// - [FactsPort] (optional) — entity-based overloads query facts directly.
/// - [EvidencePort] (optional) — provenance verification hook.
/// - [ContextBundlePort] (optional) — multi-layer context construction hook.
/// - [EventPort] (optional) — feedback proposal events are emitted here.
///
/// REDESIGN-PLAN.md Phase 6 §4.1a path **(a)** lock — the legacy
/// ethos-at-construction `PhilosophyAdapter` is removed; this is the only
/// `PhilosophyPort` implementation. See DDD `core-port.md` §3.2.
///
/// Provides two entry points that produce equivalent results for the same
/// facts (FR-PORT-012 conformance):
/// - Entity-based: [detectTensionsForEntity] / [checkProhibitionsForEntity]
///   query [FactsPort] internally.
/// - Caller-supplied: [detectTensions] / [checkProhibitions] take a
///   pre-built context. Use [deriveKnowledgeProvenance] to mirror the
///   engine's records → provenance encoding.
class PhilosophyEngine implements PhilosophyPort {
  static const String _entityFactKeyPrefix = 'entity:';
  static const String _feedbackProposedEventType =
      'philosophy.feedback_proposed';
  static const String _eventSource = 'mcp_philosophy';

  final EthosStorePort _ethosStore;
  final FactsPort? _facts;
  // ignore: unused_field
  final EvidencePort? _evidence;
  // ignore: unused_field
  final ContextBundlePort? _contextBundle;
  final EventPort? _events;

  final PhilosophyEvaluator _evaluator;
  final InterventionEngine _interventionEngine;
  final TensionDetector _tensionDetector;
  final ReinforcementEngine _reinforcementEngine;
  final FeedbackHistoryStore _feedbackHistory;
  final ProposalStore _proposals;

  /// How many past feedback events join a pattern decision (null = all).
  final int? historyLimit;

  /// Whether [initialize] should seed the default ethos into an empty store.
  ///
  /// Defaults to true. Hosts that inject their own curated ethos should pass
  /// `autoSeedEthos: false` to suppress the built-in seed.
  final bool autoSeedEthos;

  bool _initialized = false;

  PhilosophyEngine({
    required EthosStorePort ethosStore,
    FactsPort? facts,
    EvidencePort? evidence,
    ContextBundlePort? contextBundle,
    EventPort? events,
    PhilosophyEvaluator? evaluator,
    InterventionEngine? interventionEngine,
    TensionDetector? tensionDetector,
    ReinforcementEngine? reinforcementEngine,
    FeedbackHistoryStore? feedbackHistory,
    ProposalStore? proposals,
    this.historyLimit,
    this.autoSeedEthos = true,
  })  : _feedbackHistory = feedbackHistory ?? InMemoryFeedbackHistoryStore(),
        _proposals = proposals ?? InMemoryProposalStore(),
        _ethosStore = ethosStore,
        _facts = facts,
        _evidence = evidence,
        _contextBundle = contextBundle,
        _events = events,
        _evaluator = evaluator ?? const PhilosophyEvaluator(),
        _interventionEngine = interventionEngine ??
            InterventionEngine(
                evaluator: evaluator ?? const PhilosophyEvaluator()),
        _tensionDetector = tensionDetector ?? const TensionDetector(),
        _reinforcementEngine =
            reinforcementEngine ?? const ReinforcementEngine();

  /// Lazily seed the default ethos when [autoSeedEthos] is enabled.
  ///
  /// Idempotent: only seeds on the first call and only when the underlying
  /// [EthosStorePort] is empty and has no active ethos selected. Hosts that
  /// construct a [PhilosophyEngine] with their own ethos already installed
  /// can skip this call (or leave `autoSeedEthos: false`).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!autoSeedEthos) return;
    await DefaultEthosSeeder.seedIfEmpty(_ethosStore);
  }

  // ---------- PhilosophyPort ----------

  @override
  Future<PhilosophyGuidance> evaluate(
      PhilosophyEvaluationContext context) async {
    final ethos = await _loadActiveEthos();
    return _evaluator.evaluate(ethos, context);
  }

  @override
  Future<ProhibitionCheckResult> checkProhibitions(
      ProhibitionCheckRequest request) async {
    if (!request.isValid) {
      throw ArgumentError(
          'ProhibitionCheckRequest must have proposedAction or proposedOutput');
    }
    final ethos = await _loadActiveEthos();
    final context = PhilosophyEvaluationContext(
      contextId: 'prohibition_check',
      proposedAction: request.proposedAction,
      proposedOutput: request.proposedOutput,
      facts: request.context,
    );
    return _evaluator.checkProhibitions(ethos.prohibitions, context);
  }

  @override
  Future<InterventionResult> intervene(
      InterventionPoint point, PipelineContext context) async {
    final ethos = await _loadActiveEthos();
    return _interventionEngine.intervene(point, context, ethos);
  }

  @override
  Future<Ethos> getEthos() async => _loadActiveEthos();

  @override
  Future<List<Tension>> detectTensions(MultiLayerContext context) async {
    final ethos = await _loadActiveEthos();
    return _tensionDetector.detect(ethos, context);
  }

  @override
  Future<EvolutionProposal?> proposeFeedback(FeedbackEvent event) async {
    final ethos = await _loadActiveEthos();
    // The analysis adds the new event itself, so it gets the history as it
    // stood before this event.
    final past = await _feedbackHistory.recent(limit: historyLimit);
    await _feedbackHistory.append(event);
    final proposal =
        _reinforcementEngine.analyzeFeedback(event, past, ethos);
    if (proposal != null) await _proposals.save(proposal);
    final events = _events;
    if (proposal != null && events != null) {
      await events.publish(PortEvent(
        type: _feedbackProposedEventType,
        payload: {
          'proposalId': proposal.id,
          'feedbackId': event.id,
        },
        timestamp: DateTime.now(),
        source: _eventSource,
      ));
    }
    return proposal;
  }

  // ---------- Proposal handling ----------

  /// Stored proposals, oldest first, optionally narrowed.
  Future<List<EvolutionProposal>> listProposals({
    ProposalStatus? status,
    String? ethosId,
  }) =>
      _proposals.list(status: status, ethosId: ethosId);

  /// Applies a proposal a human has approved.
  ///
  /// Only a `valuePriority` target with a `reinforce` (one rank up) or
  /// `weaken` (one rank down) proposal has a mechanical meaning; any other
  /// proposal throws [UnsupportedError] and is authored by hand. The result
  /// is a new inactive ethos record derived from the source one; the source
  /// is not edited and nothing is activated here. Returns the new record.
  ///
  /// Throws [ArgumentError] when [approvedBy] is empty and [StateError] when
  /// the proposal or its ethos is missing, the proposal is not open, or the
  /// move would change nothing.
  Future<EthosRecord> applyProposal(
    String proposalId, {
    required String approvedBy,
  }) async {
    final approver = approvedBy.trim();
    if (approver.isEmpty) {
      throw ArgumentError.value(
          approvedBy, 'approvedBy', 'a human approver is required');
    }
    final proposal = await _openProposal(proposalId);
    final isMove = proposal.targetComponentType == 'valuePriority' &&
        (proposal.type == EvolutionType.reinforce ||
            proposal.type == EvolutionType.weaken);
    if (!isMove) {
      throw UnsupportedError(
          'Proposal ${proposal.id} (${proposal.type.name} on '
          '${proposal.targetComponentType}) has no mechanical application; '
          'author the change by hand');
    }

    final source = await _ethosStore.getEthos(proposal.ethosId);
    if (source == null) {
      throw StateError('Ethos not found: ${proposal.ethosId}');
    }
    final ethos = Ethos.fromJson(source.payload);
    final priorities = List<ValuePriority>.of(ethos.valuePriorities)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final at =
        priorities.indexWhere((v) => v.id == proposal.targetComponentId);
    if (at < 0) {
      throw StateError('Value priority not found: '
          '${proposal.targetComponentId}');
    }
    final to = proposal.type == EvolutionType.reinforce ? at - 1 : at + 1;
    if (to < 0 || to >= priorities.length) {
      throw StateError('Value priority ${proposal.targetComponentId} cannot '
          'move ${proposal.type.name}: already at the end');
    }
    final moved = priorities.removeAt(at);
    priorities.insert(to, moved);

    final now = DateTime.now();
    final payload = Map<String, dynamic>.from(source.payload)
      ..['valuePriorities'] = [
        for (var i = 0; i < priorities.length; i++)
          ValuePriority(
            id: priorities[i].id,
            rank: i + 1,
            higherValue: priorities[i].higherValue,
            lowerValue: priorities[i].lowerValue,
            rationale: priorities[i].rationale,
            conditions: priorities[i].conditions,
          ).toJson(),
      ]
      ..['provenance'] = {
        'kind': 'derived',
        'serves': proposal.targetComponentId,
        'derivedFrom': source.id,
        'proposalId': proposal.id,
        'approvedBy': approver,
        'approvedAt': now.toIso8601String(),
      };
    final record = EthosRecord(
      id: '${source.id}.evo.${proposal.id}',
      name: source.name,
      version: source.version,
      payload: payload,
      createdAt: now,
      active: false,
    );
    await _ethosStore.putEthos(record);
    await _proposals.save(proposal.copyWith(status: ProposalStatus.applied));
    await _publishProposalEvent('philosophy.proposal_applied', proposal.id);
    return record;
  }

  /// Marks an open proposal rejected by a human.
  Future<EvolutionProposal> rejectProposal(
    String proposalId, {
    required String rejectedBy,
  }) async {
    if (rejectedBy.trim().isEmpty) {
      throw ArgumentError.value(
          rejectedBy, 'rejectedBy', 'a human reviewer is required');
    }
    final proposal = await _openProposal(proposalId);
    final rejected = proposal.copyWith(status: ProposalStatus.rejected);
    await _proposals.save(rejected);
    await _publishProposalEvent('philosophy.proposal_rejected', proposal.id);
    return rejected;
  }

  Future<EvolutionProposal> _openProposal(String proposalId) async {
    final proposal = await _proposals.get(proposalId);
    if (proposal == null) {
      throw StateError('Proposal not found: $proposalId');
    }
    if (proposal.status != ProposalStatus.pending &&
        proposal.status != ProposalStatus.approved) {
      throw StateError('Proposal $proposalId is ${proposal.status.name}, '
          'not open');
    }
    return proposal;
  }

  Future<void> _publishProposalEvent(String type, String proposalId) async {
    final events = _events;
    if (events == null) return;
    await events.publish(PortEvent(
      type: type,
      payload: {'proposalId': proposalId},
      timestamp: DateTime.now(),
      source: _eventSource,
    ));
  }

  // ---------- Entity-based overloads (new in v0.1.1) ----------

  /// Detect tensions for a specific entity by querying [FactsPort] directly.
  ///
  /// Internally:
  ///   1. Loads the active ethos via [EthosStorePort].
  ///   2. Calls `facts.queryFacts(FactQuery(workspaceId, entityId))`.
  ///   3. Encodes the real fact records into a [MultiLayerContext]:
  ///      - `philosophyContext.facts` carries the records under
  ///        `entity:{id}` for downstream auditing and prohibition checks.
  ///      - `knowledgeProvenance` is derived from the fact content
  ///        (average `FactRecord.confidence` becomes `trust_score`,
  ///        record count becomes `record_count`) so that
  ///        [TensionDetector] reasons over real signals rather than
  ///        a `{factCount: N}` placeholder.
  ///   4. Delegates to [TensionDetector].
  ///
  /// Throws [StateError] when [FactsPort] was not injected.
  Future<List<Tension>> detectTensionsForEntity(
    String entityId, {
    required String workspaceId,
  }) async {
    final factsPort = _requireFacts();
    final ethos = await _loadActiveEthos();
    final records = await factsPort.queryFacts(
      FactQuery(workspaceId: workspaceId, entityId: entityId),
    );
    return _tensionDetector.detect(
      ethos,
      _buildEntityMultiLayerContext(entityId, records),
    );
  }

  /// Check prohibitions against an entity's facts.
  ///
  /// Same fact-loading pipeline as [detectTensionsForEntity]; the loaded
  /// facts are merged into the [PhilosophyEvaluationContext.facts] map.
  ///
  /// Throws [ArgumentError] if the request is invalid.
  /// Throws [StateError] when [FactsPort] was not injected.
  Future<ProhibitionCheckResult> checkProhibitionsForEntity(
    String entityId,
    ProhibitionCheckRequest request, {
    required String workspaceId,
  }) async {
    if (!request.isValid) {
      throw ArgumentError(
          'ProhibitionCheckRequest must have proposedAction or proposedOutput');
    }
    final factsPort = _requireFacts();
    final ethos = await _loadActiveEthos();
    final records = await factsPort.queryFacts(
      FactQuery(workspaceId: workspaceId, entityId: entityId),
    );
    final entityFacts = _encodeFactRecords(records);
    final mergedFacts = <String, dynamic>{
      ...request.context,
      '$_entityFactKeyPrefix$entityId': entityFacts,
    };
    final context = PhilosophyEvaluationContext(
      contextId: 'prohibition_check:$entityId',
      proposedAction: request.proposedAction,
      proposedOutput: request.proposedOutput,
      facts: mergedFacts,
    );
    return _evaluator.checkProhibitions(ethos.prohibitions, context);
  }

  // ---------- internals ----------

  Future<Ethos> _loadActiveEthos() async {
    final activeId = await _ethosStore.getActiveEthosId();
    if (activeId == null) {
      throw StateError(
          'No active ethos. Call EthosStorePort.activateEthos first.');
    }
    final record = await _ethosStore.getEthos(activeId);
    if (record == null) {
      throw StateError('Ethos not found: $activeId');
    }
    return Ethos.fromJson(record.payload);
  }

  FactsPort _requireFacts() {
    final facts = _facts;
    if (facts == null) {
      throw StateError('FactsPort is required for entity-based overloads');
    }
    return facts;
  }

  MultiLayerContext _buildEntityMultiLayerContext(
    String entityId,
    List<FactRecord> records,
  ) {
    final facts = <String, dynamic>{
      '$_entityFactKeyPrefix$entityId': _encodeFactRecords(records),
    };
    final philosophyContext = PhilosophyEvaluationContext(
      contextId: 'entity:$entityId',
      facts: facts,
    );
    return MultiLayerContext(
      philosophyContext: philosophyContext,
      knowledgeProvenance: deriveKnowledgeProvenance(records),
    );
  }

  /// Derive a `knowledgeProvenance` map from a list of [FactRecord].
  ///
  /// Exposed so callers using the caller-supplied [detectTensions] entry
  /// point can mirror the engine's fact-to-context encoding and verify the
  /// FR-PORT-012 conformance invariant against [detectTensionsForEntity].
  static Map<String, dynamic> deriveKnowledgeProvenance(
      List<FactRecord> records) {
    if (records.isEmpty) {
      return {
        'trust_score': 0.0,
        'record_count': 0,
      };
    }
    final scored = records.where((r) => r.confidence != null).toList();
    final avg = scored.isEmpty
        ? 0.0
        : scored.map((r) => r.confidence!).reduce((a, b) => a + b) /
            scored.length;
    return {
      'trust_score': avg,
      'record_count': records.length,
    };
  }

  Map<String, dynamic> _encodeFactRecords(List<FactRecord> records) => {
        'count': records.length,
        'records': records.map(_encodeFactRecord).toList(),
      };

  Map<String, dynamic> _encodeFactRecord(FactRecord record) => {
        'id': record.id,
        'workspaceId': record.workspaceId,
        'type': record.type,
        if (record.entityId != null) 'entityId': record.entityId,
        'content': record.content,
        if (record.confidence != null) 'confidence': record.confidence,
        'createdAt': record.createdAt.toIso8601String(),
      };
}
