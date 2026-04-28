import 'package:mcp_bundle/mcp_bundle.dart';

import '../default_ethos_seeder.dart';
import '../evaluation/philosophy_evaluator.dart';
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
  final List<FeedbackEvent> _feedbackHistory = [];

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
    this.autoSeedEthos = true,
  })  : _ethosStore = ethosStore,
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
    _feedbackHistory.add(event);
    final proposal = _reinforcementEngine.analyzeFeedback(
        event, _feedbackHistory, ethos);
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
