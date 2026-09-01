class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class DatabaseException extends AppException {
  DatabaseException(super.message);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}
