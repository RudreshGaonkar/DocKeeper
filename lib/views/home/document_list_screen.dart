// document_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class DocumentScreen extends StatefulWidget {
  final String categoryId;

  DocumentScreen({required this.categoryId});

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  String? userId;
  String? categoryName;

  @override
  void initState() {
    super.initState();
    print('DocumentScreen loaded for categoryId: ${widget.categoryId}');
    _fetchUserId();
    _fetchCategoryName();
  }

  void _fetchUserId() {
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _fetchCategoryName() async {
    final categoryDoc = await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .get();

    if (categoryDoc.exists) {
      setState(() {
        categoryName = categoryDoc['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName ?? 'Documents'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              _shareCategory();
            },
            tooltip: 'Share Category',
          ),
        ],
      ),
      body: userId == null
          ? Center(child: Text('Please log in to view your documents.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('documents')
                  .where('userId', isEqualTo: userId) // Filter by userId
                  .where('categoryId', isEqualTo: widget.categoryId) // Filter by categoryId
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No documents found.'));
                }

                final documents = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          doc['fileType'] == 'Image' ? Icons.image : Icons.file_present,
                          color: Colors.blue,
                        ),
                        title: Text(doc['title'] ?? 'Untitled'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doc['description'] != null)
                              Text(doc['description'], style: TextStyle(fontSize: 12)),
                            SizedBox(height: 4),
                            Text(
                              'Issue Date: ${_formatDate(doc['uploadDate'])}',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Expiry Date: ${_formatDate(doc['expirationDate'])}',
                              style: TextStyle(fontSize: 12),
                            ),
                            if (DateTime.parse(doc['expirationDate']).isBefore(DateTime.now()))
                              Text(
                                'Expired',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'Edit') {
                              _editDocument(doc);
                            } else if (value == 'Delete') {
                              _deleteDocument(doc['documentId']);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'Edit', child: Text('Edit')),
                            PopupMenuItem(value: 'Delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add');
        },
        child: Icon(Icons.add),
        tooltip: 'Add Document',
      ),
    );
  }

  void _shareCategory() {
    Share.share('Check out the ${categoryName ?? "category"} documents on DocKeeper!');
  }

  String _formatDate(String? date) {
    if (date == null) return 'Unknown';
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }

  void _editDocument(Map<String, dynamic> doc) {
    Navigator.pushNamed(context, '/editDocument', arguments: doc);
  }

  Future<void> _deleteDocument(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('documents').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Document deleted successfully.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete document: $e')));
    }
  }
}
