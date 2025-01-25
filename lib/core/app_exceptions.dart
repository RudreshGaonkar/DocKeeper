class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException() : super('User not found.');
}

class WrongPasswordException extends AuthException {
  const WrongPasswordException() : super('Wrong password.');
}

class GenericAuthException extends AuthException {
  const GenericAuthException(String code) : super('Auth error: $code');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException() : super("Email already in use/ register");
}

class WeakPasswordException extends AuthException{
  const WeakPasswordException(): super("Weak Password");
}