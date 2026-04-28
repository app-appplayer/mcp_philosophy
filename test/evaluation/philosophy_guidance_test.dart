import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  PhilosophyGuidance makeGuidance({
    bool prohibitionViolated = false,
    List<MatchedCriterion>? matchedCriteria,
    double confidence = 0.8,
  }) {
    return PhilosophyGuidance(
      valuePriorityApplied: testValuePriority(),
      prohibitionChecks: ProhibitionCheckResult.allPassed(const []),
      matchedCriteria: matchedCriteria ?? const [],
      recommendedAction: 'Test action',
      confidence: confidence,
      explanation: 'Test explanation',
      prohibitionViolated: prohibitionViolated,
    );
  }

  group('PhilosophyGuidance', () {
    test('allowsProceeding is true when no violation', () {
      final g = makeGuidance();
      expect(g.allowsProceeding, isTrue);
    });

    test('allowsProceeding is false when prohibition violated', () {
      final g = makeGuidance(prohibitionViolated: true);
      expect(g.allowsProceeding, isFalse);
    });

    test('hasConflicts detects conflicting criteria', () {
      final g = makeGuidance(matchedCriteria: [
        const MatchedCriterion(
          criterionId: 'jc-1',
          preferredAction: 'A',
          matchStrength: 0.9,
          hasConflict: true,
          conflictWith: 'jc-2',
        ),
      ]);
      expect(g.hasConflicts, isTrue);
    });

    test('hasConflicts is false with no conflicts', () {
      final g = makeGuidance(matchedCriteria: [
        const MatchedCriterion(
          criterionId: 'jc-1',
          preferredAction: 'A',
          matchStrength: 0.9,
        ),
      ]);
      expect(g.hasConflicts, isFalse);
    });

    // TC-083a: hasConflicts false when matchedCriteria is empty
    test('hasConflicts returns false when matchedCriteria is empty', () {
      final g = makeGuidance(matchedCriteria: []);
      expect(g.hasConflicts, isFalse);
    });

    // TC-084a: copyWith preserves unmodified fields
    test('copyWith modifies confidence', () {
      final g = makeGuidance(confidence: 0.8);
      final copied = g.copyWith(confidence: 0.5);
      expect(copied.confidence, 0.5);
      expect(copied.recommendedAction, g.recommendedAction);
    });

    // TC-084b: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final g = makeGuidance(confidence: 0.6);
      final copied = g.copyWith();
      expect(copied.confidence, g.confidence);
      expect(copied.recommendedAction, g.recommendedAction);
      expect(copied.prohibitionViolated, g.prohibitionViolated);
      expect(copied.explanation, g.explanation);
    });

    // TC-084c: copyWith replaces prohibitionChecks when provided
    test('copyWith replaces prohibitionChecks when provided', () {
      final g = makeGuidance();
      final newChecks = ProhibitionCheckResults.withViolations(const [
        ProhibitionCheck(
          prohibitionId: 'p-new',
          violated: true,
          severity: ProhibitionSeverity.hard,
        ),
      ]);
      final copied = g.copyWith(prohibitionChecks: newChecks);
      expect(copied.prohibitionChecks.hasHardViolation, isTrue);
      expect(copied.confidence, g.confidence);
    });

    test('toJson/fromJson round-trip', () {
      final g = makeGuidance();
      final json = g.toJson();
      final restored = PhilosophyGuidance.fromJson(json);
      expect(restored.confidence, g.confidence);
      expect(restored.prohibitionViolated, g.prohibitionViolated);
      expect(restored.recommendedAction, g.recommendedAction);
    });
  });

  group('ProhibitionCheckResult', () {
    test('allPassed factory', () {
      final result = ProhibitionCheckResult.allPassed(const [
        ProhibitionCheck(
          prohibitionId: 'p-1',
          violated: false,
          severity: ProhibitionSeverity.hard,
        ),
      ]);
      expect(result.hasHardViolation, isFalse);
      expect(result.violations, isEmpty);
    });

    test('withViolations factory computes ids', () {
      final result = ProhibitionCheckResults.withViolations(const [
        ProhibitionCheck(
          prohibitionId: 'p-1',
          violated: true,
          severity: ProhibitionSeverity.hard,
        ),
        ProhibitionCheck(
          prohibitionId: 'p-2',
          violated: true,
          severity: ProhibitionSeverity.soft,
        ),
        ProhibitionCheck(
          prohibitionId: 'p-3',
          violated: false,
          severity: ProhibitionSeverity.hard,
        ),
      ]);
      expect(result.hasHardViolation, isTrue);
      expect(result.hardViolationIds, ['p-1']);
      expect(result.softViolationIds, ['p-2']);
      expect(result.violations, hasLength(2));
    });

    test('toJson/fromJson round-trip', () {
      final result = ProhibitionCheckResults.withViolations(const [
        ProhibitionCheck(
          prohibitionId: 'p-1',
          violated: true,
          severity: ProhibitionSeverity.hard,
          violationDetail: 'Detail',
        ),
      ]);
      final json = result.toJson();
      final restored = ProhibitionCheckResult.fromJson(json);
      expect(restored.hasHardViolation, isTrue);
      expect(restored.hardViolationIds, ['p-1']);
      expect(restored.checks.first.violationDetail, 'Detail');
    });
  });

  group('MatchedCriterion', () {
    test('toJson/fromJson round-trip', () {
      const mc = MatchedCriterion(
        criterionId: 'jc-1',
        preferredAction: 'Action',
        matchStrength: 0.85,
        hasConflict: true,
        conflictWith: 'jc-2',
        conflictAnnotation: 'Annotation',
      );
      final json = mc.toJson();
      final restored = MatchedCriterion.fromJson(json);
      expect(restored.criterionId, mc.criterionId);
      expect(restored.matchStrength, mc.matchStrength);
      expect(restored.hasConflict, isTrue);
      expect(restored.conflictWith, 'jc-2');
    });
  });
}
