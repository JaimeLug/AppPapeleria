/// Disparador de sincronización que necesitan los repositorios offline-first.
///
/// Es la parte mínima de [SyncManager] de la que dependen los repos: así
/// pueden pedir una subida a la nube sin acoplarse a la clase concreta (y se
/// puede inyectar un fake en los tests).
abstract class SyncTrigger {
  /// Sube a la nube lo pendiente (`isSynced == false`).
  Future<void> syncPendingData();
}
