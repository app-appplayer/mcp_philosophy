import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

EthosRecord _testRecord({
  String id = 'ethos-1',
  String name = 'Test Ethos',
  String version = '1.0.0',
  Map<String, dynamic>? payload,
}) =>
    EthosRecord(
      id: id,
      name: name,
      version: version,
      payload: payload ?? {'kind': 'test', 'id': id},
      createdAt: DateTime.utc(2026, 1, 1),
      active: false,
    );

void main() {
  group('KvEthosStoreAdapter', () {
    late InMemoryKvStoragePort storage;
    late KvEthosStoreAdapter adapter;

    setUp(() {
      storage = InMemoryKvStoragePort();
      adapter = KvEthosStoreAdapter(storage: storage);
    });

    test('TC-181: putEthos then getEthos round-trips EthosRecord by id', () async {
      final record = _testRecord(id: 'ethos-a', name: 'A');
      await adapter.putEthos(record);
      final loaded = await adapter.getEthos('ethos-a');
      expect(loaded, isNotNull);
      expect(loaded!.id, 'ethos-a');
      expect(loaded.name, 'A');
      expect(loaded.payload['kind'], 'test');
      expect(loaded.createdAt, record.createdAt);
    });

    test('TC-182: getEthos returns null for unknown id', () async {
      final loaded = await adapter.getEthos('does-not-exist');
      expect(loaded, isNull);
    });

    test('TC-182a: getEthos throws StateError when stored value is not a Map (corrupt record)',
        () async {
      // Write a non-Map value directly under the adapter's key.
      await storage.set('philosophy.ethos:corrupt', 'not-a-map');
      expect(() => adapter.getEthos('corrupt'), throwsStateError);
    });

    test('TC-183: listEthos returns every stored record', () async {
      await adapter.putEthos(_testRecord(id: 'a'));
      await adapter.putEthos(_testRecord(id: 'b'));
      await adapter.putEthos(_testRecord(id: 'c'));
      final records = await adapter.listEthos();
      expect(records, hasLength(3));
      expect(records.map((r) => r.id), containsAll(['a', 'b', 'c']));
    });

    test('TC-184: listEthos respects the optional limit parameter', () async {
      await adapter.putEthos(_testRecord(id: 'a'));
      await adapter.putEthos(_testRecord(id: 'b'));
      await adapter.putEthos(_testRecord(id: 'c'));
      final records = await adapter.listEthos(limit: 2);
      expect(records, hasLength(2));
    });

    test('TC-185: listEthos excludes the __active__ marker key', () async {
      await adapter.putEthos(_testRecord(id: 'a'));
      await adapter.activateEthos('a');
      final records = await adapter.listEthos();
      expect(records, hasLength(1));
      expect(records.single.id, 'a');
    });

    test('TC-186: activateEthos then getActiveEthosId returns the activated id',
        () async {
      await adapter.putEthos(_testRecord(id: 'a'));
      await adapter.putEthos(_testRecord(id: 'b'));
      await adapter.activateEthos('b');
      expect(await adapter.getActiveEthosId(), 'b');
    });

    test('TC-187: activateEthos throws StateError when id is unknown', () async {
      expect(() => adapter.activateEthos('missing'), throwsStateError);
    });

    test('TC-188: getActiveEthosId returns null when no ethos has been activated',
        () async {
      expect(await adapter.getActiveEthosId(), isNull);
    });

    test('TC-189: respects the custom namespace constructor parameter', () async {
      final custom = KvEthosStoreAdapter(
        storage: storage,
        namespace: 'tenant.alpha.ethos',
      );
      await custom.putEthos(_testRecord(id: 'a'));
      // Default-namespace adapter must NOT see the custom-namespace record.
      expect(await adapter.getEthos('a'), isNull);
      expect((await custom.getEthos('a'))!.id, 'a');
      // Storage layout sanity check.
      final keys = await storage.keys(prefix: 'tenant.alpha.ethos:');
      expect(keys, contains('tenant.alpha.ethos:a'));
    });
  });

  group('Scenario E / F integration', () {
    test('TC-190: Scenario E — PhilosophyEngine + KvEthosStoreAdapter end-to-end evaluate',
        () async {
      final storage = InMemoryKvStoragePort();
      final ethosStore = KvEthosStoreAdapter(storage: storage);
      final ethos = fullTestEthos();
      await ethosStore.putEthos(EthosRecord(
        id: ethos.id,
        name: ethos.name,
        version: ethos.metadata.version,
        payload: ethos.toJson(),
        createdAt: ethos.metadata.createdAt,
        active: true,
      ));
      await ethosStore.activateEthos(ethos.id);

      final engine = PhilosophyEngine(ethosStore: ethosStore);
      final guidance = await engine.evaluate(
        testContext(proposedAction: 'evaluate scenario E'),
      );
      expect(guidance, isA<PhilosophyGuidance>());

      final loaded = await engine.getEthos();
      expect(loaded.id, ethos.id);
      expect(loaded.valuePriorities.length, ethos.valuePriorities.length);
    });

    test('TC-191: Scenario F — PhilosophyEngine + stub FactsPort detectTensionsForEntity surfaces content-derived tensions',
        () async {
      final storage = InMemoryKvStoragePort();
      final ethosStore = KvEthosStoreAdapter(storage: storage);
      final ethos = fullTestEthos();
      await ethosStore.putEthos(EthosRecord(
        id: ethos.id,
        name: ethos.name,
        version: ethos.metadata.version,
        payload: ethos.toJson(),
        createdAt: ethos.metadata.createdAt,
        active: true,
      ));
      await ethosStore.activateEthos(ethos.id);

      final lowConfidenceFacts = _LowConfidenceFactsPort();
      final engine = PhilosophyEngine(
        ethosStore: ethosStore,
        facts: lowConfidenceFacts,
      );
      final tensions = await engine.detectTensionsForEntity(
        'student-42',
        workspaceId: 'ws-1',
      );
      expect(tensions, isNotEmpty);
      expect(
        tensions.any((t) => t.source.opposingLayer == TensionLayer.knowledge),
        isTrue,
      );
    });
  });
}

class _LowConfidenceFactsPort implements FactsPort {
  @override
  Future<List<FactRecord>> queryFacts(FactQuery query) async {
    return [
      FactRecord(
        id: 'f1',
        workspaceId: query.workspaceId,
        type: 'declining_score',
        entityId: query.entityId,
        content: const {'score': 30},
        confidence: 0.1,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
      FactRecord(
        id: 'f2',
        workspaceId: query.workspaceId,
        type: 'declining_score',
        entityId: query.entityId,
        content: const {'score': 35},
        confidence: 0.15,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<void> writeFacts(List<FactRecord> facts) async {}

  @override
  Future<FactRecord?> getFact(String id) async => null;

  @override
  Future<void> deleteFacts(List<String> ids) async {}
}
