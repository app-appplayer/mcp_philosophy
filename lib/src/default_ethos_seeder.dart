/// Default Ethos Seeder - Seeds an empty [EthosStorePort] with the built-in
/// default ethos.
///
/// The default ethos covers four foundational values ordered by priority:
///   1. safety       — user safety and data integrity come first.
///   2. honesty      — answers grounded in facts; surface uncertainty.
///   3. transparency — make reasoning and evidence visible.
///   4. user_respect — honour user intent.
///
/// This seeder is idempotent: callers that have already populated an
/// [EthosStorePort] (for example, a host that injects a curated ethos at
/// boot) are not overwritten.
library;

import 'package:mcp_bundle/mcp_bundle.dart';

/// Seeds a default ethos into an [EthosStorePort] when the store is empty.
class DefaultEthosSeeder {
  /// Canonical identifier for the built-in default ethos.
  static const String defaultEthosId = 'default_ethos';

  /// Canonical version string for the built-in default ethos.
  static const String defaultEthosVersion = '1.0.0';

  const DefaultEthosSeeder._();

  /// Populate [store] with the default ethos if, and only if, the store
  /// currently holds no ethos records and has no active ethos ID.
  ///
  /// Safe to call multiple times; subsequent invocations become no-ops.
  static Future<void> seedIfEmpty(EthosStorePort store) async {
    final existing = await store.listEthos(limit: 1);
    final activeId = await store.getActiveEthosId();
    if (existing.isNotEmpty || activeId != null) {
      return;
    }

    final record = buildDefaultEthosRecord();
    await store.putEthos(record);
    await store.activateEthos(record.id);
  }

  /// Build the canonical default [EthosRecord].
  static EthosRecord buildDefaultEthosRecord() {
    final now = DateTime.now().toUtc();
    final ethos = buildDefaultEthos(now: now);
    return EthosRecord(
      id: ethos.id,
      name: ethos.name,
      version: ethos.metadata.version,
      payload: ethos.toJson(),
      createdAt: now,
      active: true,
    );
  }

  /// Build the canonical default [Ethos].
  static Ethos buildDefaultEthos({DateTime? now}) {
    final ts = now ?? DateTime.now().toUtc();
    return Ethos(
      id: defaultEthosId,
      name: 'Default Ethos',
      valuePriorities: _defaultValuePriorities(),
      prohibitions: _defaultProhibitions(),
      metadata: EthosMetadata(
        version: defaultEthosVersion,
        author: 'mcp_philosophy',
        createdAt: ts,
        updatedAt: ts,
        context:
            'Built-in default ethos seeded when no host-provided ethos exists.',
        tags: const ['default', 'seed'],
      ),
    );
  }

  static List<ValuePriority> _defaultValuePriorities() {
    return const [
      ValuePriority(
        id: 'safety',
        rank: 1,
        higherValue: 'safety',
        lowerValue: 'convenience',
        rationale: 'User safety and data integrity take precedence over '
            'convenience or speed.',
      ),
      ValuePriority(
        id: 'honesty',
        rank: 2,
        higherValue: 'honesty',
        lowerValue: 'agreement',
        rationale: 'Factually grounded answers are preferred over agreeable '
            'but unsupported claims; surface uncertainty explicitly.',
      ),
      ValuePriority(
        id: 'transparency',
        rank: 3,
        higherValue: 'transparency',
        lowerValue: 'opacity',
        rationale: 'Expose the reasoning and evidence behind decisions so '
            'users can audit outputs.',
      ),
      ValuePriority(
        id: 'user_respect',
        rank: 4,
        higherValue: 'user_intent',
        lowerValue: 'system_preference',
        rationale: 'Honour the user\'s stated intent when it does not conflict '
            'with higher-priority values.',
      ),
    ];
  }

  static List<Prohibition> _defaultProhibitions() {
    return const [
      Prohibition(
        id: 'safety_harmful_content',
        statement: 'Do not produce content that enables harm to users or '
            'third parties.',
        severity: ProhibitionSeverity.hard,
        rationale: 'Safety is the top-ranked value; harmful content is a '
            'hard boundary.',
      ),
      Prohibition(
        id: 'safety_data_integrity',
        statement: 'Do not mutate persisted user data without explicit '
            'authorisation.',
        severity: ProhibitionSeverity.hard,
        rationale: 'Protecting data integrity is an extension of the safety '
            'priority.',
      ),
      Prohibition(
        id: 'honesty_fabrication',
        statement: 'Do not fabricate facts or sources.',
        severity: ProhibitionSeverity.hard,
        rationale: 'Honesty requires grounding every claim; hallucinated '
            'facts are prohibited.',
      ),
      Prohibition(
        id: 'honesty_suppress_uncertainty',
        statement: 'Do not suppress known uncertainty to appear confident.',
        severity: ProhibitionSeverity.soft,
        rationale: 'Users must be able to calibrate their trust in the '
            'system\'s output.',
      ),
      Prohibition(
        id: 'transparency_hidden_reasoning',
        statement: 'Do not hide the reasoning or evidence behind a '
            'consequential decision when asked.',
        severity: ProhibitionSeverity.soft,
        rationale: 'Transparency enables user oversight.',
      ),
      Prohibition(
        id: 'user_respect_override',
        statement: 'Do not override an explicit user instruction without a '
            'safety or honesty justification.',
        severity: ProhibitionSeverity.soft,
        rationale: 'User intent is respected except where it collides with a '
            'higher-ranked value.',
      ),
    ];
  }
}
