import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  int currentTabIndex = 4;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  /// Loads the profile picture if it belongs to the logged-in user.
  Future<void> _loadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final profilePath = prefs.getString('profile_picture_$_userId');

    if (profilePath != null && profilePath.isNotEmpty) {
      setState(() {
        _profileImage = File(profilePath);
      });
    }
  }

  /// Saves the profile picture path for the specific user.
  Future<void> _saveProfilePicture(String path) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_picture_${user.uid}', path);
  }

  /// Picks a profile picture, saves it, and displays it.
  Future<void> _pickProfilePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _profileImage = file;
      });
      await _saveProfilePicture(pickedFile.path);
    }
  }

  /// Logs the user out and navigates to the login screen.
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  /// Logs out and redirects to the Reset Password screen.
  Future<void> _resetPassword() async {
    // await FirebaseAuth.instance.signOut();
    Navigator.pushNamed(context, resetRoute);
  }

  /// Deletes the user account after confirmation.
  Future<void> _deleteAccount() async {
    bool confirmDelete = await _showConfirmationDialog(
      title: "Delete Account",
      content: "Are you sure you want to delete your account? This action cannot be undone.",
    );

    if (confirmDelete) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    }
  }

  /// Shows a confirmation dialog before deleting the account.
  Future<bool> _showConfirmationDialog({required String title, required String content}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Confirm", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _pickProfilePicture,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 15,
                      child: Icon(
                        Icons.camera_alt,
                        size: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Section
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Account'),
              subtitle: const Text('Manage your account details'),
            ),
            ListTile(
              leading: const Icon(Icons.password, color: Colors.blue),
              title: const Text('Reset Password'),
              onTap: _resetPassword,
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Account'),
              onTap: _deleteAccount,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out'),
              onTap: _logout,
            ),

            const Divider(),

            // About Section
            ExpansionTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              children: [
                ListTile(
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentTabIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      currentTabIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, reminderRoute);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, locationRoute);
        break;
      case 4:
        // Already in settings, optionally do nothing.
        break;
      default:
        break;
    }
  }
}
