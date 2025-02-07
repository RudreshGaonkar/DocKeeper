// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:dockeeper/models/reminder_model.dart';
import 'package:dockeeper/services/auth_service.dart';
import 'package:dockeeper/services/document_service.dart';
import 'package:dockeeper/services/reminder_service.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  String? userId;

  @override
  void initState() {
    super.initState();
    // Retrieve the current user ID
    userId = AuthService().currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: ReminderService().fetchRemindersStream(userId: userId ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reminders found.'));
          }
          final reminders = snapshot.data!;
          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return FutureBuilder<String>(
                future: DocumentService().fetchDocumentName(reminder.documentId),
                builder: (context, documentSnapshot) {
                  if (documentSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (documentSnapshot.hasError) {
                    return const ListTile(
                      leading: Icon(Icons.insert_drive_file, color: Colors.red),
                      title: Text("Error fetching document name"),
                    );
                  }
                  final docTitle = documentSnapshot.data ?? "Unknown Document";

                  // Calculate days left until the reminder date.
                  final now = DateTime.now();
                  final daysLeft = reminder.reminderDateTime.difference(now).inDays;
                  // For demonstration, assume a total period of 30 days.
                  const totalDays = 30;
                  double progress = 0.0;
                  if (daysLeft > 0) {
                    progress = 1 - (daysLeft / totalDays);
                    progress = progress.clamp(0.0, 1.0);
                  } else {
                    progress = 1.0;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: const Icon(Icons.insert_drive_file, color: Colors.blue, size: 40),
                      title: Text(
                        docTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder Date: ${DateFormat('yyyy-MM-dd').format(reminder.reminderDateTime)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '$daysLeft days left',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: progress),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await ReminderService().deleteReminder(reminder.reminderId);
                          } else if (value == 'edit') {
                            // TODO: Navigate to edit reminder screen (future implementation)
                          } else if (value == 'view') {
                            Navigator.pushNamed(
                              context,
                              viewRoute,
                              arguments: {'documentId': reminder.documentId},
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'view', child: Text('View')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      // Tapping the card toggles completion status.
                      onTap: () async {
                        final newStatus = !reminder.isCompleted;
                        await ReminderService().updateReminder(
                            reminder.reminderId, {'isCompleted': newStatus});
                        setState(() {
                          // The stream updates automatically; no local change is needed.
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // Assuming index 1 represents the Reminders tab
        onTap: _onBottomNavTap,
      ),
    );
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, homeRoute);
        break;
      case 1:
        // Already on ReminderScreen.
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
        break;
      case 3:
        // Implement location screen navigation if needed.
        break;
      case 4:
        Navigator.pushReplacementNamed(context, settingsRoute);
        break;
      default:
        break;
    }
  }
}
