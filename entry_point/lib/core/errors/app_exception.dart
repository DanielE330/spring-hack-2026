class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors;

  @override
  String toString() => 'AppException($statusCode): $message';
}
