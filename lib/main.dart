import 'package:dockeeper/views/auth/email_verification_screen.dart';
import 'package:dockeeper/views/auth/register_screen.dart';
import 'package:dockeeper/views/auth/reset_password_screen.dart';
import 'package:dockeeper/views/document/add_document_screen.dart';
import 'package:dockeeper/views/home/category_list_screen.dart';
import 'package:dockeeper/views/home/document_list_screen.dart';
import 'package:dockeeper/views/home/home_screen.dart';
import 'package:dockeeper/views/settings/app_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'views/auth/login_screen.dart';
import 'core/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocKeeper',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: AuthCheck(), // Handles initial route dynamically
      routes: {
        loginRoute: (context) => LoginScreen(),
        registerRoute: (context) => RegisterScreen(),
        resetRoute: (context) => ResetPasswordScreen(),
        verifyEmailRoute: (context) => EmailVerificationScreen(),
        homeRoute: (context) => HomeScreen(),
        addDocumentRoute : (context) => AddDocumentScreen(),
        categoryRoute : (context) => CategoryScreen(),
        settingsRoute : (context) => SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/documents') {
          final args = settings.arguments as Map<String, dynamic>;
          print('Routing to DocumentScreen with args: $args'); // Debugging step
          return MaterialPageRoute(
            builder: (context) => DocumentScreen(categoryId: args['categoryId']),
          );
        }
        return null;
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    // Check if user is logged in and email is verified
    if (user != null) {
      if (user.emailVerified) {
        return HomeScreen(); // Navigate to Home if verified
      } else {
        return EmailVerificationScreen(); // Navigate to Email Verification
      }
    } else {
      return LoginScreen(); // Navigate to Login if not logged in
    }
  }
}
