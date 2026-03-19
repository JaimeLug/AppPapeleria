class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}

class CloudSyncException implements Exception {
  final String message;
  CloudSyncException(this.message);
  @override
  String toString() => message;
}
