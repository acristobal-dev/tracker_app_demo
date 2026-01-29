class ServerErrorConnection implements Exception {
  const ServerErrorConnection({
    required this.message,
    required this.error,
  });

  final String message;
  final String error;
}
