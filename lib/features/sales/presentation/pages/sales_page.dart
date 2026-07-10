import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sales_cart_summary.dart';
import '../widgets/sales_product_catalog.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Left: Product Catalog (60%)
          Expanded(
            flex: 6,
            child: const ProductCatalog(),
          ),
          // Right: Cart Summary (40%)
          Expanded(
            flex: 4,
            child: const CartSummary(),
          ),
        ],
      ),
    );
  }
}
