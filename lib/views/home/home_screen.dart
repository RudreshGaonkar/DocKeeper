// // home_screen.dart

// import 'package:dockeeper/core/routes.dart';
// // import 'package:dockeeper/main.dart';
// import 'package:dockeeper/models/category_model.dart';
// import 'package:dockeeper/models/reminder_model.dart';
// import 'package:dockeeper/services/auth_service.dart';
// import 'package:dockeeper/services/category_service.dart';
// import 'package:dockeeper/services/document_service.dart';
// import 'package:dockeeper/services/reminder_service.dart';
// import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final TextEditingController searchController = TextEditingController();
//   int currentTabIndex = 0;
//   // String userId = "";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: Row(
//           children: [
//             GestureDetector(
//               onTap: () {
//                 // Navigator.pushNamed(context, settingsRoute);
//               },
//               child: CircleAvatar(
//                 backgroundColor: Colors.grey.shade300,
//                 child: Icon(Icons.person, color: Colors.white),
//               ),
//             ),
//             SizedBox(width: 10),
//             FutureBuilder<String>(
//               future: AuthService().getUserName(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Text("Loading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
//                 } else if (snapshot.hasError) {
//                   return Text("Error", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
//                 }
//                 return Text(snapshot.data ?? "User", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
//               },
//             ),
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                 ),
//               ),
//               SizedBox(height: 20),
//               _buildCategoriesSection(),
//               SizedBox(height: 20),
//               _buildUpcomingRemindersSection(),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: CustomBottomNavBar(
//         currentIndex: currentTabIndex,
//         onTap: _onBottomNavTap,
//       ),
//     );
//   }

//   Widget _buildCategoriesSection() {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         color: Colors.grey.shade100,
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Categories",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pushNamed(context, categoryRoute);
//                   },
//                   child: Text("Show All", style: TextStyle(color: Colors.blue.shade900)),
//                 ),
//               ],
//             ),
//             FutureBuilder<List<Category>>(
//               future: CategoryService().fetchAllCategories(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(child: CircularProgressIndicator());
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return Padding(
//                     padding: const EdgeInsets.all(10.0),
//                     child: Text(
//                       "No categories found",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   );
//                 }

//                 return Wrap(
//                   spacing: 16, // Horizontal space between items
//                   runSpacing: 16, // Vertical space between rows
//                   children: snapshot.data!
//                       .take(3)
//                       .map(
//                         (category) => GestureDetector(
//                           onTap: () {
//                             Navigator.pushNamed(context, categoryRoute);
//                           },
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(Icons.folder, size: 40, color: Colors.blue),
//                               SizedBox(height: 5),
//                               Text(
//                                 category.name,
//                                 style: TextStyle(fontSize: 14),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ],
//                           ),
//                         ),
//                       )
//                       .toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }


//   Widget _buildUpcomingRemindersSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Upcoming Reminders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         SizedBox(height: 10),
//         FutureBuilder<List<Reminder>>(
//           future: ReminderService().fetchReminders(userId: AuthService().currentUserId), 
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Center(child: CircularProgressIndicator());
//             } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Text("No reminders yet", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
//               );
//             }
//             return Column(
//               children: snapshot.data!
//                   .map(
//                     (reminder) => FutureBuilder<String>(
//                       future: DocumentService().fetchDocumentName(reminder.documentId),
//                       builder: (context, documentSnapshot) {
//                         if (documentSnapshot.connectionState == ConnectionState.waiting) {
//                           return Center(child: CircularProgressIndicator());
//                         } else if (documentSnapshot.hasError) {
//                           return ListTile(
//                             leading: Icon(Icons.insert_drive_file, color: Colors.red),
//                             title: Text("Error fetching document name"),
//                           );
//                         }
//                         return Card(
//                           margin: EdgeInsets.only(bottom: 10),
//                           child: ListTile(
//                             leading: Icon(Icons.insert_drive_file, color: Colors.blue),
//                             title: Text(documentSnapshot.data ?? "Unknown Document"),
//                             subtitle: Text("Expiry: ${DateFormat('yyyy-MM-dd').format(reminder.reminderDate)}"),
//                             trailing: PopupMenuButton<String>(
//                               onSelected: (value) {
//                                 // Handle menu actions
//                               },
//                               itemBuilder: (context) => [
//                                 PopupMenuItem(value: "view", child: Text("View")),
//                                 PopupMenuItem(value: "edit", child: Text("Edit")),
//                                 PopupMenuItem(value: "delete", child: Text("Delete")),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   )
//                   .toList(),
//             );
//           },
//         ),
//       ],
//     );
//   }


//   void _onBottomNavTap(int index) {
//     setState(() {
//       currentTabIndex = index;
//     });
//     switch (index) {
//       case 0:
//         // Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
//         break;
//       case 1:
//         // Navigator.pushReplacementNamed(context, reminderRoute);
//         break;
//       case 2:
//         Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
//         break;
//       case 3:
//         // Navigator.pushReplacementNamed(context, locationRoute);
//         break;
//       case 4:
//         Navigator.pushNamed(context, settingsRoute);
//         break;
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
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
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Listen for changes in the search field.
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Builds the AppBar with a profile icon and user's name.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Optionally navigate to a profile screen.
            },
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          FutureBuilder<String>(
            future: AuthService().getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Loading...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
              } else if (snapshot.hasError) {
                return const Text("Error",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
              }
              return Text(snapshot.data ?? "User",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
            },
          ),
        ],
      ),
    );
  }

  /// Widget to display search results when [searchQuery] is not empty.
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('documents')
          .where('userId', isEqualTo: AuthService().currentUserId)
          .where('title', isGreaterThanOrEqualTo: searchQuery)
          .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No matching documents found."),
          );
        }
        final docs = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Search Results",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final docData = docs[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(docData['title'] ?? 'Untitled'),
                    subtitle: Text(docData['description'] ?? ''),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        viewRoute,
                        arguments: {'documentId': docs[index].id},
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Widget to display categories in a horizontal scroll view.
  Widget _buildCategoriesSection() {
    return FutureBuilder<List<Category>>(
      future: CategoryService().fetchAllCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, categoryRoute);
                },
                child: const Text(
                  "No categories found. Tap to add category.",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
        final categories = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and "Show All" button.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Categories",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, categoryRoute);
                    },
                    child: const Text("Show All",
                        style: TextStyle(color: Colors.blue, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Swipe horizontally to explore categories →",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          documentRoute,
                          arguments: {'categoryId': category.categoryId},
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.folder, size: 40, color: Colors.blue),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget to display upcoming reminders with section title.
  Widget _buildUpcomingRemindersSection() {
    return FutureBuilder<List<Reminder>>(
      future: ReminderService().fetchReminders(userId: AuthService().currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "No reminders yet",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        final now = DateTime.now();
        // Filter reminders to only include those with 30 days or less left.
        final reminders = snapshot.data!
            .where((reminder) => reminder.reminderDateTime.difference(now).inDays <= 30)
            .toList();
        if (reminders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "No upcoming reminders within 30 days",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Upcoming Reminders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: reminders.map((reminder) {
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
                    final daysLeft = reminder.reminderDateTime.difference(now).inDays;
                    final progress = daysLeft > 0 ? (1 - (daysLeft / 30)).clamp(0.0, 1.0) : 1.0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
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
                            Text("Reminder Date: ${DateFormat('yyyy-MM-dd').format(reminder.reminderDateTime)}"),
                            Text("$daysLeft days left", style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: progress),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'view') {
                              Navigator.pushNamed(
                                context,
                                viewRoute,
                                arguments: {'documentId': reminder.documentId},
                              );
                            } else if (value == 'edit') {
                              // TODO: Implement edit reminder screen navigation.
                            } else if (value == 'delete') {
                              await ReminderService().deleteReminder(reminder.reminderId);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'view', child: Text("View")),
                            PopupMenuItem(value: 'edit', child: Text("Edit")),
                            PopupMenuItem(value: 'delete', child: Text("Delete")),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            viewRoute,
                            arguments: {'documentId': reminder.documentId},
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // int currentTabIndex = 0;

  void _onBottomNavTap(int index) {
    setState(() {
      currentTabIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, homeRoute);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, reminderRoute);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (searchQuery.isNotEmpty)
                _buildSearchResults()
              else ...[
                _buildCategoriesSection(),
                const SizedBox(height: 20),
                _buildUpcomingRemindersSection(),
              ],
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
}

