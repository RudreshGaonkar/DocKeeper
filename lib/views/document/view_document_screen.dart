// import 'dart:io';
// import 'dart:typed_data';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:dockeeper/core/routes.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:open_file_plus/open_file_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';

// class ViewScreen extends StatefulWidget {
//   final String documentId;

//   const ViewScreen({Key? key, required this.documentId}) : super(key: key);

//   @override
//   _ViewScreenState createState() => _ViewScreenState();
// }

// class _ViewScreenState extends State<ViewScreen> {
//   Map<String, dynamic>? documentData;
//   bool isLoading = true;
//   bool _reminderCompleted = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchDocumentDetails();
//   }

//   Future<void> _fetchDocumentDetails() async {
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('documents')
//           .doc(widget.documentId)
//           .get();

//       if (doc.exists) {
//         final data = doc.data()!;
//         // Ensure 'documentId' exists in the data.
//         if (!data.containsKey('documentId')) {
//           data['documentId'] = widget.documentId;
//         }
//         setState(() {
//           documentData = data;
//           isLoading = false;
//         });
//         // If categoryName is missing, fetch it using categoryId.
//         if (documentData != null &&
//             !documentData!.containsKey('categoryName') &&
//             documentData!['categoryId'] != null) {
//           FirebaseFirestore.instance
//               .collection('categories')
//               .doc(documentData!['categoryId'])
//               .get()
//               .then((catDoc) {
//             if (catDoc.exists) {
//               setState(() {
//                 documentData!['categoryName'] = catDoc['name'];
//               });
//             }
//           });
//         }
//         // Fetch associated reminder status.
//         _fetchReminderStatus();
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('Document not found')));
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading document details: $e')));
//     }
//   }

//   /// Fetches the reminder document for this document and sets the completion status.
//   Future<void> _fetchReminderStatus() async {
//     try {
//       final reminderQuerySnapshot = await FirebaseFirestore.instance
//           .collection('reminders')
//           .where('documentId', isEqualTo: documentData!['documentId'])
//           .get();
//       if (reminderQuerySnapshot.docs.isNotEmpty) {
//         final reminderDoc = reminderQuerySnapshot.docs.first;
//         final status = reminderDoc.data()['isCompleted'] as bool? ?? false;
//         setState(() {
//           _reminderCompleted = status;
//         });
//       }
//     } catch (e) {
//       // If fetching the reminder fails, we simply do not update the status.
//       print("Error fetching reminder status: $e");
//     }
//   }

//   /// Helper function to extract a relative storage path from a full download URL.
//   String getStoragePath(String filePath) {
//     // If the filePath is a full URL, extract the path after '/o/' and before '?'
//     if (filePath.startsWith("https://firebasestorage.googleapis.com")) {
//       final uri = Uri.parse(filePath);
//       final pathSegments = uri.pathSegments;
//       // Firebase Storage URLs contain an 'o' segment followed by the encoded file path.
//       final oIndex = pathSegments.indexOf("o");
//       if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
//         return Uri.decodeComponent(pathSegments[oIndex + 1]);
//       }
//     }
//     return filePath;
//   }

//   /// Downloads the file from Firebase Storage to a persistent folder and opens it using the system default app.
//   /// A simple progress dialog is shown during download.
//   Future<void> _downloadAndOpenFile(String filePath) async {
//     try {
//       final relativePath = getStoragePath(filePath);
//       final ref = FirebaseStorage.instance.ref(relativePath);
//       // Get a persistent storage directory (using the app's documents directory).
//       final appDocDir = await getApplicationDocumentsDirectory();
//       final storageDir = Directory('${appDocDir.path}/DocKeeper');
//       if (!(await storageDir.exists())) {
//         await storageDir.create(recursive: true);
//       }
//       // Sanitize file name.
//       final sanitizedFileName =
//           ref.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
//       final localFile = File('${storageDir.path}/$sanitizedFileName');

//       double progress = 0.0;

//       // Show a progress dialog.
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) {
//           return StatefulBuilder(builder: (context, setStateDialog) {
//             final downloadTask = ref.writeToFile(localFile);
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
//       await ref.writeToFile(localFile);
//       // Dismiss the progress dialog.
//       Navigator.of(context).pop();

//       if (await localFile.exists()) {
//         await OpenFile.open(localFile.path);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('File could not be downloaded.')),
//         );
//       }
//     } catch (e) {
//       if (Navigator.canPop(context)) {
//         Navigator.of(context).pop();
//       }
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error opening file: $e')));
//     }
//   }

//   /// Navigates to the Update Document screen and refreshes details on return.
//   void updateDocument() {
//     if (documentData != null && documentData!['documentId'] != null) {
//       Navigator.pushNamed(
//         context,
//         updateRoute,
//         arguments: {'documentId': documentData!['documentId']},
//       ).then((_) {
//         // Refresh details after update.
//         _fetchDocumentDetails();
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Document data is missing.")));
//     }
//   }

//   /// Deletes the document from Firestore, its file from Firebase Storage, and any associated reminders.
//   Future<void> _deleteDocument(String documentId, String filePath) async {
//     try {
//       if (filePath.isNotEmpty) {
//         final relativePath = getStoragePath(filePath);
//         final ref = FirebaseStorage.instance.ref(relativePath);
//         try {
//           await ref.delete();
//           print("File deleted successfully from Storage.");
//         } catch (e) {
//           print("Error deleting file from Storage: $e");
//           // Optionally ignore if file doesn't exist.
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
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to delete document: $e')),
//       );
//     }
//   }

//   /// Toggles the completion status of the associated reminder.
//   Future<void> _toggleReminderCompletion() async {
//     try {
//       final reminderQuerySnapshot = await FirebaseFirestore.instance
//           .collection('reminders')
//           .where('documentId', isEqualTo: documentData!['documentId'])
//           .get();
//       if (reminderQuerySnapshot.docs.isNotEmpty) {
//         final reminderDoc = reminderQuerySnapshot.docs.first;
//         final currentStatus = reminderDoc.data()['isCompleted'] as bool? ?? false;
//         await reminderDoc.reference.update({'isCompleted': !currentStatus});
//         setState(() {
//           _reminderCompleted = !currentStatus;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Reminder marked as ${_reminderCompleted ? 'done' : 'not done'}')),
//         );
//       } else {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('No reminder found for this document.')));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to toggle reminder: $e')));
//     }
//   }

//   String _formatDate(String? date) {
//     if (date == null) return 'Unknown';
//     final parsedDate = DateTime.tryParse(date);
//     if (parsedDate == null) return 'Unknown';
//     return DateFormat('yyyy-MM-dd').format(parsedDate);
//   }

//   void _deleteDocumentPressed() async {
//     bool? confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Document'),
//         content: const Text('Are you sure you want to delete this document?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//     if (confirmed == true) {
//       _deleteDocument(documentData!['documentId'], documentData!['filePath']);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Document Details'),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : documentData == null
//               ? const Center(child: Text('Document not found'))
//               : SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Card(
//                       elevation: 6,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.stretch,
//                           children: [
//                             // Document details.
//                             Text(
//                               documentData!['title'] ?? 'N/A',
//                               style: Theme.of(context).textTheme.headlineSmall,
//                               textAlign: TextAlign.center,
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               documentData!['description'] ?? 'No description available',
//                               style: Theme.of(context).textTheme.bodyLarge,
//                               textAlign: TextAlign.center,
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Category: ${documentData!['categoryName'] ?? documentData!['categoryId'] ?? 'N/A'}',
//                               style: Theme.of(context).textTheme.bodyLarge,
//                               textAlign: TextAlign.center,
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Uploaded on: ${_formatDate(documentData!['uploadDate'])}',
//                               style: Theme.of(context).textTheme.bodyLarge,
//                               textAlign: TextAlign.center,
//                             ),
//                             const SizedBox(height: 16),
//                             // File preview and open button.
//                             if (documentData!['filePath'] != null &&
//                                 (documentData!['filePath'] as String).isNotEmpty)
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                                 children: [
//                                   const Text(
//                                     'Preview:',
//                                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: 8),
//                                   GestureDetector(
//                                     onTap: () => _downloadAndOpenFile(documentData!['filePath']),
//                                     child: Container(
//                                       height: 200,
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: const Center(
//                                         child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton.icon(
//                                     onPressed: () => _downloadAndOpenFile(documentData!['filePath']),
//                                     icon: const Icon(Icons.open_in_new),
//                                     label: const Text('Open PDF'),
//                                   ),
//                                 ],
//                               )
//                             else
//                               const Text(
//                                 'No file available for this document',
//                                 textAlign: TextAlign.center,
//                               ),
//                             const SizedBox(height: 16),
//                             // Action buttons.
//                             Wrap(
//                               alignment: WrapAlignment.center,
//                               spacing: 8,
//                               runSpacing: 8,
//                               children: [
//                                 ElevatedButton.icon(
//                                   onPressed: updateDocument,
//                                   icon: const Icon(Icons.edit),
//                                   label: const Text('Update'),
//                                 ),
//                                 ElevatedButton.icon(
//                                   onPressed: _deleteDocumentPressed,
//                                   icon: const Icon(Icons.delete),
//                                   label: const Text('Delete'),
//                                 ),
//                                 ElevatedButton.icon(
//                                   onPressed: _toggleReminderCompletion,
//                                   icon: const Icon(Icons.check_circle),
//                                   label: Text(_reminderCompleted ? 'Mark as Not Done' : 'Mark as Done'),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//     );
//   }
// }
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:dockeeper/services/notification_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';

class ViewScreen extends StatefulWidget {
  final String documentId;

  const ViewScreen({Key? key, required this.documentId}) : super(key: key);

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  Map<String, dynamic>? documentData;
  bool isLoading = true;
  bool _reminderCompleted = false;

  @override
  void initState() {
    super.initState();
    _fetchDocumentDetails();
  }

  Future<void> _fetchDocumentDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('documents')
          .doc(widget.documentId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        // Ensure 'documentId' exists in the data.
        if (!data.containsKey('documentId')) {
          data['documentId'] = widget.documentId;
        }
        setState(() {
          documentData = data;
          isLoading = false;
        });
        // If categoryName is missing, fetch it using categoryId.
        if (documentData != null &&
            !documentData!.containsKey('categoryName') &&
            documentData!['categoryId'] != null) {
          FirebaseFirestore.instance
              .collection('categories')
              .doc(documentData!['categoryId'])
              .get()
              .then((catDoc) {
            if (catDoc.exists) {
              setState(() {
                documentData!['categoryName'] = catDoc['name'];
              });
            }
          });
        }
        // Fetch associated reminder status.
        _fetchReminderStatus();
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Document not found')));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading document details: $e')));
    }
  }

  /// Fetches the reminder document for this document and sets the completion status.
  Future<void> _fetchReminderStatus() async {
    try {
      final reminderQuerySnapshot = await FirebaseFirestore.instance
          .collection('reminders')
          .where('documentId', isEqualTo: documentData!['documentId'])
          .get();
      if (reminderQuerySnapshot.docs.isNotEmpty) {
        final reminderDoc = reminderQuerySnapshot.docs.first;
        final status = reminderDoc.data()['isCompleted'] as bool? ?? false;
        setState(() {
          _reminderCompleted = status;
        });
      }
    } catch (e) {
      print("Error fetching reminder status: $e");
    }
  }

  /// Helper function to extract a relative storage path from a full download URL.
  String getStoragePath(String filePath) {
    if (filePath.startsWith("https://firebasestorage.googleapis.com")) {
      final uri = Uri.parse(filePath);
      final pathSegments = uri.pathSegments;
      final oIndex = pathSegments.indexOf("o");
      if (oIndex != -1 && oIndex + 1 < pathSegments.length) {
        return Uri.decodeComponent(pathSegments[oIndex + 1]);
      }
    }
    return filePath;
  }

  /// Downloads the file from Firebase Storage to a persistent folder and opens it using the default app.
  Future<void> _downloadAndOpenFile(String filePath) async {
    try {
      final relativePath = getStoragePath(filePath);
      final ref = FirebaseStorage.instance.ref(relativePath);
      final appDocDir = await getApplicationDocumentsDirectory();
      final storageDir = Directory('${appDocDir.path}/DocKeeper');
      if (!(await storageDir.exists())) {
        await storageDir.create(recursive: true);
      }
      final sanitizedFileName =
          ref.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final localFile = File('${storageDir.path}/$sanitizedFileName');

      double progress = 0.0;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            final downloadTask = ref.writeToFile(localFile);
            downloadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              if (snapshot.totalBytes > 0) {
                final double newProgress =
                    snapshot.bytesTransferred / snapshot.totalBytes;
                setStateDialog(() {
                  progress = newProgress;
                });
                print(
                    'Download progress: ${(progress * 100).toStringAsFixed(0)}%');
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
      await ref.writeToFile(localFile);
      Navigator.of(context).pop();

      if (await localFile.exists()) {
        await OpenFile.open(localFile.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File could not be downloaded.')),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error opening file: $e')));
    }
  }

  /// Navigates to the Update Document screen and refreshes details on return.
  void updateDocument() {
    if (documentData != null && documentData!['documentId'] != null) {
      Navigator.pushNamed(
        context,
        updateRoute,
        arguments: {'documentId': documentData!['documentId']},
      ).then((_) {
        _fetchDocumentDetails();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document data is missing.")));
    }
  }

  /// Deletes the document from Firestore, its file from Firebase Storage, and any associated reminders.
  Future<void> _deleteDocument(String documentId, String filePath) async {
    try {
      if (filePath.isNotEmpty) {
        final relativePath = getStoragePath(filePath);
        final ref = FirebaseStorage.instance.ref(relativePath);
        try {
          await ref.delete();
          print("File deleted successfully from Storage.");
        } catch (e) {
          print("Error deleting file from Storage: $e");
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
      await NotificationService.cancelScheduledNotification(documentId);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete document: $e')),
      );
    }
  }

  /// Toggles the completion status of the associated reminder.
  Future<void> _toggleReminderCompletion() async {
    try {
      final reminderQuerySnapshot = await FirebaseFirestore.instance
          .collection('reminders')
          .where('documentId', isEqualTo: documentData!['documentId'])
          .get();
      if (reminderQuerySnapshot.docs.isNotEmpty) {
        final reminderDoc = reminderQuerySnapshot.docs.first;
        final currentStatus = reminderDoc.data()['isCompleted'] as bool? ?? false;
        await reminderDoc.reference.update({'isCompleted': !currentStatus});
        setState(() {
          _reminderCompleted = !currentStatus;
        });
        if (!currentStatus) {
          await NotificationService.cancelScheduledNotification(reminderDoc.data()['documentId']);
        }
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
  }

  String _formatDate(String? date) {
    if (date == null) return 'Unknown';
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }

  void _deleteDocumentPressed() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteDocument(documentData!['documentId'], documentData!['filePath']);
    }
  }

  /// Bottom Navigation Bar tap handler.
  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, homeRoute);
        break;
      case 1:
        // Already on the current screen (view screen).
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : documentData == null
              ? const Center(child: Text('Document not found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Document details.
                            Text(
                              documentData!['title'] ?? 'N/A',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              documentData!['description'] ?? 'No description available',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Category: ${documentData!['categoryName'] ?? documentData!['categoryId'] ?? 'N/A'}',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Issue Authority: ${documentData!['issueAuthority'] ?? documentData!['issueAuthority'] ?? 'N/A'}',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Uploaded on: ${_formatDate(documentData!['uploadDate'])}',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // File preview and open button.
                            if (documentData!['filePath'] != null &&
                                (documentData!['filePath'] as String).isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Preview:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _downloadAndOpenFile(documentData!['filePath']),
                                    child: Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _downloadAndOpenFile(documentData!['filePath']),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Open PDF'),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'No file available for this document',
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 16),
                            // Action buttons.
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: updateDocument,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Update'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _deleteDocumentPressed,
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _toggleReminderCompletion,
                                  icon: const Icon(Icons.check_circle),
                                  label: Text(_reminderCompleted ? 'Mark as Not Done' : 'Mark as Done'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
