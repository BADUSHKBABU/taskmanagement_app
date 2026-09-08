abstract class AuthEvent {
  const AuthEvent();

}

class CheckAuthEvent extends AuthEvent {
  const CheckAuthEvent();
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({required this.email, required this.password});

}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const SignUpEvent({
    required this.email,
    required this.password,
    required this.name,
  });

}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

class ClearAuthErrorEvent extends AuthEvent {
  const ClearAuthErrorEvent();
}
