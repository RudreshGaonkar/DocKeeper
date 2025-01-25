import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_exceptions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Getter for current user's ID
  String get currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }
    return user.uid; // Ensure this is a non-nullable String
  }

  Future<void> reauthenticateUser(String email, String password) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: password);
        await user.reauthenticateWithCredential(credential);
        await user.reload(); // Refresh the user's profile
      } else {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No user is currently signed in.',
        );
      }
    } catch (e) {
      throw FirebaseAuthException(
        code: 'reauthentication-failed',
        message: 'Failed to reauthenticate user: ${e.toString()}',
      );
    }
  }


  /// Logs in the user with the provided email and password.
  /// 
  /// Throws an [AuthException] if the login fails.
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw UserNotFoundException();
      } else if (e.code == 'wrong-password') {
        throw WrongPasswordException();
      } else {
        throw GenericAuthException(e.code);
      }
    }
  }

  /// Registers a new user with email and password.
/// Also updates the user's display name.
Future<void> registerUser(String name, String email, String password) async {
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    /// Save user details to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'userId': userCredential.user!.uid,
      });

      // Send email verification
      await userCredential.user!.sendEmailVerification();
    } catch (e) {
      throw e;
    }

  //   await userCredential.user?.reload(); // Reload user to reflect changes
  // } on FirebaseAuthException catch (e) {
  //   if (e.code == 'email-already-in-use') {
  //     throw EmailAlreadyInUseException();
  //   } else if (e.code == 'weak-password') {
  //     throw WeakPasswordException();
  //   } else {
  //     throw GenericAuthException(e.code);
  //   }
  // }

}


  /// Logs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Checks if the user is currently authenticated.
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// Checks if the currently signed-in user's email is verified.
  /// 
  /// Returns `true` if verified, `false` otherwise.
  /// Throws an [AuthException] if no user is signed in.
  Future<bool> checkEmailVerification() async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw GenericAuthException("No user is signed in.");
    }

    await user.reload(); // Reload the user to get the latest data.
    user = _auth.currentUser; // Update user instance after reload.

    return user?.emailVerified ?? false; // Return email verification status.
  }

  /// Sends a verification email to the currently signed-in user.
  /// 
  /// Throws an [AuthException] if no user is signed in or if sending fails.
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw GenericAuthException("No user is signed in.");
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw GenericAuthException("Email is already verified.");
    }
  }

  /// Sends a password reset email to the specified email address.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw UserNotFoundException();
      } else {
        throw GenericAuthException(e.code);
      }
    }
  }

  // Method to fetch the user's name from Firestore
  Future<String> getUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return userDoc['name'] ?? 'User'; // Replace 'name' with the actual field name in Firestore
        } else {
          throw Exception('User document does not exist.');
        }
      } catch (e) {
        throw Exception('Failed to fetch user name: $e');
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }
}


