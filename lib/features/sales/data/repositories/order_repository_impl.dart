import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/google_cloud_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final Box<OrderModel> orderBox;

  OrderRepositoryImpl(this.orderBox);

  @override
  Future<Either<Failure, bool>> addOrder(OrderEntity order) async {
    try {
      // Manual conversion if needed, or update OrderModel.fromEntity
      final itemsModel = order.items.map((e) => OrderItemModel.fromEntity(e)).toList();
      
      String? eventId = order.googleEventId;
      bool syncSuccess = false;
      
      // --- Google Cloud Sync (before saving to get event ID) ---
      try {
        final settingsBox = Hive.box('settings');
        final settingsMap = settingsBox.get('appSettings');
        if (settingsMap != null) {
           final settings = Map<String, dynamic>.from(settingsMap);
           final googleService = GoogleCloudService();
           
           if (googleService.isAuthenticated) {
             
             // 1. Spreadsheet Sync
             if (settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
               print('LOG: Attempting to sync to Sheets...');
               await googleService.appendOrderToSheet(settings['googleSheetId'], order);
               syncSuccess = true; // Mark as synced if sheet append works (primary)
             }

             // 2. Calendar Sync - Lifecycle Management
             if (settings['syncCalendarEnabled'] == true) {
               if (eventId != null && eventId.isNotEmpty) {
                 print('LOG: Attempting to update existing Calendar event: $eventId');
                 final success = await googleService.updateCalendarEvent(eventId, order);
                 if (!success) {
                   print('LOG: Update failed (Event likely deleted). Creating new event.');
                   eventId = await googleService.createCalendarEvent(order);
                 }
               } else {
                 print('LOG: No Event ID found. Creating new Calendar event.');
                 eventId = await googleService.createCalendarEvent(order);
               }
             }
           } else {
             print('LOG: Google Service not authenticated, skipping sync.');
           }
        }
      } catch (e) {
        print('LOG: Error during Google Sync: $e');
        syncSuccess = false; // Explicitly false on error
      }
      // -------------------------
      
      final orderModel = OrderModel(
        id: order.id,
        customerName: order.customerName,
        items: itemsModel,
        totalPrice: order.totalPrice,
        pendingBalance: order.pendingBalance,
        deliveryDate: order.deliveryDate,
        isSynced: syncSuccess, // Update model with actual sync status
        saleDate: order.saleDate,
        status: order.status,
        paymentStatus: order.paymentStatus,
        deliveryStatus: order.deliveryStatus,
        googleEventId: eventId,
      );

      await orderBox.put(orderModel.id, orderModel);
      print('LOG: Saved order to Hive - deliveryStatus: ${orderModel.deliveryStatus}, paymentStatus: ${orderModel.paymentStatus}, Synced: $syncSuccess');

      return Right(syncSuccess);
    } catch (e) {
      print('LOG: Error saving order to Hive: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrder(String id) async {
    try {
      // Get order before deleting to access googleEventId
      final order = orderBox.get(id);
      
      // Delete from Google Calendar if event exists
      if (order?.googleEventId != null && order!.googleEventId!.isNotEmpty) {
        try {
          final googleService = GoogleCloudService();
          if (googleService.isAuthenticated) {
            final settingsBox = Hive.box('settings');
            final settingsMap = settingsBox.get('appSettings');
            if (settingsMap != null) {
              final settings = Map<String, dynamic>.from(settingsMap);
              if (settings['syncCalendarEnabled'] == true) {
                print('LOG: Deleting calendar event: ${order.googleEventId}');
                await googleService.deleteCalendarEvent(order.googleEventId!);
              }
            }
          }
        } catch (e) {
          print('LOG: Error deleting calendar event: $e');
          // Don't fail the deletion if calendar sync fails
        }
      }

      // Delete from Hive
      await orderBox.delete(id);
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    try {
      final orders = orderBox.values.toList();
      return Right(orders);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
