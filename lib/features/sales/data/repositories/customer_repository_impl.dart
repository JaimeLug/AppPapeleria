import 'package:hive/hive.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';
import '../../../../core/services/google_cloud_service.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final Box<CustomerModel> _box;

  CustomerRepositoryImpl(this._box);

  @override
  Future<List<CustomerEntity>> getAllCustomers() async {
    return _box.values.toList();
  }

  @override
  Future<void> saveCustomer(CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    await _box.put(customer.id, model);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _box.delete(id);

    try {
      final googleService = GoogleCloudService();
      if (googleService.isAuthenticated) {
         final settingsBox = Hive.box('settings');
         final settingsMap = settingsBox.get('appSettings');
         if (settingsMap != null) {
           final settings = Map<String, dynamic>.from(settingsMap);
           if (settings['syncSheetsEnabled'] == true && settings['googleSheetId'] != null) {
             final sheetId = settings['googleSheetId'] as String;
             if (sheetId.isNotEmpty) {
               print('Intentando eliminar cliente $id de Cloud...');
               await googleService.deleteRowById(sheetId, 'Clientes', id);
             }
           }
         }
      }
    } catch (e) {
      print('Error al intentar borrar cliente de la nube: $e');
    }
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final lowerQuery = query.toLowerCase();
    return _box.values
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
