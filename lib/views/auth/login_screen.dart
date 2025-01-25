// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../core/routes.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //final TextEditingController nameController = TextEditingController(); // Controller for the name field
  final TextEditingController emailController = TextEditingController(); // Controller for the email field
  final TextEditingController passwordController = TextEditingController(); // Controller for the password field
  bool showPassword = false; // Toggles password visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background color
          Container(color: const Color.fromARGB(255, 36, 153, 248)),

          
          // Welcome message at the top
          Positioned(
            top: 80,
            left: 20,
            right: 20, // Adjusted to ensure text fits within screen bounds
            child: Text(
              'Welcome to DocKeeper',
              textAlign: TextAlign.center, // Center the text horizontally
              style: TextStyle(
                fontSize: 26, // Font size for the title
                fontWeight: FontWeight.bold, // Bold text
                color: const Color.fromARGB(255, 255, 255, 255), // Dark blue color
              ),
            ),
          ),

          // Login card at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7, // Card height
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), // Rounded top-left corner
                  topRight: Radius.circular(30), // Rounded top-right corner
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Padding around card content
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
                  children: [
                    // Title for the login card
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 30, // Font size for the title
                        fontWeight: FontWeight.bold, // Bold text
                        color: Colors.blue.shade900, // Dark blue color
                      ),
                    ),
                    SizedBox(height: 20), // Spacing between title and fields

                    // Name text field
                    // CustomTextField(
                    //   controller: nameController, // Controller for name input
                    //   labelText: 'Full Name', // Label for the text field
                    //   icon: Icons.person, // Icon for the field
                    // ),
                    // SizedBox(height: 20), // Spacing between fields

                    // Email text field
                    CustomTextField(
                      controller: emailController, // Controller for email input
                      labelText: 'Email', // Label for the text field
                      icon: Icons.email, // Icon for the field
                    ),
                    SizedBox(height: 20), // Spacing between fields

                    // Password text field
                    CustomTextField(
                      controller: passwordController, // Controller for password input
                      labelText: 'Password', // Label for the text field
                      icon: Icons.lock, // Icon for the field
                      obscureText: !showPassword, // Toggles visibility
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility // Show password icon
                              : Icons.visibility_off, // Hide password icon
                        ),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword; // Toggle visibility
                          });
                        },
                      ),
                    ),
                     // Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, resetRoute); // Navigate to reset password screen
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue.shade900, // Link color
                            fontSize: 14, // Font size for the link
                            fontWeight: FontWeight.bold, // Bold text
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20), // Spacing between password field and button

                    // Login button
                    CustomButton(
                      text: 'Login', // Button text
                      onPressed: () async {

                        
                        String email = emailController.text.trim(); // Get email input
                        String password = passwordController.text.trim(); // Get password input

                        // Validate inputs
                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill in all fields')), // Show error message
                          );
                          return;
                        }

                        try {
                          // Attempt to log in
                          await AuthService().loginWithEmailAndPassword(email, password);

                          // Check email verification
                          bool isVerified = await AuthService().checkEmailVerification();
                          if (!isVerified) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please verify your email before logging in. Verification email resent.')),
                            );
                            // await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                            Navigator.pushNamed(context, verifyEmailRoute);
                            return;
                          }
                          await AuthService().loginWithEmailAndPassword(email, password);

                          // Re-authenticate if required (required after a reset flow)
                          try {
                            await AuthService().reauthenticateUser(email, password);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to refresh credentials: ${e.toString()}')),
                            );
                            return;
                          }
                          Navigator.pushReplacementNamed(context, homeRoute); // Navigate to home on success
                        }

                        catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())), // Show error message
                          );
                        }
                      },
                    ),

                    SizedBox(height: 20), // Spacing between button and registration text

                    // Registration prompt and link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have a account?",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(context, registerRoute, (route) => false); // Navigate to registration screen
                          },
                          child: Text(
                            "Sign Up!",
                            style: TextStyle(
                              color: Colors.blue.shade900, // Link color
                              fontSize: 16, // Font size for the link
                              //fontWeight: FontWeight.bold, // Bold text
                              //decoration: TextDecoration.underline, // Underline for link
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

