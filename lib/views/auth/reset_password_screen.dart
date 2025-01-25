import 'package:dockeeper/widgets/loading_spinner.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/routes.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  // Function to reset password
  Future<void> resetPassword() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      await AuthService().sendPasswordResetEmail(email); // Call to reset password
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent! Please check your email.')),
      );

      // Navigate back to login screen
      Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter your email address and we will send you a link to reset your password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            // Email TextField
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Reset Password Button
            ElevatedButton(
              onPressed: isLoading ? null : resetPassword, // Disable when loading
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Send Reset Link'),
            ),
            SizedBox(height: 10),

            // Back to Login
            TextButton(
              onPressed: () {
                isLoading
                ? LoadingSpinner() // Spinner shown during loading
                : Text('Update Password');
                Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
              },
              child: Text(
                'Back to Login',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade900,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
