import 'package:hive_flutter/hive_flutter.dart';

class PendingDelete {
  final String type;
  final String id;
  final DateTime updatedAt;

  const PendingDelete({
    required this.type,
    required this.id,
    required this.updatedAt,
  });

  factory PendingDelete.fromMap(Map<String, dynamic> map) {
    return PendingDelete(
      type: map['type'] as String,
      id: map['id'] as String,
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'id': id,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}

class PendingDeleteQueue {
  static const String _boxName = 'settings';
  static const String _key = 'pendingDeletes';

  static Box get _box => Hive.box(_boxName);

  static List<PendingDelete> getAll() {
    final raw = _box.get(_key);
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => PendingDelete.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> add(String type, String id) async {
    final current = getAll();
    final alreadyQueued =
        current.any((item) => item.type == type && item.id == id);
    if (alreadyQueued) return;

    final updated = [
      ...current,
      PendingDelete(type: type, id: id, updatedAt: DateTime.now()),
    ];

    await _box.put(_key, updated.map((item) => item.toMap()).toList());
  }

  static Future<void> remove(String type, String id) async {
    final updated = getAll()
        .where((item) => item.type != type || item.id != id)
        .map((item) => item.toMap())
        .toList();

    await _box.put(_key, updated);
  }

  static int get count => getAll().length;

  static Future<void> clear() async {
    await _box.delete(_key);
  }
}
