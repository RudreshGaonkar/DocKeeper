import 'package:firebase_auth/firebase_auth.dart';

class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() {
    return message;
  }
}

/// Handles Firebase-specific exceptions centrally
class FirebaseExceptionHandler {
  static String handleException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'wrong-password':
        return 'The password you entered is incorrect.';
      case 'user-not-found':
        return 'No user found with this email. Please register.';
      case 'user-disabled':
        return 'This user has been disabled. Contact support.';
      case 'reauthentication-failed':
        return 'Failed to reauthenticate. Please try again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}