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
              .where('categoryId', isEqualTo: widget.categoryId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading documents'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No documents found for this category.'));
            }

            final documents = snapshot.data!.docs;

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final documentSnapshot = documents[index];
                final docData = documentSnapshot.data() as Map<String, dynamic>;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      docData['title'] ?? 'Unnamed Document',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(docData['description'] ?? 'No description available'),
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
                              final filePath = docData['filePath'] as String? ?? '';
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

  Future<void> _shareDocument(QueryDocumentSnapshot documentSnapshot) async {
    try {
      final docData = documentSnapshot.data() as Map<String, dynamic>;
      final filePath = docData['filePath'] as String?;
      final title = docData['title'] ?? 'Untitled Document';

      if (filePath != null && filePath.isNotEmpty) {
        // Create a reference to the file in Firebase Storage.
        final ref = FirebaseStorage.instance.ref(filePath);
        print('Downloading file from: $filePath');

        // Get the temporary directory.
        final tempDir = await getTemporaryDirectory();
        final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final localFilePath = '${tempDir.path}/$sanitizedTitle.pdf';
        final localFile = File(localFilePath);

        try {
          // Download the file.
          await ref.writeToFile(localFile);
          print('File downloaded to: $localFilePath');
        } catch (e) {
          print("Error downloading file: $e");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error downloading file: $e')));
          return;
        }

        if (await localFile.exists()) {
          final xFile = XFile(localFile.path, name: '$sanitizedTitle.pdf');
          await Share.shareXFiles(
            [xFile],
            text: 'Document: $title',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File could not be downloaded.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file available to share.')),
        );
      }
    } catch (e) {
      print('Error sharing document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing document: $e')),
      );
    }
  }

  Future<void> _deleteDocument(String documentId, String filePath) async {
    try {
      // Delete the file from Firebase Storage if a file path exists.
      if (filePath.isNotEmpty) {
        final ref = FirebaseStorage.instance.ref(filePath);
        try {
          await ref.getMetadata(); // Check if the file exists.
          await ref.delete();
          print("File deleted successfully.");
        } catch (e) {
          print("Error or file not found in storage: $e");
          // You may choose to ignore if the file does not exist.
        }
      }
      // Delete the document from Firestore.
      await FirebaseFirestore.instance.collection('documents').doc(documentId).delete();
      
      // Delete associated reminders from Firestore.
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
