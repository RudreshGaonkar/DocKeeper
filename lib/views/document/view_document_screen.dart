import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';

class ViewScreen extends StatefulWidget {
  final String documentId;

  const ViewScreen({Key? key, required this.documentId}) : super(key: key);

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  Map<String, dynamic>? documentData;
  bool isLoading = true;

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
        setState(() {
          documentData = doc.data();
          isLoading = false;
        });
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

  Future<void> _downloadAndOpenFile(String filePath) async {
    try {
      final ref = FirebaseStorage.instance.ref(filePath);
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/${ref.name}');
      await ref.writeToFile(localFile);
      await OpenFile.open(localFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')));
    }
  }

  /// Update functionality: Navigate to the Update Document Screen.
  void updateDocument() {
    if (documentData != null && documentData!['documentId'] != null) {
      Navigator.pushNamed(
        context,
        updateRoute,
        arguments: {'documentId': documentData!['documentId']},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Document data is missing.")),
      );
    }
  }

  // Delete the document, its file from Storage, and associated reminders.
  Future<void> _deleteDocument(String documentId, String filePath) async {
    try {
      // Delete the file from Firebase Storage if a file path exists.
      if (filePath.isNotEmpty) {
        final ref = FirebaseStorage.instance.ref(filePath);
        try {
          await ref.delete();
          print("File deleted successfully from Storage.");
        } catch (e) {
          print("Error deleting file from Storage: $e");
          // Optionally, ignore if file doesn't exist.
        }
      }
      // Delete the document from Firestore.
      await FirebaseFirestore.instance.collection('documents').doc(documentId).delete();
      // Delete any associated reminders.
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
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete document: $e')));
    }
  }

  // Mark the document as done (complete).
  Future<void> _markAsDone() async {
    try {
      await FirebaseFirestore.instance
          .collection('documents')
          .doc(documentData!['documentId'])
          .update({'isCompleted': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document marked as done.')),
      );
      setState(() {
        documentData!['isCompleted'] = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark document as done: $e')));
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
                              'Uploaded on: ${_formatDate(documentData!['uploadDate'])}',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // File preview.
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
                                  onPressed: _markAsDone,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Mark as Done'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
