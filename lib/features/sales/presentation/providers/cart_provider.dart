import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../../inventory/domain/entities/product.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../../../core/services/pdf_service.dart';
import '../../domain/repositories/order_repository.dart';
import 'package:app_papeleria/features/settings/presentation/providers/settings_provider.dart';

// Repository Provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final box = Hive.box<OrderModel>('orders');
  return OrderRepositoryImpl(box);
});

// Cart State
class CartState {
  final List<OrderItemEntity> items;
  final String customerName;
  final DateTime? deliveryDate;
  final DateTime? saleDate; // New field for retroactive date
  final double advancePayment;
  final bool isFullyPaid;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const CartState({
    this.items = const [],
    this.customerName = '',
    this.deliveryDate,
    this.saleDate,
    this.advancePayment = 0.0,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.isFullyPaid = false,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => subtotal; // Can add tax or discounts here
  double get pendingBalance => isFullyPaid ? 0.0 : total - advancePayment;

  CartState copyWith({
    List<OrderItemEntity>? items,
    String? customerName,
    DateTime? deliveryDate,
    DateTime? saleDate,
    double? advancePayment,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    bool? isFullyPaid,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      saleDate: saleDate ?? this.saleDate,
      advancePayment: advancePayment ?? this.advancePayment,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset if not provided, or logic can vary
      isSuccess: isSuccess ?? this.isSuccess,
      isFullyPaid: isFullyPaid ?? this.isFullyPaid,
    );
  }
}

// Cart Notifier
class CartNotifier extends StateNotifier<CartState> {
  final OrderRepository repository;

  CartNotifier(this.repository) : super(const CartState());

  void addItem(ProductEntity product) {
    if (state.items.any((item) => item.productId == product.id)) {
      // Increment quantity if exists
      final existingItem = state.items.firstWhere((item) => item.productId == product.id);
      updateQuantity(product.id, existingItem.quantity + 1);
    } else {
      // Add new item
      final newItem = OrderItemEntity(
        productId: product.id,
        productName: product.name,
        price: product.basePrice + product.extraCost,
        quantity: 1,
        notes: product.notes,
      );
      state = state.copyWith(items: [...state.items, newItem]);
      
      // Auto-update advance if fully paid
      if (state.isFullyPaid) {
        // Calculate new total
        final newItems = [...state.items, newItem];
        final newTotal = newItems.fold(0.0, (sum, item) => sum + item.total);
        state = state.copyWith(advancePayment: newTotal);
      }
    }
  }

  void removeItem(String productId) {
    final newItems = state.items.where((item) => item.productId != productId).toList();
    state = state.copyWith(items: newItems);
     if (state.isFullyPaid) {
        final newTotal = newItems.fold(0.0, (sum, item) => sum + item.total);
        state = state.copyWith(advancePayment: newTotal);
      }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final newItems = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: newItems);
    if (state.isFullyPaid) {
        final newTotal = newItems.fold(0.0, (sum, item) => sum + item.total);
        state = state.copyWith(advancePayment: newTotal);
    }
  }

  void setCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }

  void setDeliveryDate(DateTime date) {
    // Preserve time if it exists, otherwise set to noon
    if (state.deliveryDate != null) {
      final existingTime = state.deliveryDate!;
      final newDate = DateTime(
        date.year,
        date.month,
        date.day,
        existingTime.hour,
        existingTime.minute,
      );
      state = state.copyWith(deliveryDate: newDate);
    } else {
      // Default to noon if no time set
      final newDate = DateTime(date.year, date.month, date.day, 12, 0);
      state = state.copyWith(deliveryDate: newDate);
    }
  }

  void setDeliveryTime(int hour, int minute) {
    // Merge time with existing date, or use today if no date set
    final currentDate = state.deliveryDate ?? DateTime.now();
    final newDateTime = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      hour,
      minute,
    );
    state = state.copyWith(deliveryDate: newDateTime);
  }

  void setSaleDate(DateTime date) {
    state = state.copyWith(saleDate: date);
  }

  void setAdvancePayment(double amount) {
    if (!state.isFullyPaid) {
      state = state.copyWith(advancePayment: amount);
    }
  }
  
  void toggleFullPayment(bool value) {
    state = state.copyWith(
      isFullyPaid: value,
      advancePayment: value ? state.total : 0.0, 
    );
  }

  void clearCart() {
    state = const CartState();
  }
  
  void resetStatus() {
     state = state.copyWith(errorMessage: null, isSuccess: false, isLoading: false);
  }

  Future<void> confirmSale(AppSettings settings) async {
    print('LOG: Inicio de venta...');
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    // 1. Validation
    if (state.items.isEmpty) {
      print('LOG: Error - Carrito vacío');
      state = state.copyWith(isLoading: false, errorMessage: 'El carrito está vacío');
      return;
    }
    if (state.customerName.trim().isEmpty) {
       print('LOG: Error - Falta nombre de cliente');
       state = state.copyWith(isLoading: false, errorMessage: 'Debes ingresar el nombre del cliente');
       return;
    }

    final isPaid = state.isFullyPaid || (state.advancePayment >= state.total);

    final order = OrderEntity(
      id: const Uuid().v4(),
      customerName: state.customerName,
      items: state.items,
      totalPrice: state.total,
      pendingBalance: state.isFullyPaid ? 0.0 : state.pendingBalance, // Ensure 0 if fully paid
      deliveryDate: state.deliveryDate ?? DateTime.now(),
      saleDate: state.saleDate ?? DateTime.now(), // Use selected sale date or now
      isSynced: false,
      status: 'Diseño',
      paymentStatus: isPaid ? 'paid' : 'pending',
      deliveryStatus: 'pending',
    );

    try {
      // Paso 1: Guardar en Hive (Critical)
      print('LOG: Intentando guardar pedido en Hive...');
      // Ensure box is open just in case, though main should handle it.
      if (!Hive.isBoxOpen('orders')) {
         print('LOG: Orders box not open, opening now...');
         await Hive.openBox<OrderModel>('orders');
      }

      final result = await repository.addOrder(order);
      
      await result.fold(
        (failure) async {
          print('LOG: Error al guardar en Hive: ${failure.message}');
          state = state.copyWith(isLoading: false, errorMessage: 'Error al guardar: ${failure.message}');
        },
        (syncSuccess) async {
           print('LOG: Pedido guardado con éxito. ID: ${order.id}. Synced: $syncSuccess');
           
           // Paso 3: PDF (Opcional/Riesgoso)
           try {
              print('LOG: Intentando generar PDF...');
              final pdfService = PdfService();
              await pdfService.generateAndPrintReceipt(order, settings);
              print('LOG: PDF generado correctamente');
           } catch (e) {
              print('LOG: Error generando PDF: $e');
              // Non-critical error, order is saved.
              // We could warn, but sync status is more important.
           }

           clearCart(); 
           // manually set success state to show snackbar
           // We can pass syncSuccess via errorMessage hack or a new field, 
           // but simpler to just use errorMessage for "Warning" if sync failed.
           if (syncSuccess) {
             state = const CartState(isSuccess: true);
           } else {
             state = const CartState(isSuccess: true, errorMessage: 'Guardado LOCALMENTE, pero falló la subida a Nube.');
           }
        },
      );
    } catch (e) {
      print('LOG: Excepción no controlada en confirmSale: $e');
       state = state.copyWith(isLoading: false, errorMessage: 'Error crítico: $e');
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return CartNotifier(repository);
});
