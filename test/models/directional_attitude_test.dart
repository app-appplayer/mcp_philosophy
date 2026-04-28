import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('DirectionalAttitude', () {
    // TC-044: Construction for each domain
    test('constructs for uncertainty domain', () {
      final da = testAttitude(domain: AttitudeDomain.uncertainty);
      expect(da.domain, AttitudeDomain.uncertainty);
    });

    test('constructs for failure domain', () {
      final da = testAttitude(domain: AttitudeDomain.failure);
      expect(da.domain, AttitudeDomain.failure);
    });

    test('constructs for conflict domain', () {
      final da = testAttitude(domain: AttitudeDomain.conflict);
      expect(da.domain, AttitudeDomain.conflict);
    });

    test('constructs for unknownDomain', () {
      final da = testAttitude(domain: AttitudeDomain.unknownDomain);
      expect(da.domain, AttitudeDomain.unknownDomain);
    });

    // TC-044b: construction with empty posture (no constructor validation)
    test('construction with empty posture succeeds (no constructor validation)',
        () {
      final da = testAttitude(posture: '');
      expect(da.posture, '');
    });

    // TC-045: JSON round-trip
    test('toJson/fromJson round-trip', () {
      final da = testAttitude();
      final json = da.toJson();
      final restored = DirectionalAttitude.fromJson(json);
      expect(restored.id, da.id);
      expect(restored.domain, da.domain);
      expect(restored.posture, da.posture);
      expect(restored.behavioralImplications, da.behavioralImplications);
    });

    // TC-044a: validate throws when id is empty
    test('validate() throws ArgumentError when id is empty', () {
      expect(
        () => testAttitude(id: '').validate(),
        throwsArgumentError,
      );
    });

    // TC-044c: validate succeeds for minimally valid attitude
    test('validate() succeeds for minimally valid attitude', () {
      final da = testAttitude();
      expect(() => da.validate(), returnsNormally);
    });

    // TC-045a: copyWith preserves unmodified fields
    test('copyWith modifies posture and preserves other fields', () {
      final da = testAttitude();
      final copied = da.copyWith(posture: 'New posture');
      expect(copied.posture, 'New posture');
      expect(copied.id, da.id);
      expect(copied.domain, da.domain);
      expect(copied.behavioralImplications, da.behavioralImplications);
    });

    // TC-045b: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final da = testAttitude();
      final copied = da.copyWith();
      expect(copied.id, da.id);
      expect(copied.domain, da.domain);
      expect(copied.posture, da.posture);
      expect(copied.behavioralImplications, da.behavioralImplications);
    });

    // TC-045c: copyWith replaces behavioralImplications list when provided
    test('copyWith replaces behavioralImplications list when provided', () {
      final da = testAttitude();
      final copied = da.copyWith(behavioralImplications: ['new-impl']);
      expect(copied.behavioralImplications, ['new-impl']);
      expect(copied.id, da.id);
    });
  });

  // TC-050: AttitudeDomain enum forward compatibility
  group('AttitudeDomain', () {
    test('fromString falls back to unknown for unrecognized value', () {
      expect(
        AttitudeDomain.fromString('nonexistent'),
        AttitudeDomain.unknownDomain,
      );
    });
  });
}
