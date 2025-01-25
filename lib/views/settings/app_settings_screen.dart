import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dockeeper/core/routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login screen after logging out
      Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Log Out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: CustomBottomNavBar(
      //   currentIndex: 4,
      //   onTap: _onBottomNavTap,
      // ),
    );
  }

  // void _onBottomNavTap(int index) {
  //   int currentTabIndex = 4;
  //   setState(() {
  //     currentTabIndex = index;
  //   });
  //   switch (index) {
  //     case 0:
  //       // Navigator.pushReplacementNamed(context, homeRoute);
  //       break;
  //     case 1:
  //       // Navigator.pushReplacementNamed(context, reminderRoute);
  //       break;
  //     case 2:
  //       Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
  //       break;
  //     case 3:
  //       // Navigator.pushReplacementNamed(context, locationRoute);
  //       break;
  //     case 4:
  //       Navigator.pushReplacementNamed(context, settingsRoute);
  //       break;
  //   }
  // }
}
