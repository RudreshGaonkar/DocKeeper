// document_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document_model.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new document
  Future<void> addDocument(Document document) async {
    try {
      await _firestore.collection('documents').add(document.toJson());
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  Future<void> uploadFile(String documentId, File file) async {
    try {
      // Reference to the file location in Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref('documents/$documentId/${file.path.split('/').last}');

      // Start uploading the file
      final uploadTask = storageRef.putFile(file);

      // Listen for progress updates
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload is $progress% complete.');
      });

      // Await upload completion
      final snapshot = await uploadTask;

      // Ensure the upload was successful
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('File uploaded successfully. Download URL: $downloadUrl');
      } else {
        throw Exception('File upload failed. Task state: ${snapshot.state}');
      }
    } catch (e) {
      // Handle errors
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }



  Future<void> addReminder({
    required String documentId,
    required String userId,
    required DateTime reminderDate,
    required String title,
  }) async {
    // Save reminder info to database
    // Example: FirebaseFirestore.instance.collection('reminders').add({
    //   'documentId': documentId,
    //   'userId': userId,
    //   'reminderDate': reminderDate,
    //   'title': title,
    // });
  }

  // Fetch all documents for a specific user
  Future<List<Document>> fetchDocuments(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Document.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  // Fetch document name by documentId
  Future<String> fetchDocumentName(String documentId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('documents') // Replace with your Firestore collection name
          .doc(documentId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()?['name'] ?? "Unknown Document";
      } else {
        return "Unknown Document";
      }
    } catch (e) {
      return "Error fetching document";
    }
  }

  // Update an existing document
  Future<void> updateDocument(String documentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('documents').doc(documentId).update(updates);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  // Delete a document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('documents').doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}