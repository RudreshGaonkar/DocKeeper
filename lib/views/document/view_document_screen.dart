import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document not found')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading document details: $e')),
      );
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
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : documentData == null
              ? const Center(child: Text('Document not found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title: ${documentData!['title'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.headlineSmall, //Error: The getter 'headline6' isn't defined for the type 'TextTheme'.Try importing the library that defines 'headline6', correcting the name to the name of an existing getter, or defining a getter or field named 'headline6'.
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Description: ${documentData!['description'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodyLarge,

                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category: ${documentData!['categoryName'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded on: ${_formatDate(documentData!['uploadedAt'])}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      if (documentData!['filePath'] != null)
                        Column(
                          children: [
                            const Text(
                              'Preview:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () =>
                                  _downloadAndOpenFile(documentData!['filePath']),
                              child: Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.picture_as_pdf, size: 48),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _downloadAndOpenFile(documentData!['filePath']),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open PDF'),
                            ),
                          ],
                        )
                      else
                        const Text('No file available for this document'),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Unknown';
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }
}
