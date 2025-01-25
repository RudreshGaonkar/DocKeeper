// home_screen.dart

import 'package:dockeeper/core/routes.dart';
// import 'package:dockeeper/main.dart';
import 'package:dockeeper/models/category_model.dart';
import 'package:dockeeper/models/reminder_model.dart';
import 'package:dockeeper/services/auth_service.dart';
import 'package:dockeeper/services/category_service.dart';
import 'package:dockeeper/services/document_service.dart';
import 'package:dockeeper/services/reminder_service.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  int currentTabIndex = 0;
  // String userId = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                // Navigator.pushNamed(context, settingsRoute);
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            FutureBuilder<String>(
              future: AuthService().getUserName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
                } else if (snapshot.hasError) {
                  return Text("Error", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
                }
                return Text(snapshot.data ?? "User", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),
              _buildCategoriesSection(),
              SizedBox(height: 20),
              _buildUpcomingRemindersSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentTabIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, categoryRoute);
                  },
                  child: Text("Show All", style: TextStyle(color: Colors.blue.shade900)),
                ),
              ],
            ),
            FutureBuilder<List<Category>>(
              future: CategoryService().fetchAllCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "No categories found",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Wrap(
                  spacing: 16, // Horizontal space between items
                  runSpacing: 16, // Vertical space between rows
                  children: snapshot.data!
                      .take(3)
                      .map(
                        (category) => GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, categoryRoute);
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder, size: 40, color: Colors.blue),
                              SizedBox(height: 5),
                              Text(
                                category.name,
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUpcomingRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upcoming Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        FutureBuilder<List<Reminder>>(
          future: ReminderService().fetchReminders(userId: AuthService().currentUserId), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("No reminders yet", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: snapshot.data!
                  .map(
                    (reminder) => FutureBuilder<String>(
                      future: DocumentService().fetchDocumentName(reminder.documentId),
                      builder: (context, documentSnapshot) {
                        if (documentSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (documentSnapshot.hasError) {
                          return ListTile(
                            leading: Icon(Icons.insert_drive_file, color: Colors.red),
                            title: Text("Error fetching document name"),
                          );
                        }
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(Icons.insert_drive_file, color: Colors.blue),
                            title: Text(documentSnapshot.data ?? "Unknown Document"),
                            subtitle: Text("Expiry: ${DateFormat('yyyy-MM-dd').format(reminder.reminderDate)}"),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                // Handle menu actions
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: "view", child: Text("View")),
                                PopupMenuItem(value: "edit", child: Text("Edit")),
                                PopupMenuItem(value: "delete", child: Text("Delete")),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }


  void _onBottomNavTap(int index) {
    setState(() {
      currentTabIndex = index;
    });
    switch (index) {
      case 0:
        // Navigator.pushReplacementNamed(context, homeRoute);
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
        Navigator.pushReplacementNamed(context, settingsRoute);
        break;
    }
  }
}
