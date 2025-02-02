import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io'; // For File class
import 'package:path_provider/path_provider.dart'; // For getTemporaryDirectory

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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .where('categoryId', isEqualTo: widget.categoryId) // Match using categoryId
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
              final doc = documents[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(doc['title'] ?? 'Unnamed Document'),
                  subtitle: Text(doc['description'] ?? 'No description available'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _shareDocument(doc),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'delete') {
                            final documentId = doc['documentId'] as String; // Ensure this is the correct field for the Firestore document ID
                            final filePath = doc['filePath'] as String? ?? ''; // Ensure this is the field where the file path is stored
                            await _deleteDocument(documentId, filePath); // Call _deleteDocument here
                          }
                        },
                      ),

                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      viewRoute,
                      arguments: {'documentId': doc['index'].id}, // Error : The getter 'id' isn't defined for the type 'Map<String, dynamic>'.Try importing the library that defines 'id', correcting the name to the name of an existing getter, or defining a getter or field named 'id'.
                    );
                  },
                ),
              );

            },
          );
        },
      ),
    );
  }

  Future<void> _shareDocument(Map<String, dynamic> doc) async {
    try {
      final filePath = doc['filePath'] as String?; // Firebase Storage file path
      final title = doc['title'] ?? 'Untitled Document';

      if (filePath != null && filePath.isNotEmpty) {
        // Create a reference to the file in Firebase Storage
        final ref = FirebaseStorage.instance.ref(filePath);

        // Get the temporary directory
        final tempDir = await getTemporaryDirectory();
        final localFilePath = '${tempDir.path}/$title.pdf';

        // Download the file to the local file system
        final localFile = File(localFilePath);
        await ref.writeToFile(localFile);

        // Share the file
        if (await localFile.exists()) {
          final xFile = XFile(localFile.path, name: '$title.pdf');
          await Share.shareXFiles(
            [xFile],
            text: 'Check out this document: $title',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing document: $e')),
      );
    }
  }






  Future<void> _deleteDocument(String documentId, String filePath) async {
    try {
      // Delete the file from Firebase Storage
      if (filePath.isNotEmpty) {
        final ref = FirebaseStorage.instance.ref(filePath);
        await ref.delete();
      }

      // Delete the document from Firestore
      await FirebaseFirestore.instance.collection('documents').doc(documentId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted successfully.')),
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
