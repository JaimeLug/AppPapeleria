import 'product_repository.dart';

/// Contrato de la fuente remota de productos (Supabase) tal como la consumen
/// el repositorio offline-first y el SyncManager.
///
/// Extiende [ProductRepository] con [deletedIdsAmong], necesario para la poda
/// segura. Depender de esta interfaz (no de la clase Supabase concreta)
/// permite inyectar fakes en los tests.
abstract class RemoteProductRepository implements ProductRepository {
  /// De una lista de ids, devuelve los que en el servidor están marcados como
  /// borrados (`is_deleted = true`). Base de la poda segura.
  Future<Set<String>> deletedIdsAmong(List<String> ids);
}
