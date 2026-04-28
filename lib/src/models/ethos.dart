import 'package:mcp_bundle/mcp_bundle.dart';

import '../exceptions.dart';

/// Strategy for merging conflicting Ethos instances.
enum ConflictStrategy {
  /// Prefer the higher-ranked values from both.
  preferHigher,

  /// Prefer the lower-ranked values from both.
  preferLower,

  /// Merge both sets and re-rank.
  merge,

  /// Reject the merge if conflicts exist.
  reject,

  /// Forward compatibility.
  unknown;

  static ConflictStrategy fromString(String value) {
    return ConflictStrategy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConflictStrategy.unknown,
    );
  }
}

/// Conflict resolution configuration for Ethos merging.
class ConflictResolution {
  /// How to handle priority conflicts.
  final ConflictStrategy strategy;

  /// Which Ethos wins (for strategy=preferHigher/preferLower).
  final String? preferredEthosId;

  const ConflictResolution({
    required this.strategy,
    this.preferredEthosId,
  });

  Map<String, dynamic> toJson() {
    return {
      'strategy': strategy.name,
      if (preferredEthosId != null) 'preferredEthosId': preferredEthosId,
    };
  }

  factory ConflictResolution.fromJson(Map<String, dynamic> json) {
    return ConflictResolution(
      strategy: ConflictStrategy.fromString(json['strategy'] as String),
      preferredEthosId: json['preferredEthosId'] as String?,
    );
  }
}

/// Extensions for Ethos domain-specific behavior beyond the contract.
extension EthosExtensions on Ethos {
  /// Validate Ethos constraints.
  ///
  /// The mcp_bundle contract type uses const constructor without validation.
  /// Call this method to enforce business rules.
  void validate() {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Ethos id must not be empty');
    }
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Ethos name must not be empty');
    }
    if (valuePriorities.isEmpty) {
      throw ArgumentError.value(valuePriorities, 'valuePriorities',
          'Ethos must have at least one value priority');
    }
    if (prohibitions.isEmpty) {
      throw ArgumentError.value(prohibitions, 'prohibitions',
          'Ethos must have at least one prohibition');
    }
    final ranks = valuePriorities.map((vp) => vp.rank).toSet();
    if (ranks.length != valuePriorities.length) {
      throw ArgumentError('Ethos valuePriorities must have unique ranks');
    }
  }

  /// Get judgment criteria applicable to a domain.
  List<JudgmentCriterion> criteriaForDomain(String domain) =>
      judgmentCriteria
          .where((c) => c.conditions.any((cond) => cond.contains(domain)))
          .toList();

  /// Get directional attitude for a specific domain.
  DirectionalAttitude? attitudeFor(AttitudeDomain domain) {
    for (final a in directionalAttitudes) {
      if (a.domain == domain) return a;
    }
    return null;
  }

  /// Create a copy with modified fields.
  Ethos copyWith({
    String? id,
    String? name,
    List<ValuePriority>? valuePriorities,
    List<Prohibition>? prohibitions,
    List<JudgmentCriterion>? judgmentCriteria,
    List<DirectionalAttitude>? directionalAttitudes,
    EthosMetadata? metadata,
    List<EthosScope>? scopes,
  }) {
    return Ethos(
      id: id ?? this.id,
      name: name ?? this.name,
      valuePriorities: valuePriorities ?? this.valuePriorities,
      prohibitions: prohibitions ?? this.prohibitions,
      judgmentCriteria: judgmentCriteria ?? this.judgmentCriteria,
      directionalAttitudes: directionalAttitudes ?? this.directionalAttitudes,
      metadata: metadata ?? this.metadata,
      scopes: scopes ?? this.scopes,
    );
  }

  /// Merge with another Ethos (other takes precedence on conflicts).
  Ethos mergeWith(Ethos other, {required ConflictResolution resolution}) {
    if (resolution.strategy == ConflictStrategy.reject) {
      final thisRanks = valuePriorities.map((vp) => vp.rank).toSet();
      final otherRanks = other.valuePriorities.map((vp) => vp.rank).toSet();
      final conflictingRanks = thisRanks.intersection(otherRanks);
      if (conflictingRanks.isNotEmpty) {
        throw EthosValidationException(
          'Cannot merge: conflicting ranks $conflictingRanks with reject strategy',
        );
      }
    }

    final mergedPriorities = <ValuePriority>[];
    final seenRanks = <int>{};

    final primary =
        resolution.preferredEthosId == other.id ? other : this;
    final secondary =
        resolution.preferredEthosId == other.id ? this : other;

    for (final vp in primary.valuePriorities) {
      mergedPriorities.add(vp);
      seenRanks.add(vp.rank);
    }

    var nextRank = (seenRanks.isEmpty
            ? 0
            : seenRanks.reduce((a, b) => a > b ? a : b)) +
        1;
    for (final vp in secondary.valuePriorities) {
      if (seenRanks.contains(vp.rank)) {
        mergedPriorities.add(ValuePriority(
          id: vp.id,
          rank: nextRank,
          higherValue: vp.higherValue,
          lowerValue: vp.lowerValue,
          rationale: vp.rationale,
          conditions: vp.conditions,
        ));
        seenRanks.add(nextRank);
        nextRank++;
      } else {
        mergedPriorities.add(vp);
        seenRanks.add(vp.rank);
      }
    }

    final mergedProhibitions = <Prohibition>{
      ...prohibitions,
      ...other.prohibitions,
    }.toList();

    final criteriaMap = <String, JudgmentCriterion>{};
    for (final jc in judgmentCriteria) {
      criteriaMap[jc.id] = jc;
    }
    for (final jc in other.judgmentCriteria) {
      criteriaMap[jc.id] = jc;
    }

    final attitudeMap = <AttitudeDomain, DirectionalAttitude>{};
    for (final da in directionalAttitudes) {
      attitudeMap[da.domain] = da;
    }
    for (final da in other.directionalAttitudes) {
      attitudeMap[da.domain] = da;
    }

    final now = DateTime.now();
    return Ethos(
      id: '${id}_merged_${other.id}',
      name: '$name + ${other.name}',
      valuePriorities: mergedPriorities,
      prohibitions: mergedProhibitions,
      judgmentCriteria: criteriaMap.values.toList(),
      directionalAttitudes: attitudeMap.values.toList(),
      metadata: EthosMetadata(
        version: '${metadata.version}-merged',
        author: metadata.author,
        createdAt: now,
        updatedAt: now,
        context:
            'Merged from ${metadata.context ?? id} and ${other.metadata.context ?? other.id}',
        tags: {...metadata.tags, ...other.metadata.tags}.toList(),
      ),
      scopes: scopes != null || other.scopes != null
          ? [...?scopes, ...?other.scopes]
          : null,
    );
  }
}
