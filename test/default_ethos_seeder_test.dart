/// Tests for [DefaultEthosSeeder] and the [PhilosophyEngine.initialize] hook.
library;

import 'package:mcp_philosophy/mcp_philosophy.dart';
import 'package:test/test.dart';

import 'port/philosophy_engine_test.dart' show FakeEthosStore;

void main() {
  group('DefaultEthosSeeder', () {
    test('seedIfEmpty populates an empty store with the default ethos',
        () async {
      final store = FakeEthosStore();
      await DefaultEthosSeeder.seedIfEmpty(store);

      final all = await store.listEthos();
      expect(all, hasLength(1));
      expect(all.single.id, DefaultEthosSeeder.defaultEthosId);

      final activeId = await store.getActiveEthosId();
      expect(activeId, DefaultEthosSeeder.defaultEthosId);
    });

    test('seedIfEmpty is idempotent — running twice does not duplicate records',
        () async {
      final store = FakeEthosStore();
      await DefaultEthosSeeder.seedIfEmpty(store);
      await DefaultEthosSeeder.seedIfEmpty(store);

      final all = await store.listEthos();
      expect(all, hasLength(1));
    });

    test('seedIfEmpty leaves a non-empty store untouched', () async {
      final store = FakeEthosStore();
      final now = DateTime.now().toUtc();
      final hostEthos = EthosRecord(
        id: 'host_ethos',
        name: 'Host-Provided Ethos',
        version: '0.1.0',
        payload: const {},
        createdAt: now,
      );
      await store.putEthos(hostEthos);
      await store.activateEthos('host_ethos');

      await DefaultEthosSeeder.seedIfEmpty(store);

      final activeId = await store.getActiveEthosId();
      expect(activeId, 'host_ethos');
      final all = await store.listEthos();
      expect(all.map((e) => e.id), ['host_ethos']);
    });

    test('buildDefaultEthos emits four value priorities and prohibitions',
        () async {
      final ethos = DefaultEthosSeeder.buildDefaultEthos();
      expect(ethos.valuePriorities, hasLength(4));
      expect(
        ethos.valuePriorities.map((v) => v.id),
        containsAll(['safety', 'honesty', 'transparency', 'user_respect']),
      );
      expect(ethos.prohibitions.length, greaterThanOrEqualTo(4));
      expect(
        ethos.prohibitions.map((p) => p.id),
        containsAll([
          'safety_harmful_content',
          'honesty_fabrication',
        ]),
      );
    });
  });

  group('PhilosophyEngine.initialize', () {
    test('seeds the default ethos into an empty store when autoSeedEthos is '
        'true (default)', () async {
      final store = FakeEthosStore();
      final engine = PhilosophyEngine(ethosStore: store);

      await engine.initialize();

      final activeId = await store.getActiveEthosId();
      expect(activeId, DefaultEthosSeeder.defaultEthosId);
    });

    test('leaves the store untouched when autoSeedEthos is false', () async {
      final store = FakeEthosStore();
      final engine = PhilosophyEngine(
        ethosStore: store,
        autoSeedEthos: false,
      );

      await engine.initialize();

      final all = await store.listEthos();
      expect(all, isEmpty);
    });

    test('is idempotent — repeated calls do not re-seed', () async {
      final store = FakeEthosStore();
      final engine = PhilosophyEngine(ethosStore: store);

      await engine.initialize();
      await engine.initialize();
      await engine.initialize();

      final all = await store.listEthos();
      expect(all, hasLength(1));
    });
  });
}
