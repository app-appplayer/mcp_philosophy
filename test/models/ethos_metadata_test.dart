import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  group('EthosMetadata', () {
    // TC-046: Construction with all fields
    test('constructs with all fields', () {
      final m = testMetadata();
      expect(m.version, '1.0.0');
      expect(m.author, 'tester');
      expect(m.createdAt, testTime);
      expect(m.updatedAt, testTime);
      expect(m.context, 'test');
      expect(m.tags, ['test']);
    });

    // TC-046a: construction with only required fields (author/tags null)
    test('constructs with only required fields (author/tags null)', () {
      final m = EthosMetadata(
        version: '1.0.0',
        createdAt: testTime,
        updatedAt: testTime,
      );
      expect(m.author, isNull);
      expect(m.context, isNull);
      expect(m.tags, isEmpty);
    });

    // TC-047: JSON round-trip
    test('toJson/fromJson round-trip', () {
      final m = testMetadata();
      final json = m.toJson();
      final restored = EthosMetadata.fromJson(json);
      expect(restored.version, m.version);
      expect(restored.author, m.author);
      expect(restored.createdAt, m.createdAt);
      expect(restored.updatedAt, m.updatedAt);
      expect(restored.context, m.context);
      expect(restored.tags, m.tags);
    });

    // TC-048: copyWith preserves unmodified fields
    test('copyWith preserves unmodified fields', () {
      final m = testMetadata();
      final copied = m.copyWith(version: '2.0.0');
      expect(copied.version, '2.0.0');
      expect(copied.author, m.author);
      expect(copied.createdAt, m.createdAt);
      expect(copied.tags, m.tags);
    });

    // TC-048a: copyWith with no arguments returns field-equivalent copy
    test('copyWith with no arguments returns field-equivalent copy', () {
      final m = testMetadata();
      final copied = m.copyWith();
      expect(copied.version, m.version);
      expect(copied.author, m.author);
      expect(copied.createdAt, m.createdAt);
      expect(copied.updatedAt, m.updatedAt);
      expect(copied.context, m.context);
      expect(copied.tags, m.tags);
    });

    // TC-048b: copyWith replaces tags list when provided
    test('copyWith replaces tags list when provided', () {
      final m = testMetadata();
      final copied = m.copyWith(tags: const ['new-tag']);
      expect(copied.tags, ['new-tag']);
      expect(copied.version, m.version);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'version': '1.0.0',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final m = EthosMetadata.fromJson(json);
      expect(m.author, isNull);
      expect(m.context, isNull);
      expect(m.tags, isEmpty);
    });
  });
}
