String getAuthErrorMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'User is not registered. Please sign up first.';
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return 'User is not registered or invalid credentials. Please check or sign up.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'email-already-in-use':
      return 'An account already exists for this email.';
    case 'invalid-email':
      return 'The email address is invalid.';
    case 'weak-password':
      return 'The password is too weak. Please use at least 6 characters.';
    case 'user-disabled':
      return 'This user account has been disabled.';
    default:
      return 'Authentication error ($code). Please try again.';
  }
}