// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dockeeper/core/routes.dart';
// import 'package:dockeeper/models/reminder_model.dart';
// import 'package:dockeeper/services/auth_service.dart';
// import 'package:dockeeper/services/document_service.dart';
// import 'package:dockeeper/services/reminder_service.dart';
// import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class ReminderScreen extends StatefulWidget {
//   const ReminderScreen({Key? key}) : super(key: key);

//   @override
//   _ReminderScreenState createState() => _ReminderScreenState();
// }

// class _ReminderScreenState extends State<ReminderScreen> {
//   String? userId;
//   // Filter options: 'newlyAdded', 'dateAdded', 'completed'
//   String _selectedFilter = 'newlyAdded';

//   @override
//   void initState() {
//     super.initState();
//     userId = AuthService().currentUserId;
//   }

//   /// Builds a row of ChoiceChips for filtering the reminders.
//   Widget _buildFilterChips() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: [
//             ChoiceChip(
//               label: const Text('Newly Added'),
//               selected: _selectedFilter == 'newlyAdded',
//               onSelected: (selected) {
//                 setState(() {
//                   _selectedFilter = 'newlyAdded';
//                 });
//               },
//             ),
//             const SizedBox(width: 8),
//             ChoiceChip(
//               label: const Text('Date Added'),
//               selected: _selectedFilter == 'dateAdded',
//               onSelected: (selected) {
//                 setState(() {
//                   _selectedFilter = 'dateAdded';
//                 });
//               },
//             ),
//             const SizedBox(width: 8),
//             ChoiceChip(
//               label: const Text('Completed'),
//               selected: _selectedFilter == 'completed',
//               onSelected: (selected) {
//                 setState(() {
//                   _selectedFilter = 'completed';
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Fetches and sorts/filters the reminders based on the selected filter.
//   Future<List<Reminder>> _fetchAndFilterReminders() async {
//     try {
//       List<Reminder> reminders =
//           await ReminderService().fetchReminders(userId: userId!);
//       final now = DateTime.now();

//       // If not filtering by "completed", only show reminders with 30 days or less left.
//       if (_selectedFilter != 'completed') {
//         reminders = reminders
//             .where((r) => r.reminderDateTime.difference(now).inDays <= 30)
//             .toList();
//       }

//       // Sort or filter based on selected option.
//       if (_selectedFilter == 'newlyAdded') {
//         // Sort descending by reminderId (assuming reminderId is a timestamp in string form).
//         reminders.sort((a, b) =>
//             int.parse(b.reminderId).compareTo(int.parse(a.reminderId)));
//       } else if (_selectedFilter == 'dateAdded') {
//         // Sort ascending by the scheduled reminder date.
//         reminders.sort((a, b) =>
//             a.reminderDateTime.compareTo(b.reminderDateTime));
//       } else if (_selectedFilter == 'completed') {
//         // Filter to show only completed reminders.
//         reminders = reminders.where((r) => r.isCompleted).toList();
//       }
//       return reminders;
//     } catch (e) {
//       throw Exception('Failed to fetch reminders: $e');
//     }
//   }

//   /// Returns a text label for the toggle button based on completion status.
//   String _toggleButtonText(bool isCompleted) =>
//       isCompleted ? 'Mark as Undone' : 'Mark as Done';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Reminders'),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           _buildFilterChips(),
//           Expanded(
//             child: FutureBuilder<List<Reminder>>(
//               future: _fetchAndFilterReminders(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(child: Text('No reminders found.'));
//                 }
//                 final reminders = snapshot.data!;
//                 return ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   itemCount: reminders.length,
//                   itemBuilder: (context, index) {
//                     final reminder = reminders[index];
//                     return FutureBuilder<String>(
//                       future: DocumentService().fetchDocumentName(reminder.documentId),
//                       builder: (context, docSnapshot) {
//                         if (docSnapshot.connectionState == ConnectionState.waiting) {
//                           return const Center(child: CircularProgressIndicator());
//                         } else if (docSnapshot.hasError) {
//                           return const ListTile(
//                             leading: Icon(Icons.insert_drive_file, color: Colors.red),
//                             title: Text("Error fetching document name"),
//                           );
//                         }
//                         final docTitle = docSnapshot.data ?? "Unknown Document";
//                         final now = DateTime.now();
//                         final daysLeft = reminder.reminderDateTime.difference(now).inDays;
//                         final progress = daysLeft > 0
//                             ? (1 - (daysLeft / 30)).clamp(0.0, 1.0)
//                             : 1.0;
//                         return Card(
//                           margin: const EdgeInsets.symmetric(vertical: 8),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 ListTile(
//                                   contentPadding: EdgeInsets.zero,
//                                   leading: const Icon(Icons.insert_drive_file, color: Colors.blue, size: 40),
//                                   title: Text(
//                                     docTitle,
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       decoration: reminder.isCompleted
//                                           ? TextDecoration.lineThrough
//                                           : null,
//                                     ),
//                                   ),
//                                   subtitle: Text(
//                                     'Reminder: ${DateFormat('yyyy-MM-dd HH:mm').format(reminder.reminderDateTime)}\n$daysLeft days left',
//                                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 LinearProgressIndicator(value: progress),
//                                 const SizedBox(height: 8),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                   children: [
//                                     ElevatedButton(
//                                       onPressed: () async {
//                                         final newStatus = !reminder.isCompleted;
//                                         await ReminderService().updateReminder(
//                                           reminder.reminderId,
//                                           {'isCompleted': newStatus},
//                                         );
//                                         setState(() {});
//                                       },
//                                       child: Text(_toggleButtonText(reminder.isCompleted)),
//                                     ),
//                                     PopupMenuButton<String>(
//                                       onSelected: (value) async {
//                                         if (value == 'view') {
//                                           Navigator.pushNamed(
//                                             context,
//                                             viewRoute,
//                                             arguments: {'documentId': reminder.documentId},
//                                           );
//                                         } else if (value == 'edit') {
//                                           // TODO: Implement edit reminder screen.
//                                         } else if (value == 'delete') {
//                                           await ReminderService().deleteReminder(reminder.reminderId);
//                                           setState(() {});
//                                         }
//                                       },
//                                       itemBuilder: (context) => const [
//                                         PopupMenuItem(value: 'view', child: Text("View")),
//                                         PopupMenuItem(value: 'edit', child: Text("Edit")),
//                                         PopupMenuItem(value: 'delete', child: Text("Delete")),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: CustomBottomNavBar(
//         currentIndex: 1,
//         onTap: _onBottomNavTap,
//       ),
//     );
//   }

//   void _onBottomNavTap(int index) {
//     switch (index) {
//       case 0:
//         Navigator.pushReplacementNamed(context, homeRoute);
//         break;
//       case 1:
//         // Already on ReminderScreen.
//         break;
//       case 2:
//         Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
//         break;
//       case 3:
//         Navigator.pushNamedAndRemoveUntil(context, locationRoute, (route) => false);
//         break;
//       case 4:
//         Navigator.pushReplacementNamed(context, settingsRoute);
//         break;
//       default:
//         break;
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Filter options: 'newlyAdded', 'dateAdded', 'completed'
  String _selectedFilter = 'newlyAdded';
    bool _reminderCompleted = false;

  @override
  void initState() {
    super.initState();
    userId = AuthService().currentUserId;
  }

  /// Builds a row of ChoiceChips for filtering the reminders.
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Hint text:
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "Filter by:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ChoiceChip(
              label: const Text('Newly Added'),
              selected: _selectedFilter == 'newlyAdded',
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = 'newlyAdded';
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Date Added'),
              selected: _selectedFilter == 'dateAdded',
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = 'dateAdded';
                });
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Completed'),
              selected: _selectedFilter == 'completed',
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = 'completed';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Fetches and sorts/filters the reminders based on the selected filter.
  Future<List<Reminder>> _fetchAndFilterReminders() async {
    try {
      List<Reminder> reminders =
          await ReminderService().fetchReminders(userId: userId!);
      final now = DateTime.now();

      if (_selectedFilter != 'completed') {
        // For "newlyAdded" and "dateAdded", exclude completed reminders.
        reminders = reminders.where((r) => !r.isCompleted).toList();
        // Only show reminders that are within 30 days.
        reminders = reminders
            .where((r) => r.reminderDateTime.difference(now).inDays <= 30)
            .toList();
      } else {
        // For the "completed" filter, show only completed reminders.
        reminders = reminders.where((r) => r.isCompleted).toList();
      }

      // Sort based on selected filter.
      if (_selectedFilter == 'newlyAdded') {
        // Sort descending by reminderId (assuming reminderId is a timestamp in string form).
        reminders.sort((a, b) =>
            int.parse(b.reminderId).compareTo(int.parse(a.reminderId)));
      } else if (_selectedFilter == 'dateAdded') {
        // Sort ascending by the scheduled reminder date.
        reminders.sort((a, b) =>
            a.reminderDateTime.compareTo(b.reminderDateTime));
      }
      return reminders;
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  /// Returns a text label for the toggle button based on completion status.
  String _toggleButtonText(bool isCompleted) =>
      isCompleted ? 'Mark as Undone' : 'Mark as Done';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: FutureBuilder<List<Reminder>>(
              future: _fetchAndFilterReminders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No reminders found.'));
                }
                final reminders = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return FutureBuilder<String>(
                      future: DocumentService().fetchDocumentName(reminder.documentId),
                      builder: (context, docSnapshot) {
                        if (docSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (docSnapshot.hasError) {
                          return const ListTile(
                            leading: Icon(Icons.insert_drive_file, color: Colors.red),
                            title: Text("Error fetching document name"),
                          );
                        }
                        final docTitle = docSnapshot.data ?? "Unknown Document";
                        final now = DateTime.now();
                        final daysLeft = reminder.reminderDateTime.difference(now).inDays;
                        final progress = daysLeft > 0
                            ? (1 - (daysLeft / 30)).clamp(0.0, 1.0)
                            : 1.0;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.insert_drive_file, color: Colors.blue, size: 40),
                                  title: Text(
                                    docTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: reminder.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Reminder: ${DateFormat('yyyy-MM-dd HH:mm').format(reminder.reminderDateTime)}\n$daysLeft days left',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(value: progress),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Mark as Done/Undone button.
                                    ElevatedButton(
                                      onPressed: () async {
                                        final newStatus = !reminder.isCompleted;
                                        // Update the reminder in Firestore.
                                       try {
                                          final reminderQuerySnapshot = await FirebaseFirestore.instance
                                              .collection('reminders')
                                              .where('documentId', isEqualTo: reminder.documentId)
                                              .get();
                                          if (reminderQuerySnapshot.docs.isNotEmpty) {
                                            final reminderDoc = reminderQuerySnapshot.docs.first;
                                            final currentStatus = reminderDoc.data()['isCompleted'] as bool? ?? false;
                                            await reminderDoc.reference.update({'isCompleted': !currentStatus});
                                            setState(() {
                                              _reminderCompleted = !currentStatus;
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Reminder marked as ${_reminderCompleted ? 'done' : 'not done'}')),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(content: Text('No reminder found for this document.')));
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to toggle reminder: $e')));
                                        }
                                        // Refresh UI.
                                        setState(() {});
                                      },
                                      child: Text(_toggleButtonText(reminder.isCompleted)),
                                    ),
                                    // Popup menu for other actions.
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'view') {
                                          // Navigate to the document view screen.
                                          Navigator.pushNamed(
                                            context,
                                            viewRoute,
                                            arguments: {'documentId': reminder.documentId},
                                          );
                                        } else if (value == 'edit') {
                                          // Navigate to the edit reminder/document screen.
                                          Navigator.pushNamed(
                                            context,
                                            updateRoute,
                                            arguments: {'documentId': reminder.documentId},
                                          );
                                        } else if (value == 'delete') {
                                          // Delete the reminder.
                                          await FirebaseFirestore.instance.collection('documents').doc(reminder.documentId).delete();
                                          final reminderQuerySnapshot = await FirebaseFirestore.instance
                                              .collection('reminders')
                                              .where('documentId', isEqualTo: reminder.documentId)
                                              .get();
                                          for (var doc in reminderQuerySnapshot.docs) {
                                            await doc.reference.delete();
                                          }
                                          // Refresh UI.
                                          setState(() {});
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(value: 'view', child: Text("View")),
                                        PopupMenuItem(value: 'edit', child: Text("Edit")),
                                        PopupMenuItem(value: 'delete', child: Text("Delete")),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
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
        Navigator.pushNamedAndRemoveUntil(context, locationRoute, (route) => false);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, settingsRoute);
        break;
      default:
        break;
    }
  }
}

