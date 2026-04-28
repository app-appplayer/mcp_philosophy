import 'package:mcp_bundle/mcp_bundle.dart';

import '../evaluation/philosophy_guidance.dart';

/// Adjusts PhilosophyGuidance intensity based on state weighting.
///
/// Rules:
/// 1. Value priority ordering is NEVER changed
/// 2. Prohibition results are NEVER modified
/// 3. Confidence score may be adjusted
/// 4. Recommended action tone/urgency may be adjusted
class StateAdjuster {
  const StateAdjuster();

  /// Adjust guidance intensity and return the adjusted guidance with impact record.
  (PhilosophyGuidance, StateWeightingImpact) adjustGuidance(
    PhilosophyGuidance guidance,
    StateWeighting stateWeighting,
  ) {
    final adjustments = <String, double>{};

    final confidenceAdjustment = _computeConfidenceAdjustment(
      guidance.confidence,
      stateWeighting.confidence,
    );
    adjustments['confidence'] = confidenceAdjustment;

    final thoroughnessAdjustment = _computeThoroughnessAdjustment(
      stateWeighting.urgency,
    );
    adjustments['thoroughness'] = thoroughnessAdjustment;

    final cautionAdjustment = _computeCautionAdjustment(
      stateWeighting.riskSensitivity,
    );
    adjustments['caution'] = cautionAdjustment;

    final expressionAdjustment = _computeExpressionAdjustment(
      stateWeighting.emotionalIntensity,
    );
    adjustments['expression'] = expressionAdjustment;

    final adjustedGuidance = guidance.copyWith(
      confidence:
          (guidance.confidence + confidenceAdjustment).clamp(0.0, 1.0),
    );

    final impact = StateWeightingImpact(
      appliedWeighting: stateWeighting,
      adjustments: adjustments,
      summary: _buildSummary(adjustments, stateWeighting),
      directionPreserved: true,
      prohibitionsPreserved: true,
    );

    return (adjustedGuidance, impact);
  }

  /// High state confidence -> slight boost; low -> slight penalty.
  /// Range: [-0.1, +0.1]
  double _computeConfidenceAdjustment(double base, double stateConfidence) {
    return (stateConfidence - 0.5) * 0.2;
  }

  /// High urgency -> reduce thoroughness; low urgency -> increase thoroughness.
  /// Range: [-0.15, +0.15]
  double _computeThoroughnessAdjustment(double urgency) {
    return (0.5 - urgency) * 0.3;
  }

  /// High risk sensitivity -> increase caution.
  /// Range: [-0.2, +0.2]
  double _computeCautionAdjustment(double riskSensitivity) {
    return (riskSensitivity - 0.5) * 0.4;
  }

  /// Emotional intensity adjustment.
  /// Range: [-0.15, +0.15]
  double _computeExpressionAdjustment(double emotionalIntensity) {
    return (emotionalIntensity - 0.5) * 0.3;
  }

  String _buildSummary(
    Map<String, double> adjustments,
    StateWeighting stateWeighting,
  ) {
    final parts = <String>[];

    if (stateWeighting.urgency > 0.7) {
      parts.add(
          'Urgency (${stateWeighting.urgency.toStringAsFixed(2)}) reduced thoroughness');
    } else if (stateWeighting.urgency < 0.3) {
      parts.add(
          'Low urgency (${stateWeighting.urgency.toStringAsFixed(02)}) increased thoroughness');
    }

    if (stateWeighting.riskSensitivity > 0.7) {
      parts.add('High risk sensitivity increased caution');
    } else if (stateWeighting.riskSensitivity < 0.3) {
      parts.add('Low risk tolerance reduced caution');
    }

    if (stateWeighting.confidence > 0.7) {
      parts.add('High context confidence boosted guidance confidence');
    } else if (stateWeighting.confidence < 0.3) {
      parts.add('Low context confidence reduced guidance confidence');
    }

    if (stateWeighting.emotionalIntensity > 0.7) {
      parts.add('High emotional intensity adjusted expression');
    }

    if (parts.isEmpty) {
      return 'Neutral state weighting applied. No significant adjustments.';
    }

    return '${parts.join("; ")}. Direction preserved.';
  }
}
