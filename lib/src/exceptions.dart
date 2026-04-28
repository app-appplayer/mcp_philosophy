/// Base exception for all philosophy-related errors.
class PhilosophyException implements Exception {
  final String message;
  final Object? cause;

  const PhilosophyException(this.message, {this.cause});

  @override
  String toString() => 'PhilosophyException: $message';
}

/// Thrown when an Ethos structure is invalid.
class EthosValidationException extends PhilosophyException {
  const EthosValidationException(super.message, {super.cause});

  @override
  String toString() => 'EthosValidationException: $message';
}

/// Thrown when a hard prohibition is violated.
class ProhibitionViolationException extends PhilosophyException {
  final List<String> violatedProhibitionIds;

  const ProhibitionViolationException(
    super.message, {
    this.violatedProhibitionIds = const [],
    super.cause,
  });

  @override
  String toString() =>
      'ProhibitionViolationException: $message (violations: $violatedProhibitionIds)';
}

/// Thrown when evaluation logic encounters an error.
class EvaluationException extends PhilosophyException {
  const EvaluationException(super.message, {super.cause});

  @override
  String toString() => 'EvaluationException: $message';
}

/// Thrown when pipeline intervention fails.
class InterventionException extends PhilosophyException {
  const InterventionException(super.message, {super.cause});

  @override
  String toString() => 'InterventionException: $message';
}

/// Thrown when tension resolution fails.
class TensionResolutionException extends PhilosophyException {
  const TensionResolutionException(super.message, {super.cause});

  @override
  String toString() => 'TensionResolutionException: $message';
}

/// Thrown when evolution proposal generation or application fails.
class EvolutionException extends PhilosophyException {
  const EvolutionException(super.message, {super.cause});

  @override
  String toString() => 'EvolutionException: $message';
}
