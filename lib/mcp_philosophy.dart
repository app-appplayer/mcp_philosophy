/// MCP Philosophy - Value principle, judgment direction, and ethos layer.
///
/// This package provides the philosophy (ethos) adapter layer for the MakeMind
/// Knowledge System. All contract types (models, enums, port interface) are
/// defined in mcp_bundle and re-exported here for convenience.
///
/// mcp_philosophy adds:
/// - Philosophy evaluation engine
/// - Pipeline intervention at pre/during/post generation stages
/// - Tension detection and resolution between layers
/// - Philosophy evolution through feedback loops
/// - Dynamic state weighting integration
/// - Extension methods (copyWith, validate, mergeWith) on contract types
library mcp_philosophy;

// =============================================================================
// Re-export contract types from mcp_bundle
// =============================================================================

export 'package:mcp_bundle/mcp_bundle.dart'
    show
        // Port interface
        PhilosophyPort,
        StubPhilosophyPort,
        // Consume-side ports (REDESIGN-PLAN Phase 6)
        EthosStorePort,
        EthosRecord,
        StubEthosStorePort,
        FactsPort,
        FactRecord,
        FactQuery,
        StubFactsPort,
        EvidencePort,
        EvidenceFragment,
        StubEvidencePort,
        ContextBundlePort,
        StubContextBundlePort,
        EventPort,
        PortEvent,
        InMemoryEventPort,
        KvStoragePort,
        InMemoryKvStoragePort,
        // Core models
        Ethos,
        EthosScope,
        ValuePriority,
        Prohibition,
        ProhibitionException,
        ProhibitionSeverity,
        JudgmentCriterion,
        DirectionalAttitude,
        AttitudeDomain,
        EthosMetadata,
        // Evaluation models
        PhilosophyEvaluationContext,
        PhilosophyGuidance,
        ProhibitionCheckRequest,
        ProhibitionCheckResult,
        ProhibitionCheck,
        MatchedCriterion,
        ValueResolution,
        // Intervention models
        InterventionPoint,
        PipelineContext,
        InterventionResult,
        AppliedIntervention,
        InterventionType,
        // Tension models
        Tension,
        TensionSource,
        TensionResolution,
        ResolutionOption,
        MultiLayerContext,
        TensionSeverity,
        TensionLayer,
        ResolutionStrategy,
        // Evolution models
        FeedbackEvent,
        FeedbackOutcome,
        EvolutionProposal,
        ProposedChange,
        EvolutionType,
        ProposalStatus,
        // State models
        StateWeighting,
        StateWeightingImpact;

// =============================================================================
// mcp_philosophy exceptions
// =============================================================================

export 'src/exceptions.dart';

// =============================================================================
// Extensions on contract types (copyWith, validate, mergeWith, etc.)
// =============================================================================

// Models extensions (MOD-CORE-001)
export 'src/models/ethos.dart'; // ConflictStrategy, ConflictResolution, EthosExtensions
export 'src/models/value_priority.dart'; // ValuePriorityExtensions
export 'src/models/prohibition.dart'; // ProhibitionExtensions
export 'src/models/judgment_criterion.dart'; // JudgmentCriterionExtensions
export 'src/models/directional_attitude.dart'; // DirectionalAttitudeExtensions
export 'src/models/ethos_metadata.dart'; // EthosMetadataExtensions

// =============================================================================
// Evaluation engine (MOD-CORE-002)
// =============================================================================

// EvaluationContext typedef + EvaluationContextExtensions +
// PhilosophyEvaluator + ProhibitionCheckResults helper
export 'src/evaluation/philosophy_evaluator.dart';
export 'src/evaluation/philosophy_guidance.dart'; // PhilosophyGuidanceExtensions
export 'src/evaluation/conflict_resolver.dart'; // ConflictResolver

// =============================================================================
// Intervention engine (MOD-CORE-003)
// =============================================================================

export 'src/intervention/intervention_engine.dart'; // InterventionEngine
export 'src/intervention/intervention_point.dart'; // PipelineContextExtensions
export 'src/intervention/intervention_result.dart'; // Pre/During/PostGenerationResult

// =============================================================================
// Tension detection (MOD-FEAT-001)
// =============================================================================

export 'src/tension/tension.dart'; // TensionExtensions
export 'src/tension/tension_detector.dart'; // TensionDetector

// =============================================================================
// Evolution engine (MOD-FEAT-002)
// =============================================================================

export 'src/evolution/feedback_event.dart'; // FeedbackEventExtensions
export 'src/evolution/evolution_proposal.dart'; // EvolutionProposalExtensions
export 'src/evolution/reinforcement_engine.dart'; // ReinforcementEngine, ReinforcementPattern, PatternDirection, EvolutionRecord

// =============================================================================
// State integration (MOD-FEAT-003)
// =============================================================================

export 'src/state/state_weighting.dart'; // StateWeightingExtensions
export 'src/state/state_adjuster.dart'; // StateAdjuster

// =============================================================================
// Port adapters (MOD-CORE-004)
// =============================================================================

export 'src/port/philosophy_engine.dart'; // PhilosophyEngine (sole PhilosophyPort implementation — REDESIGN-PLAN §4.1a path a)
export 'src/port/ethos_store_adapter.dart'; // KvEthosStoreAdapter (EthosStorePort over KvStoragePort)

// =============================================================================
// Seeders
// =============================================================================

export 'src/default_ethos_seeder.dart'; // DefaultEthosSeeder
