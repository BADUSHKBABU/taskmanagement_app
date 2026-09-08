class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException([this.message = 'A server error occurred. Please try again.', this.statusCode]);

  @override
  String toString() => 'ServerException: $message (StatusCode: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'No internet connection. Please check your network setting.']);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException([this.message = 'Authentication failed.', this.code]);

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Failed to access local cache.']);

  @override
  String toString() => 'CacheException: $message';
}
