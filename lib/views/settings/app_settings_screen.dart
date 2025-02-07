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
  bool _isDarkMode = false; // Local toggle for Dark Mode
  int currentTabIndex = 4;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  /// Loads the profile picture path from SharedPreferences.
  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    final profilePath = prefs.getString('profile_picture');
    if (profilePath != null && profilePath.isNotEmpty) {
      setState(() {
        _profileImage = File(profilePath);
      });
    }
  }

  /// Saves the selected profile picture path to SharedPreferences.
  Future<void> _saveProfilePicture(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_picture', path);
  }

  /// Picks a profile picture from the gallery and saves its path locally.
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

  /// Toggles dark mode.
  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    // In a full implementation, update your app's theme state (via Provider, Bloc, etc.)
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
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out'),
              onTap: _logout,
            ),
            const Divider(),
            // Appearance Section
            ExpansionTile(
              leading: const Icon(Icons.palette),
              title: const Text('Appearance'),
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: _isDarkMode,
                  onChanged: _toggleDarkMode,
                  secondary: const Icon(Icons.brightness_6),
                ),
                ListTile(
                  title: const Text('System Default'),
                  onTap: () {
                    // reset toggle to system default settings
                    setState(() {
                      _isDarkMode = false;
                    });
                  },
                ),
              ],
            ),
            // Additional settings sections can be added here.
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
        // Navigator.pushReplacementNamed(context, reminderRoute);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
        break;
      case 3:
        // Navigator.pushReplacementNamed(context, locationRoute);
        break;
      case 4:
        // Already in settings, optionally do nothing.
        break;
      default:
        break;
    }
  }
}
