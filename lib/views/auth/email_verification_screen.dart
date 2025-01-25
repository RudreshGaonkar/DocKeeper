import 'package:dockeeper/core/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isVerifying = false; // To show a loading spinner during verification check

  // Function to check if the email is verified
  Future<void> checkEmailVerified() async {
    setState(() {
      isVerifying = true; // Show spinner
    });

    try {
      bool isVerified = await AuthService().checkEmailVerification(); // Call to check verification status

      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email verified successfully!')),
        );
        // Navigator.pushReplacementNamed(context, homeRoute); // Navigate to home screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())), // Show error message
      );
    } finally {
      setState(() {
        isVerifying = false; // Hide spinner
      });
    }
  }

  // Function to resend the verification email
  Future<void> resendVerificationEmail() async {
    try {
      await AuthService().checkEmailVerification(); // Call to resend the verification email
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email sent. Please check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())), // Show error message
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Verification'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            // Information message
            Text(
              'A verification email has been sent to your registered email address. Please verify your email to continue.',
              textAlign: TextAlign.center, // Center the text horizontally
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20), // Spacing between text and buttons

            // Resend email button
            ElevatedButton(
              onPressed: isVerifying ? null : resendVerificationEmail, // Disable if verifying
              child: Text('Resend Verification Email'),
            ),
            SizedBox(height: 20), // Spacing between buttons

            // Check verification status button
            ElevatedButton(
              onPressed: isVerifying ? null : checkEmailVerified, // Disable if verifying
              child: isVerifying
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Check Verification Status'),
            ),
            SizedBox(height: 20), // Spacing between buttons

            // Continue button
            TextButton(
              onPressed: () async {
                bool isVerified = await AuthService().checkEmailVerification();
                if (isVerified) {
                  // Navigate to the login screen if the email is verified
                  Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
                } else {
                  try {
                    // Resend the verification email
                    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Verification email resent. Please check your inbox.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sending verification email: $e')),
                    );
                  }
                }
                
              },
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.red, // Red text for sign-out
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
