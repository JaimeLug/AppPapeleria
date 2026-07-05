import 'dart:io';

import 'package:app_papeleria/core/services/pending_delete_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'pending_delete_queue_test_',
    );
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('stores each pending delete only once and removes it after sync', () async {
    await PendingDeleteQueue.add('product', 'product-1');
    await PendingDeleteQueue.add('product', 'product-1');
    await PendingDeleteQueue.add('order', 'order-1');

    expect(PendingDeleteQueue.getAll(), hasLength(2));
    expect(
      PendingDeleteQueue.getAll().map((item) => '${item.type}:${item.id}'),
      containsAll(['product:product-1', 'order:order-1']),
    );

    await PendingDeleteQueue.remove('product', 'product-1');

    final remaining = PendingDeleteQueue.getAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.type, 'order');
    expect(remaining.single.id, 'order-1');
  });
}
