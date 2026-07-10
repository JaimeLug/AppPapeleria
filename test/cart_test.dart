import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_papeleria/core/error/failures.dart';
import 'package:app_papeleria/features/inventory/domain/entities/product.dart';
import 'package:app_papeleria/features/sales/domain/entities/order.dart';
import 'package:app_papeleria/features/sales/domain/repositories/order_repository.dart';
import 'package:app_papeleria/features/sales/presentation/providers/cart_provider.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';

/// Fake que implementa la interfaz de dominio: nos deja construir el
/// CartNotifier sin Hive ni Supabase. Registra los pedidos guardados.
class _FakeOrderRepository implements OrderRepository {
  final List<OrderEntity> saved = [];

  @override
  Future<Either<Failure, bool>> addOrder(OrderEntity order) async {
    saved.add(order);
    return const Right(true);
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async => const Right([]);

  @override
  Stream<List<OrderEntity>> watchOrders() => const Stream.empty();

  @override
  Future<Either<Failure, void>> deleteOrder(String id) async => const Right(null);

  @override
  Future<Either<Failure, bool>> syncOrders() async => const Right(true);
}

ProductEntity _product({double base = 10.0, double extra = 0.0}) => ProductEntity(
      id: 'p-$base-$extra',
      name: 'Producto',
      basePrice: base,
      extraCost: extra,
      category: 'General',
    );

void main() {
  group('CartNotifier - totales', () {
    test('addItem agrega y el mismo producto acumula cantidad', () {
      final cart = CartNotifier(_FakeOrderRepository());
      final p = _product(base: 10);
      cart.addItem(p);
      cart.addItem(p, quantity: 2);
      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.single.quantity, 3);
      expect(cart.state.subtotal, 30.0);
    });

    test('total incluye el monto extra', () {
      final cart = CartNotifier(_FakeOrderRepository());
      cart.addItem(_product(base: 19.99));
      cart.setExtraAmount(5.01);
      expect(cart.state.subtotal, 19.99);
      expect(cart.state.total, 25.00);
    });

    test('removeItem y updateQuantity(0) quitan el renglón', () {
      final cart = CartNotifier(_FakeOrderRepository());
      final p = _product();
      cart.addItem(p);
      cart.updateQuantity(p.id, 0);
      expect(cart.state.items, isEmpty);
    });
  });

  group('CartNotifier - anticipo acotado [0, total] (fix #1)', () {
    test('un anticipo mayor al total se acota al total (pendiente 0)', () {
      final cart = CartNotifier(_FakeOrderRepository());
      cart.addItem(_product(base: 10)); // total = 10
      cart.setAdvancePayment(999);
      expect(cart.state.advancePayment, 10.0);
      expect(cart.state.pendingBalance, 0.0);
    });

    test('un anticipo negativo se acota a 0', () {
      final cart = CartNotifier(_FakeOrderRepository());
      cart.addItem(_product(base: 10));
      cart.setAdvancePayment(-50);
      expect(cart.state.advancePayment, 0.0);
      expect(cart.state.pendingBalance, 10.0);
    });

    test('un anticipo parcial deja el pendiente correcto', () {
      final cart = CartNotifier(_FakeOrderRepository());
      cart.addItem(_product(base: 100));
      cart.setAdvancePayment(30);
      expect(cart.state.advancePayment, 30.0);
      expect(cart.state.pendingBalance, 70.0);
    });

    test('marcar liquidado pone anticipo = total y pendiente 0', () {
      final cart = CartNotifier(_FakeOrderRepository());
      cart.addItem(_product(base: 45.5));
      cart.toggleFullPayment(true);
      expect(cart.state.advancePayment, 45.5);
      expect(cart.state.pendingBalance, 0.0);
    });
  });

  group('CartNotifier - validación de confirmSale', () {
    test('carrito vacío devuelve error y no queda cargando', () async {
      final cart = CartNotifier(_FakeOrderRepository());
      await cart.confirmSale(const AppSettings());
      expect(cart.state.errorMessage, 'El carrito está vacío');
      expect(cart.state.isLoading, false);
    });

    test('sin nombre de cliente devuelve error', () async {
      final cart = CartNotifier(_FakeOrderRepository());
      cart.addItem(_product());
      await cart.confirmSale(const AppSettings());
      expect(cart.state.errorMessage, 'Debes ingresar el nombre del cliente');
      expect(cart.state.isLoading, false);
    });

    test('monto extra sin concepto devuelve error', () async {
      final cart = CartNotifier(_FakeOrderRepository());
      cart.addItem(_product());
      cart.setCustomerName('Ana');
      cart.setExtraAmount(20);
      await cart.confirmSale(const AppSettings());
      expect(cart.state.errorMessage, 'Debes especificar el concepto del cargo extra');
      expect(cart.state.isLoading, false);
    });
  });
}
