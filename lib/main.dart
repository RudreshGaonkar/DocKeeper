import 'dart:io';
import 'package:dockeeper/services/notification_service.dart';
import 'package:dockeeper/views/auth/email_verification_screen.dart';
import 'package:dockeeper/views/auth/register_screen.dart';
import 'package:dockeeper/views/auth/reset_password_screen.dart';
import 'package:dockeeper/views/document/add_document_screen.dart';
import 'package:dockeeper/views/document/edit_document_screen.dart';
import 'package:dockeeper/views/document/view_document_screen.dart';
import 'package:dockeeper/views/home/category_list_screen.dart';
import 'package:dockeeper/views/home/document_list_screen.dart';
import 'package:dockeeper/views/home/home_screen.dart';
import 'package:dockeeper/views/home/location_map_screen.dart';
import 'package:dockeeper/views/home/reminder_list_screen.dart';
import 'package:dockeeper/views/settings/app_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'views/auth/login_screen.dart';
import 'core/routes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;



Future<void> requestStoragePermissions() async {
  // For Android devices, request storage permission.
  if (Platform.isAndroid) {
    // Request basic storage permission.
    PermissionStatus storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      print("Storage permission not granted.");
    }
    // Optionally, if you need broad file access on Android 11+:
    PermissionStatus manageStatus = await Permission.manageExternalStorage.request();
    if (!manageStatus.isGranted) {
      print("Manage external storage permission not granted.");
    }
  }
}

Future<void> requestExactAlarmPermission() async {
  if (Platform.isAndroid) {
    // Check the current status.
    final status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      // Request the permission.
      final result = await Permission.scheduleExactAlarm.request();
      if (result.isGranted) {
        print('Exact alarm permission granted.');
      } else {
        print('Exact alarm permission denied.');
        // Optionally, prompt the user to open app settings.
        await openAppSettings();
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Request storage permissions at startup.
  await requestStoragePermissions();
  // Request exact alarm permission.
  await requestExactAlarmPermission();

  tz.initializeTimeZones();

  // await AndroidAlarmManager.initialize();

  await NotificationService.initialize();
  DateTime now = DateTime.now();
  DateTime futureTime = now.add(Duration(seconds: 30));
  NotificationService.scheduleNotification("123456", "Test Reminder", futureTime);
  NotificationService.scheduleNotification("Test","This works",DateTime.now().add(Duration(seconds: 5)));
  NotificationService.showInstantNotification("test",'$futureTime');

  
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
        addDocumentRoute: (context) => AddDocumentScreen(),
        categoryRoute: (context) => CategoryScreen(),
        settingsRoute: (context) => SettingsScreen(),
        reminderRoute: (context) => ReminderScreen(),
        locationRoute: (context) => LocationScreen(),
        // For updateRoute we now handle it in onGenerateRoute.
        viewRoute: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('documentId')) {
            return ViewScreen(documentId: args['documentId']);
          } else {
            return const ErrorScreen(message: 'Missing or invalid arguments for ViewScreen.');
          }
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/documents') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('categoryId')) {
            return MaterialPageRoute(
              builder: (context) => DocumentScreen(categoryId: args['categoryId']),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => const ErrorScreen(
                message: 'Missing or invalid arguments for the /documents route.',
              ),
            );
          }
        }
        if (settings.name == updateRoute) {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('documentId')) {
            return MaterialPageRoute(
              builder: (context) => UpdateDocumentScreen(documentId: args['documentId']),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => const ErrorScreen(
                message: 'Missing or invalid arguments for UpdateDocumentScreen.',
              ),
            );
          }
        }
        return null; // Default behavior for unknown routes.
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
      return user.emailVerified ? HomeScreen() : EmailVerificationScreen();
    } else {
      return LoginScreen();
    }
  }
}

// A fallback screen for invalid routes or arguments.
class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 18, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
