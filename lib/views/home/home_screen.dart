// import 'dart:async';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dockeeper/core/routes.dart';
// import 'package:dockeeper/models/category_model.dart';
// import 'package:dockeeper/models/reminder_model.dart';
// import 'package:dockeeper/services/auth_service.dart';
// import 'package:dockeeper/services/category_service.dart';
// import 'package:dockeeper/services/document_service.dart';
// import 'package:dockeeper/services/reminder_service.dart';
// import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final TextEditingController searchController = TextEditingController();
//   Timer? _debounce;
//   String activeSearchQuery = "";
//   int currentTabIndex = 0;
//   String searchQuery = "";
//   File? _profileImage;

//   @override
//   void initState() {
//     super.initState();
//     _loadProfilePicture();
//     searchController.addListener(_onSearchChanged);
//   }

//   void _onSearchChanged() {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//       _debounce = Timer(const Duration(milliseconds: 300), () {
//         setState(() {
//           activeSearchQuery = searchController.text.trim();
//           print("Active search query: $activeSearchQuery");
//         });
//       });
//   }

//   @override
//   void dispose() {
//     searchController.removeListener(_onSearchChanged);
//     _debounce?.cancel();
//     searchController.dispose();
//     super.dispose();
//   }

//   /// Loads the profile picture for the current user from SharedPreferences.
//   Future<void> _loadProfilePicture() async {
//     final prefs = await SharedPreferences.getInstance();
//     String key = 'profile_picture_${AuthService().currentUserId}';
//     final profilePath = prefs.getString(key);
//     if (profilePath != null && profilePath.isNotEmpty) {
//       setState(() {
//         _profileImage = File(profilePath);
//       });
//     }
//   }

//   // @override
//   // void dispose() {
//   //   searchController.removeListener(_onSearchChanged);
//   //   _debounce?.cancel();
//   //   searchController.dispose();
//   //   super.dispose();
//   // }

//   /// Builds the AppBar with a profile picture (if available) and the user's name.
//   PreferredSizeWidget buildAppBar() {
//     return AppBar(
//       automaticallyImplyLeading: false,
//       title: Row(
//         children: [
//           // Profile picture section.
//           GestureDetector(
//             onTap: () {
//               // Optionally navigate to a profile screen.
//             },
//             child: CircleAvatar(
//               backgroundColor: Colors.grey.shade300,
//               backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
//               child: _profileImage == null ? Icon(Icons.person, color: Colors.white) : null,
//             ),
//           ),
//           const SizedBox(width: 10),
//           FutureBuilder<String>(
//             future: AuthService().getUserName(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Text(
//                   "Loading...",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 );
//               } else if (snapshot.hasError) {
//                 return const Text(
//                   "Error",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 );
//               }
//               return Text(
//                 snapshot.data ?? "User",
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   /// Widget to display search results using the active search query.
//   Widget _buildSearchResults() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('documents')
//           .where('userId', isEqualTo: AuthService().currentUserId)
//           .orderBy('title')
//           .startAt(["test 51"])
//           .endAt(["test 51" + '\uf8ff'])
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Text("No matching documents found."),
//           );
//         }
//         if (snapshot.hasError) {
//           return Text("Error: ${snapshot.error}");
//         }
//         final docs = snapshot.data!.docs;
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Search Results",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: docs.length,
//               itemBuilder: (context, index) {
//                 final docData = docs[index].data() as Map<String, dynamic>;
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 6),
//                   child: ListTile(
//                     title: Text(docData['title'] ?? 'Untitled'),
//                     subtitle: Text(docData['description'] ?? ''),
//                     onTap: () {
//                       Navigator.pushNamed(
//                         context,
//                         viewRoute,
//                         arguments: {'documentId': docs[index].id},
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }


//   /// Widget to display categories in a horizontal scroll view.
//   Widget _buildCategoriesSection() {
//     return FutureBuilder<List<Category>>(
//       future: CategoryService().fetchAllCategories(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Container(
//             padding: const EdgeInsets.all(16),
//             child: const Center(child: CircularProgressIndicator()),
//           );
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Center(
//               child: TextButton(
//                 onPressed: () {
//                   Navigator.pushNamed(context, categoryRoute);
//                 },
//                 child: const Text(
//                   "No categories found. Tap to add category.",
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }
//         final categories = snapshot.data!;
//         return Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header row with title and "Show All" button.
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     "Categories",
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushNamed(context, categoryRoute);
//                     },
//                     child: const Text(
//                       "Show All",
//                       style: TextStyle(color: Colors.blue, fontSize: 16),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               const Text(
//                 "Swipe horizontally to explore categories →",
//                 style: TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 height: 110,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: categories.length,
//                   separatorBuilder: (context, index) =>
//                       const SizedBox(width: 16),
//                   itemBuilder: (context, index) {
//                     final category = categories[index];
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.pushNamed(
//                           context,
//                           documentRoute,
//                           arguments: {'categoryId': category.categoryId},
//                         );
//                       },
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.1),
//                                   blurRadius: 5,
//                                   offset: const Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                             child: const Icon(Icons.folder,
//                                 size: 40, color: Colors.blue),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             category.name,
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   /// Widget to display upcoming reminders (only those not completed and within 30 days).
//   Widget _buildUpcomingRemindersSection() {
//     return FutureBuilder<List<Reminder>>(
//       future:
//           ReminderService().fetchReminders(userId: AuthService().currentUserId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Padding(
//             padding: EdgeInsets.all(10.0),
//             child: Text(
//               "No reminders yet",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey),
//             ),
//           );
//         }
//         final now = DateTime.now();
//         final reminders = snapshot.data!
//             .where((reminder) =>
//                 !reminder.isCompleted &&
//                 reminder.reminderDateTime.difference(now).inDays <= 30)
//             .toList();
//         if (reminders.isEmpty) {
//           return const Padding(
//             padding: EdgeInsets.all(10.0),
//             child: Text(
//               "No upcoming reminders within 30 days",
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey),
//             ),
//           );
//         }
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Upcoming Reminders",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Column(
//               children: reminders.map((reminder) {
//                 return FutureBuilder<String>(
//                   future: DocumentService()
//                       .fetchDocumentName(reminder.documentId),
//                   builder: (context, documentSnapshot) {
//                     if (documentSnapshot.connectionState ==
//                         ConnectionState.waiting) {
//                       return const Center(
//                           child: CircularProgressIndicator());
//                     } else if (documentSnapshot.hasError) {
//                       return const ListTile(
//                         leading: Icon(Icons.insert_drive_file, color: Colors.red),
//                         title: Text("Error fetching document name"),
//                       );
//                     }
//                     final docTitle =
//                         documentSnapshot.data ?? "Unknown Document";
//                     final daysLeft =
//                         reminder.reminderDateTime.difference(now).inDays;
//                     final progress = daysLeft > 0
//                         ? (1 - (daysLeft / 30)).clamp(0.0, 1.0)
//                         : 1.0;
//                     return Card(
//                       margin: const EdgeInsets.only(bottom: 10),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 3,
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.all(12),
//                         leading: const Icon(Icons.insert_drive_file,
//                             color: Colors.blue, size: 40),
//                         title: Text(
//                           docTitle,
//                           style: const TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text("Reminder Date: ${DateFormat('yyyy-MM-dd HH:mm').format(reminder.reminderDateTime)}"),
//                             Text("$daysLeft days left",
//                                 style: const TextStyle(color: Colors.grey)),
//                             const SizedBox(height: 6),
//                             LinearProgressIndicator(value: progress),
//                           ],
//                         ),
//                         trailing: PopupMenuButton<String>(
//                           onSelected: (value) async {
//                             if (value == 'view') {
//                               Navigator.pushNamed(
//                                 context,
//                                 viewRoute,
//                                 arguments: {'documentId': reminder.documentId},
//                               );
//                             } else if (value == 'edit') {
//                               Navigator.pushNamed(
//                                 context,
//                                 updateRoute,
//                                 arguments: {'documentId': reminder.documentId},
//                               );
//                             } else if (value == 'delete') {
//                               // Delete the reminder.
//                               await FirebaseFirestore.instance
//                                   .collection('documents')
//                                   .doc(reminder.documentId)
//                                   .delete();
//                               final reminderQuerySnapshot = await FirebaseFirestore.instance
//                                   .collection('reminders')
//                                   .where('documentId', isEqualTo: reminder.documentId)
//                                   .get();
//                               for (var doc in reminderQuerySnapshot.docs) {
//                                 await doc.reference.delete();
//                               }
//                               // Refresh UI.
//                               setState(() {});
//                             }
//                           },
//                           itemBuilder: (context) => const [
//                             PopupMenuItem(value: 'view', child: Text("View")),
//                             PopupMenuItem(value: 'edit', child: Text("Edit")),
//                             PopupMenuItem(value: 'delete', child: Text("Delete")),
//                           ],
//                         ),
//                         onTap: () {
//                           Navigator.pushNamed(
//                             context,
//                             viewRoute,
//                             arguments: {'documentId': reminder.documentId},
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 );
//               }).toList(),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   /// Builds the AppBar for HomeScreen.
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       automaticallyImplyLeading: false,
//       title: Row(
//         children: [
//           // Profile picture section: If a profile picture is found in SharedPreferences (for current user), show it; otherwise, show default icon.
//           GestureDetector(
//             onTap: () {
//               // Optionally navigate to a profile screen.
//             },
//             child: CircleAvatar(
//               backgroundColor: Colors.grey.shade300,
//               backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
//               child: _profileImage == null ? Icon(Icons.person, color: Colors.white) : null,
//             ),
//           ),
//           const SizedBox(width: 10),
//           FutureBuilder<String>(
//             future: AuthService().getUserName(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Text("Loading...",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
//               } else if (snapshot.hasError) {
//                 return const Text("Error",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
//               }
//               return Text(snapshot.data ?? "User",
//                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   /// Widget to display search results.
//   // Widget buildSearchResults() {
//   //   return StreamBuilder<QuerySnapshot>(
//   //     stream: FirebaseFirestore.instance
//   //         .collection('documents')
//   //         .where('userId', isEqualTo: AuthService().currentUserId)
//   //         .where('title', isGreaterThanOrEqualTo: searchQuery)
//   //         .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff')
//   //         .snapshots(),
//   //     builder: (context, snapshot) {
//   //       if (snapshot.connectionState == ConnectionState.waiting) {
//   //         return const Center(child: CircularProgressIndicator());
//   //       }
//   //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//   //         return const Padding(
//   //           padding: EdgeInsets.all(8.0),
//   //           child: Text("No matching documents found."),
//   //         );
//   //       }
//   //       final docs = snapshot.data!.docs;
//   //       return Column(
//   //         crossAxisAlignment: CrossAxisAlignment.start,
//   //         children: [
//   //           const Text("Search Results",
//   //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//   //           const SizedBox(height: 10),
//   //           ListView.builder(
//   //             shrinkWrap: true,
//   //             physics: const NeverScrollableScrollPhysics(),
//   //             itemCount: docs.length,
//   //             itemBuilder: (context, index) {
//   //               final docData = docs[index].data() as Map<String, dynamic>;
//   //               return Card(
//   //                 margin: const EdgeInsets.symmetric(vertical: 6),
//   //                 child: ListTile(
//   //                   title: Text(docData['title'] ?? 'Untitled'),
//   //                   subtitle: Text(docData['description'] ?? ''),
//   //                   onTap: () {
//   //                     Navigator.pushNamed(
//   //                       context,
//   //                       viewRoute,
//   //                       arguments: {'documentId': docs[index].id},
//   //                     );
//   //                   },
//   //                 ),
//   //               );
//   //             },
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }

//  @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Search bar.
//               TextField(
//                 controller: searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search documents...',
//                   prefixIcon: const Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               if (activeSearchQuery.isNotEmpty)
//                 _buildSearchResults()
//               else ...[
//                 _buildCategoriesSection(),
//                 const SizedBox(height: 20),
//                 _buildUpcomingRemindersSection(),
//               ],
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

//   void _onBottomNavTap(int index) {
//     setState(() {
//       currentTabIndex = index;
//     });
//     switch (index) {
//       case 0:
//         Navigator.pushReplacementNamed(context, homeRoute);
//         break;
//       case 1:
//         Navigator.pushReplacementNamed(context, reminderRoute);
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
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:dockeeper/models/category_model.dart';
import 'package:dockeeper/models/reminder_model.dart';
import 'package:dockeeper/services/auth_service.dart';
import 'package:dockeeper/services/category_service.dart';
import 'package:dockeeper/services/document_service.dart';
import 'package:dockeeper/services/notification_service.dart';
import 'package:dockeeper/services/reminder_service.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  String activeSearchQuery = "";
  int currentTabIndex = 0;
  File? _profileImage;
  OverlayEntry? _overlayEntry;
  // GlobalKey to get the position/size of the search field.
  final GlobalKey _searchFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        activeSearchQuery = searchController.text.trim();
        print("Active search query: $activeSearchQuery");
      });
      // If there's a query, show the overlay; otherwise, remove it.
      if (activeSearchQuery.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay(); // Remove any existing overlay.
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    // Get the render box of the search field to determine its position.
    RenderBox renderBox = _searchFieldKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 4.0,
          // Wrap in ClipRRect to give soft rounded corners.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 250, // Adjust height as needed.
              color: Colors.white,
              child: _buildSearchResultsOverlay(),
            ),
          ),
        ),
      ),
    );
  }
  

  /// This widget builds the list of search results that appear in the overlay.
  Widget _buildSearchResultsOverlay() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('documents')
        .where('userId', isEqualTo: AuthService().currentUserId)
        .orderBy('title')
        .startAt([activeSearchQuery])
        .endAt([activeSearchQuery + '\uf8ff'])
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("No matching documents found."),
        );
      }
      final docs = snapshot.data!.docs;
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final docData = docs[index].data() as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: Text(docData['title'] ?? 'Untitled'),
              subtitle: Text(docData['description'] ?? ''),
              onTap: () {
                _removeOverlay();
                Navigator.pushNamed(
                  context,
                  viewRoute,
                  arguments: {'documentId': docs[index].id},
                );
              },
            ),
          );
        },
      );
    },
  );
}



  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  /// Loads the profile picture for the current user from SharedPreferences.
  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'profile_picture_${AuthService().currentUserId}';
    final profilePath = prefs.getString(key);
    if (profilePath != null && profilePath.isNotEmpty) {
      setState(() {
        _profileImage = File(profilePath);
      });
    }
  }

  /// Builds the AppBar with a profile picture (if available) and the user's name.
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
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null ? Icon(Icons.person, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 10),
          FutureBuilder<String>(
            future: AuthService().getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text(
                  "Loading...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              } else if (snapshot.hasError) {
                return const Text(
                  "Error",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              }
              return Text(
                snapshot.data ?? "User",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              );
            },
          ),
        ],
      ),
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
                    child: const Text(
                      "Show All",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
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

  /// Widget to display upcoming reminders (only those not completed and within 30 days).
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
        final reminders = snapshot.data!
            .where((reminder) =>
                !reminder.isCompleted &&
                reminder.reminderDateTime.difference(now).inDays <= 30)
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            Text("Reminder Date: ${DateFormat('yyyy-MM-dd HH:mm').format(reminder.reminderDateTime)}"),
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
                              Navigator.pushNamed(
                                context,
                                updateRoute,
                                arguments: {'documentId': reminder.documentId},
                              );
                            } else if (value == 'delete') {
                              // Delete the reminder.
                              await FirebaseFirestore.instance
                                  .collection('documents')
                                  .doc(reminder.documentId)
                                  .delete();
                              final reminderQuerySnapshot = await FirebaseFirestore.instance
                                  .collection('reminders')
                                  .where('documentId', isEqualTo: reminder.documentId)
                                  .get();
                              for (var doc in reminderQuerySnapshot.docs) {
                                await doc.reference.delete();
                              }
                              await NotificationService.cancelScheduledNotification(reminder.documentId);
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
              // Search bar with the GlobalKey.
              TextField(
                key: _searchFieldKey,
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
              // When no search query is active, show the normal home content.
              if (activeSearchQuery.isEmpty) ...[
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
        onTap: (index) {
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
              Navigator.pushNamedAndRemoveUntil(context, locationRoute, (route) => false);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, settingsRoute);
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}
