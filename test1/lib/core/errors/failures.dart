abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred. Please try again.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Operating in offline mode.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to load cached data.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid data provided. Please check your inputs.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested task or resource not found.']);
}
