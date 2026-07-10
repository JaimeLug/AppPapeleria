import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:app_papeleria/core/error/failures.dart';
import 'package:app_papeleria/core/services/pending_delete_queue.dart';
import 'package:app_papeleria/core/services/sync_trigger.dart';
import 'package:app_papeleria/features/inventory/domain/entities/product.dart';
import 'package:app_papeleria/features/inventory/domain/repositories/remote_product_repository.dart';
import 'package:app_papeleria/features/inventory/data/models/product_model.dart';
import 'package:app_papeleria/features/inventory/data/repositories/offline_first_product_repository.dart';

/// Fake del disparador de sync: solo cuenta cuántas veces se pidió subir.
class _FakeSync implements SyncTrigger {
  int calls = 0;
  @override
  Future<void> syncPendingData() async => calls++;
}

/// Fake de la fuente remota: datos en memoria, sin Supabase.
class _FakeRemote implements RemoteProductRepository {
  List<ProductEntity> remote = [];
  Set<String> deleted = {};
  List<String>? lastDeletedQuery;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async => Right(remote);

  @override
  Future<Set<String>> deletedIdsAmong(List<String> ids) async {
    lastDeletedQuery = ids;
    return ids.where(deleted.contains).toSet();
  }

  @override
  Stream<List<ProductEntity>> watchProducts() => const Stream.empty();

  @override
  Future<Either<Failure, void>> addProduct(ProductEntity product) async => const Right(null);
  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async => const Right(null);
  @override
  Future<Either<Failure, void>> deleteProduct(String id) async => const Right(null);
}

ProductModel _model(String id, {bool synced = true, DateTime? updated}) => ProductModel(
      id: id,
      name: 'P$id',
      basePrice: 1,
      extraCost: 0,
      category: 'c',
      isSynced: synced,
      updatedAt: updated ?? DateTime(2026, 1, 1),
    );

void main() {
  late Directory tempDir;
  late Box<ProductModel> box;
  late _FakeRemote remote;
  late _FakeSync sync;
  late OfflineFirstProductRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_product_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductModelAdapter());
    }
    box = await Hive.openBox<ProductModel>('products');
    await Hive.openBox('settings'); // usado por PendingDeleteQueue
    remote = _FakeRemote();
    sync = _FakeSync();
    repo = OfflineFirstProductRepository(remote, box, sync);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('addProduct guarda en la caja con isSynced=false y dispara sync', () async {
    await repo.addProduct(const ProductEntity(
      id: 'p1',
      name: 'Lápiz',
      basePrice: 5,
      extraCost: 0,
      category: 'c',
    ));
    final stored = box.get('p1');
    expect(stored, isNotNull);
    expect(stored!.isSynced, false);
    expect(sync.calls, 1);
  });

  test('deleteProduct encola el borrado, quita de la caja y dispara sync', () async {
    await box.put('p1', _model('p1'));
    await repo.deleteProduct('p1');
    expect(box.containsKey('p1'), false);
    expect(
      PendingDeleteQueue.getAll().any((d) => d.type == 'product' && d.id == 'p1'),
      true,
    );
    expect(sync.calls, 1);
  });

  test('poda segura: borra local solo lo que el servidor confirma borrado', () async {
    await box.put('A', _model('A'));
    await box.put('B', _model('B'));
    await box.put('C', _model('C', synced: false)); // local nuevo, aún sin subir
    remote.remote = [_model('A')]; // solo A sigue activo en remoto
    remote.deleted = {'B'}; // B confirmado borrado; C no existe en el server

    await repo.getProducts(); // dispara _fetchRemoteAndSync (fire-and-forget)
    await Future.delayed(const Duration(milliseconds: 50));

    expect(box.containsKey('A'), true, reason: 'sigue activo');
    expect(box.containsKey('B'), false, reason: 'podado (confirmado borrado)');
    expect(box.containsKey('C'), true, reason: 'preservado (flag local obsoleto, no confirmado)');
    // La confirmación solo consulta los candidatos (B y C), nunca los activos.
    expect(remote.lastDeletedQuery!.toSet(), {'B', 'C'});
  });

  test('reconcile trae productos nuevos del remoto a la caja', () async {
    remote.remote = [_model('X')];
    await repo.getProducts();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(box.containsKey('X'), true);
  });

  test('reconcile respeta LWW: no pisa un local más nuevo', () async {
    await box.put('A', _model('A', updated: DateTime(2026, 6, 1)));
    // Remoto trae la misma A pero más vieja: no debe sobrescribir.
    remote.remote = [_model('A', updated: DateTime(2026, 1, 1))];
    await repo.getProducts();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(box.get('A')!.updatedAt, DateTime(2026, 6, 1));
  });
}
