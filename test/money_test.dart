import 'package:flutter_test/flutter_test.dart';
import 'package:app_papeleria/core/utils/money.dart';
import 'package:app_papeleria/features/sales/domain/entities/order_item.dart';

void main() {
  group('roundMoney', () {
    test('corrige el clásico error de flotante 0.1 + 0.2', () {
      expect(roundMoney(0.1 + 0.2), 0.30);
    });

    test('mantiene los enteros intactos', () {
      expect(roundMoney(100), 100.0);
      expect(roundMoney(0), 0.0);
    });

    test('redondea a 2 decimales', () {
      expect(roundMoney(19.994), 19.99);
      expect(roundMoney(19.996), 20.00);
    });

    test('no acumula error al sumar repetidamente', () {
      double suma = 0;
      for (var i = 0; i < 10; i++) {
        suma = roundMoney(suma + 0.1);
      }
      expect(suma, 1.0);
    });

    test('suma de importes tipo carrito queda exacta', () {
      final precios = [19.99, 5.05, 0.1, 0.2];
      final total = roundMoney(precios.fold(0.0, (s, p) => s + p));
      expect(total, 25.34);
    });

    test('maneja valores negativos (saldos/ajustes)', () {
      expect(roundMoney(-19.99), -19.99);
      expect(roundMoney(-0.1 - 0.2), -0.30);
    });

    test('maneja importes grandes sin perder centavos', () {
      expect(roundMoney(1234567.894), 1234567.89);
      expect(roundMoney(999999.996), 1000000.00);
    });

    test('un solo decimal se conserva', () {
      expect(roundMoney(15.5), 15.50);
    });
  });

  group('OrderItemEntity.total', () {
    test('multiplica precio por cantidad y redondea', () {
      const item = OrderItemEntity(
        productId: 'p1',
        productName: 'Cuaderno',
        price: 19.99,
        quantity: 3,
      );
      expect(item.total, 59.97);
    });

    test('cantidad cero da total cero', () {
      const item = OrderItemEntity(
        productId: 'p2',
        productName: 'Pluma',
        price: 12.50,
        quantity: 0,
      );
      expect(item.total, 0.0);
    });
  });
}
