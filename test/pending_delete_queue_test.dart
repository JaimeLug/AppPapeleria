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

  test('count refleja el número de borrados pendientes', () async {
    expect(PendingDeleteQueue.count, 0);
    await PendingDeleteQueue.add('product', 'p1');
    await PendingDeleteQueue.add('customer', 'c1');
    expect(PendingDeleteQueue.count, 2);
  });

  test('clear vacía la cola por completo', () async {
    await PendingDeleteQueue.add('product', 'p1');
    await PendingDeleteQueue.add('order', 'o1');
    expect(PendingDeleteQueue.count, 2);

    await PendingDeleteQueue.clear();
    expect(PendingDeleteQueue.count, 0);
    expect(PendingDeleteQueue.getAll(), isEmpty);
  });

  test('remove de un id inexistente no altera la cola', () async {
    await PendingDeleteQueue.add('product', 'p1');
    await PendingDeleteQueue.remove('product', 'no-existe');
    expect(PendingDeleteQueue.count, 1);
    expect(PendingDeleteQueue.getAll().single.id, 'p1');
  });
}
