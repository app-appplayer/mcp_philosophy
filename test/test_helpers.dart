import 'package:mcp_philosophy/mcp_philosophy.dart';

/// Shared test fixtures for mcp_philosophy tests.

final DateTime testTime = DateTime.utc(2026, 1, 1);

EthosMetadata testMetadata({String version = '1.0.0'}) => EthosMetadata(
      version: version,
      author: 'tester',
      createdAt: testTime,
      updatedAt: testTime,
      context: 'test',
      tags: const ['test'],
    );

ValuePriority testValuePriority({
  String id = 'vp-1',
  int rank = 1,
  String higherValue = 'Understanding',
  String lowerValue = 'Speed',
  List<String>? conditions,
}) =>
    ValuePriority(
      id: id,
      rank: rank,
      higherValue: higherValue,
      lowerValue: lowerValue,
      rationale: 'Test rationale',
      conditions: conditions,
    );

Prohibition testProhibition({
  String id = 'proh-1',
  String statement = 'Never present uncertain information as certain',
  ProhibitionSeverity severity = ProhibitionSeverity.hard,
  List<ProhibitionException>? exceptions,
}) =>
    Prohibition(
      id: id,
      statement: statement,
      severity: severity,
      rationale: 'Test rationale',
      exceptions: exceptions,
    );

JudgmentCriterion testCriterion({
  String id = 'jc-1',
  List<String> conditions = const ['risk == "high"'],
  String preferredAction = 'Conservative approach',
  String? fallbackStrategy,
}) =>
    JudgmentCriterion(
      id: id,
      conditions: conditions,
      preferredAction: preferredAction,
      fallbackStrategy: fallbackStrategy,
    );

DirectionalAttitude testAttitude({
  String id = 'da-1',
  AttitudeDomain domain = AttitudeDomain.uncertainty,
  String posture = 'Acknowledge openly',
}) =>
    DirectionalAttitude(
      id: id,
      domain: domain,
      posture: posture,
      behavioralImplications: const ['Use hedging language'],
    );

Ethos testEthos({
  String id = 'test-ethos-001',
  String name = 'Test Ethos',
  List<ValuePriority>? valuePriorities,
  List<Prohibition>? prohibitions,
  List<JudgmentCriterion>? judgmentCriteria,
  List<DirectionalAttitude>? directionalAttitudes,
  EthosMetadata? metadata,
  List<EthosScope>? scopes,
}) =>
    Ethos(
      id: id,
      name: name,
      valuePriorities: valuePriorities ?? [testValuePriority()],
      prohibitions: prohibitions ?? [testProhibition()],
      judgmentCriteria: judgmentCriteria ?? [],
      directionalAttitudes: directionalAttitudes ?? [],
      metadata: metadata ?? testMetadata(),
      scopes: scopes,
    );

Ethos fullTestEthos() => Ethos(
      id: 'test-ethos-full',
      name: 'Full Test Ethos',
      valuePriorities: [
        testValuePriority(id: 'vp-1', rank: 1),
        testValuePriority(
          id: 'vp-2',
          rank: 2,
          higherValue: 'Truthfulness',
          lowerValue: 'Persuasion',
        ),
      ],
      prohibitions: [
        testProhibition(id: 'proh-1', severity: ProhibitionSeverity.hard),
        testProhibition(
          id: 'proh-2',
          statement: 'Avoid excessive jargon',
          severity: ProhibitionSeverity.soft,
        ),
      ],
      judgmentCriteria: [
        testCriterion(
          id: 'jc-1',
          conditions: ['risk == "high"', 'evidence_sufficiency < 0.5'],
          fallbackStrategy: 'Present known facts only',
        ),
      ],
      directionalAttitudes: [
        testAttitude(id: 'da-1', domain: AttitudeDomain.uncertainty),
        testAttitude(
          id: 'da-2',
          domain: AttitudeDomain.failure,
          posture: 'Treat as learning signal',
        ),
      ],
      metadata: testMetadata(),
      scopes: [const EthosScope(domain: 'education', description: 'K-12')],
    );

EvaluationContext testContext({
  String contextId = 'ctx-1',
  Map<String, dynamic>? facts,
  Map<String, double>? metrics,
  String? proposedAction,
  String? proposedOutput,
}) =>
    EvaluationContext(
      contextId: contextId,
      facts: facts ?? const {},
      metrics: metrics ?? const {},
      proposedAction: proposedAction,
      proposedOutput: proposedOutput,
      evaluatedAt: testTime,
    );

FeedbackEvent testFeedbackEvent({
  String id = 'fb-1',
  String actionId = 'act-1',
  String ethosId = 'test-ethos-001',
  String? valuePriorityId = 'vp-1',
  FeedbackOutcome outcome = FeedbackOutcome.positive,
  double outcomeScore = 0.8,
}) =>
    FeedbackEvent(
      id: id,
      actionId: actionId,
      ethosId: ethosId,
      valuePriorityId: valuePriorityId,
      outcome: outcome,
      outcomeScore: outcomeScore,
      occurredAt: testTime,
    );
