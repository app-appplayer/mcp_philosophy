import 'package:mcp_bundle/mcp_bundle.dart';

/// Default [EthosStorePort] implementation backed by a [KvStoragePort].
///
/// Stores each [EthosRecord] under the key `'$namespace:${record.id}'` and
/// tracks the active ethos id under the reserved key `'$namespace:__active__'`.
/// The reserved key is excluded from [listEthos] results.
///
/// REDESIGN-PLAN.md Phase 6 — see DDD `core-port.md` §3.4.
class KvEthosStoreAdapter implements EthosStorePort {
  static const String _activeMarker = '__active__';

  final KvStoragePort _storage;
  final String _namespace;

  KvEthosStoreAdapter({
    required KvStoragePort storage,
    String namespace = 'philosophy.ethos',
  })  : _storage = storage,
        _namespace = namespace;

  String _recordKey(String id) => '$_namespace:$id';
  String get _activeKey => '$_namespace:$_activeMarker';

  @override
  Future<EthosRecord?> getEthos(String id) async {
    final raw = await _storage.get(_recordKey(id));
    if (raw == null) return null;
    if (raw is! Map) {
      throw StateError(
        'Corrupt ethos record at ${_recordKey(id)}: expected Map, '
        'got ${raw.runtimeType}',
      );
    }
    return _decodeRecord(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> putEthos(EthosRecord ethos) async {
    await _storage.set(_recordKey(ethos.id), _encodeRecord(ethos));
  }

  @override
  Future<List<EthosRecord>> listEthos({int? limit}) async {
    final keys = await _storage.keys(prefix: '$_namespace:');
    final results = <EthosRecord>[];
    for (final key in keys) {
      if (key == _activeKey) continue;
      if (limit != null && results.length >= limit) break;
      final raw = await _storage.get(key);
      if (raw is Map) {
        results.add(_decodeRecord(Map<String, dynamic>.from(raw)));
      }
    }
    return results;
  }

  @override
  Future<void> activateEthos(String id) async {
    final existing = await getEthos(id);
    if (existing == null) {
      throw StateError('Ethos not found: $id');
    }
    await _storage.set(_activeKey, id);
  }

  @override
  Future<String?> getActiveEthosId() async {
    final raw = await _storage.get(_activeKey);
    if (raw == null) return null;
    return raw as String;
  }

  // Encoding helpers — EthosRecord (mcp_bundle) does not declare toJson.

  Map<String, dynamic> _encodeRecord(EthosRecord record) => {
        'id': record.id,
        'name': record.name,
        'version': record.version,
        'payload': record.payload,
        'createdAt': record.createdAt.toIso8601String(),
        'active': record.active,
      };

  EthosRecord _decodeRecord(Map<String, dynamic> json) => EthosRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        version: json['version'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        active: (json['active'] as bool?) ?? false,
      );
}
