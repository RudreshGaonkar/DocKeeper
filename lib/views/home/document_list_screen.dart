// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dockeeper/core/routes.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:path_provider/path_provider.dart';

// class DocumentScreen extends StatefulWidget {
//   final String categoryId;

//   const DocumentScreen({Key? key, required this.categoryId}) : super(key: key);

//   @override
//   _DocumentScreenState createState() => _DocumentScreenState();
// }

// class _DocumentScreenState extends State<DocumentScreen> {
//   String? userId;
//   String? categoryName;

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserId();
//     _fetchCategoryName();
//   }

//   void _fetchUserId() {
//     userId = FirebaseAuth.instance.currentUser?.uid;
//   }

//   Future<void> _fetchCategoryName() async {
//     try {
//       final categoryDoc = await FirebaseFirestore.instance
//           .collection('categories')
//           .doc(widget.categoryId)
//           .get();

//       if (categoryDoc.exists) {
//         setState(() {
//           categoryName = categoryDoc['name'];
//         });
//       } else {
//         setState(() {
//           categoryName = 'Unknown Category';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         categoryName = 'Error fetching category';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Documents in ${categoryName ?? 'Loading...'}'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: FirebaseFirestore.instance
//               .collection('documents')
//               .where('categoryId', isEqualTo: widget.categoryId)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (snapshot.hasError) {
//               return const Center(child: Text('Error loading documents'));
//             }
//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Center(
//                   child: Text('No documents found for this category.'));
//             }

//             final documents = snapshot.data!.docs;

//             return ListView.builder(
//               itemCount: documents.length,
//               itemBuilder: (context, index) {
//                 final documentSnapshot = documents[index];
//                 final docData =
//                     documentSnapshot.data() as Map<String, dynamic>;

//                 return Card(
//                   elevation: 4,
//                   margin:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     contentPadding: const EdgeInsets.all(12),
//                     title: Text(
//                       docData['title'] ?? 'Unnamed Document',
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                     subtitle: Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Text(
//                           docData['description'] ?? 'No description available'),
//                     ),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.share, color: Colors.blue),
//                           onPressed: () => _shareDocument(documentSnapshot),
//                         ),
//                         PopupMenuButton(
//                           onSelected: (value) async {
//                             if (value == 'delete') {
//                               final documentId = documentSnapshot.id;
//                               final filePath =
//                                   docData['filePath'] as String? ?? '';
//                               await _deleteDocument(documentId, filePath);
//                             }
//                           },
//                           itemBuilder: (context) => const [
//                             PopupMenuItem(
//                               value: 'delete',
//                               child: Text('Delete'),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     onTap: () {
//                       Navigator.pushNamed(
//                         context,
//                         viewRoute,
//                         arguments: {'documentId': documentSnapshot.id},
//                       );
//                     },
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }

//   /// Downloads the file from Firebase Storage into a persistent folder ("DocKeeper"),
//   /// shows a progress dialog with download progress, and then shares the file using share_plus.
//   Future<void> _shareDocument(QueryDocumentSnapshot documentSnapshot) async {
//     try {
//       final docData = documentSnapshot.data() as Map<String, dynamic>;
//       final filePath = docData['filePath'] as String?;
//       print("File path from Firestore: $filePath");
//       final title = docData['title'] ?? 'Untitled Document';

//       if (filePath == null || filePath.isEmpty) {
//         print("No file path provided in document.");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No file available to share.')),
//         );
//         return;
//       }

//       // Use refFromURL because filePath is a full download URL.
//       final ref = FirebaseStorage.instance.refFromURL(filePath);
//       print("Firebase Storage reference: $ref");

//       // Get the application's documents directory and create a persistent "DocKeeper" folder.
//       final appDocDir = await getApplicationDocumentsDirectory();
//       final storageDir = Directory('${appDocDir.path}/DocKeeper');
//       print("Storage directory: $storageDir");
//       if (!(await storageDir.exists())) {
//         await storageDir.create(recursive: true);
//         print("Created storage directory.");
//       }

//       // Sanitize the file name.
//       final sanitizedTitle =
//           title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
//       final localFile = File('${storageDir.path}/$sanitizedTitle.pdf');
//       print("Local file path: ${localFile.path}");

//       double progress = 0.0;
//       // Create the download task.
//       final downloadTask = ref.writeToFile(localFile);

//       // Show a progress dialog.
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return StatefulBuilder(builder: (context, setStateDialog) {
//             downloadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
//               if (snapshot.totalBytes > 0) {
//                 final double newProgress =
//                     snapshot.bytesTransferred / snapshot.totalBytes;
//                 setStateDialog(() {
//                   progress = newProgress;
//                 });
//                 print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
//               }
//             });
//             return AlertDialog(
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text("Downloading... ${(progress * 100).toStringAsFixed(0)}%"),
//                   const SizedBox(height: 16),
//                   LinearProgressIndicator(value: progress),
//                 ],
//               ),
//             );
//           });
//         },
//       );

//       // Wait for the download to complete.
//       await downloadTask;
//       // Dismiss the progress dialog.
//       Navigator.of(context).pop();

//       if (await localFile.exists()) {
//         print("File downloaded successfully.");
//         final xFile = XFile(localFile.path, name: '$sanitizedTitle.pdf');
//         await Share.shareXFiles([xFile], text: 'Document: $title');
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('File could not be downloaded.')),
//         );
//       }
//     } catch (e) {
//       try {
//         Navigator.of(context).pop();
//       } catch (_) {}
//       print("Error sharing document: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error sharing document: $e')),
//       );
//     }
//   }

//   /// Deletes the document from Firestore, its file from Firebase Storage,
//   /// and any associated reminders.
//   Future<void> _deleteDocument(String documentId, String filePath) async {
//     try {
//       if (filePath.isNotEmpty) {
//         // Use refFromURL because the stored filePath is a full download URL.
//         final ref = FirebaseStorage.instance.refFromURL(filePath);
//         try {
//           await ref.getMetadata(); // Check if the file exists.
//           await ref.delete();
//           print("File deleted successfully.");
//         } catch (e) {
//           print("Error or file not found in storage: $e");
//         }
//       }
//       await FirebaseFirestore.instance.collection('documents').doc(documentId).delete();
//       final reminderQuerySnapshot = await FirebaseFirestore.instance
//           .collection('reminders')
//           .where('documentId', isEqualTo: documentId)
//           .get();
//       for (var doc in reminderQuerySnapshot.docs) {
//         await doc.reference.delete();
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Document and associated reminders deleted successfully.')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to delete document: $e')),
//       );
//     }
//   }

//   String _formatDate(String? date) {
//     if (date == null) return 'Unknown';
//     final parsedDate = DateTime.tryParse(date);
//     if (parsedDate == null) return 'Unknown';
//     return DateFormat('yyyy-MM-dd').format(parsedDate);
//   }
// }
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class DocumentScreen extends StatefulWidget {
  final String categoryId;

  const DocumentScreen({Key? key, required this.categoryId}) : super(key: key);

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  String? userId;
  String? categoryName;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _fetchCategoryName();
  }

  void _fetchUserId() {
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _fetchCategoryName() async {
    try {
      final categoryDoc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .get();

      if (categoryDoc.exists) {
        setState(() {
          categoryName = categoryDoc['name'];
        });
      } else {
        setState(() {
          categoryName = 'Unknown Category';
        });
      }
    } catch (e) {
      setState(() {
        categoryName = 'Error fetching category';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents in ${categoryName ?? 'Loading...'}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('documents')
              // Only retrieve documents that belong to the specified category...
              .where('categoryId', isEqualTo: widget.categoryId)
              // ...and that belong to the currently logged-in user.
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading documents'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No documents found for this category.'));
            }

            final documents = snapshot.data!.docs;

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final documentSnapshot = documents[index];
                final docData =
                    documentSnapshot.data() as Map<String, dynamic>;

                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      docData['title'] ?? 'Unnamed Document',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          docData['description'] ?? 'No description available'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.blue),
                          onPressed: () => _shareDocument(documentSnapshot),
                        ),
                        PopupMenuButton(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final documentId = documentSnapshot.id;
                              final filePath =
                                  docData['filePath'] as String? ?? '';
                              await _deleteDocument(documentId, filePath);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        viewRoute,
                        arguments: {'documentId': documentSnapshot.id},
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Downloads the file from Firebase Storage into a persistent folder ("DocKeeper"),
  /// shows a progress dialog with download progress, and then shares the file using share_plus.
  Future<void> _shareDocument(QueryDocumentSnapshot documentSnapshot) async {
    try {
      final docData = documentSnapshot.data() as Map<String, dynamic>;
      final filePath = docData['filePath'] as String?;
      print("File path from Firestore: $filePath");
      final title = docData['title'] ?? 'Untitled Document';

      if (filePath == null || filePath.isEmpty) {
        print("No file path provided in document.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file available to share.')),
        );
        return;
      }

      // Use refFromURL because filePath is a full download URL.
      final ref = FirebaseStorage.instance.refFromURL(filePath);
      print("Firebase Storage reference: $ref");

      // Get the application's documents directory and create a persistent "DocKeeper" folder.
      final appDocDir = await getApplicationDocumentsDirectory();
      final storageDir = Directory('${appDocDir.path}/DocKeeper');
      print("Storage directory: $storageDir");
      if (!(await storageDir.exists())) {
        await storageDir.create(recursive: true);
        print("Created storage directory.");
      }

      // Sanitize the file name.
      final sanitizedTitle =
          title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final localFile = File('${storageDir.path}/$sanitizedTitle.pdf');
      print("Local file path: ${localFile.path}");

      double progress = 0.0;
      // Create the download task.
      final downloadTask = ref.writeToFile(localFile);

      // Show a progress dialog.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            downloadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              if (snapshot.totalBytes > 0) {
                final double newProgress =
                    snapshot.bytesTransferred / snapshot.totalBytes;
                setStateDialog(() {
                  progress = newProgress;
                });
                print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
              }
            });
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Downloading... ${(progress * 100).toStringAsFixed(0)}%"),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            );
          });
        },
      );

      // Wait for the download to complete.
      await downloadTask;
      // Dismiss the progress dialog.
      Navigator.of(context).pop();

      if (await localFile.exists()) {
        print("File downloaded successfully.");
        final xFile = XFile(localFile.path, name: '$sanitizedTitle.pdf');
        await Share.shareXFiles([xFile], text: 'Document: $title');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File could not be downloaded.')),
        );
      }
    } catch (e) {
      try {
        Navigator.of(context).pop();
      } catch (_) {}
      print("Error sharing document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing document: $e')),
      );
    }
  }

  /// Deletes the document from Firestore, its file from Firebase Storage,
  /// and any associated reminders.
  Future<void> _deleteDocument(String documentId, String filePath) async {
    try {
      if (filePath.isNotEmpty) {
        // Use refFromURL because the stored filePath is a full download URL.
        final ref = FirebaseStorage.instance.refFromURL(filePath);
        try {
          await ref.getMetadata(); // Check if the file exists.
          await ref.delete();
          print("File deleted successfully.");
        } catch (e) {
          print("Error or file not found in storage: $e");
        }
      }
      await FirebaseFirestore.instance.collection('documents').doc(documentId).delete();
      final reminderQuerySnapshot = await FirebaseFirestore.instance
          .collection('reminders')
          .where('documentId', isEqualTo: documentId)
          .get();
      for (var doc in reminderQuerySnapshot.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document and associated reminders deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete document: $e')),
      );
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'Unknown';
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }
}
