import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document_model.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new document with a provided documentId.
  Future<void> addDocument(Document document) async {
    try {
      // Create the document using the provided documentId.
      await _firestore.collection('documents').doc(document.documentId).set(document.toJson());
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  /// Uploads a file to Firebase Storage using the given documentId and file,
  /// then updates the Firestore document's filePath field with the download URL.
  ///
  /// Returns the download URL as a String.
  Future<String> uploadFile(String documentId, File file) async {
    try {
      // Create a reference to the file location in Firebase Storage.
      final storageRef = FirebaseStorage.instance
          .ref('documents/$documentId/${file.path.split('/').last}');
      
      // Start uploading the file.
      final uploadTask = storageRef.putFile(file);

      // Listen for progress updates.
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload is $progress% complete.');
      });

      // Await upload completion.
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get the download URL.
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('File uploaded successfully. Download URL: $downloadUrl');

        // Update the Firestore document with the download URL.
        // Option 1: Using update()
        // await _firestore.collection('documents').doc(documentId).update({
        //   'filePath': downloadUrl,
        // });
        
        // Option 2: If you're not 100% sure the document exists, you can merge:
        await _firestore.collection('documents').doc(documentId).set({
          'filePath': downloadUrl,
        }, SetOptions(merge: true));

        return downloadUrl;
      } else {
        throw Exception('File upload failed. Task state: ${snapshot.state}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // Fetch all documents for a specific user.
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

  // Fetch document name by documentId.
  Future<String> fetchDocumentName(String documentId) async {
    try {
      final docSnapshot = await _firestore
          .collection('documents')
          .doc(documentId)
          .get();

      if (docSnapshot.exists) {
        // Ensure that the field used here matches your model (e.g., 'title' or 'name').
        return docSnapshot.data()?['title'] ?? "Unknown Document";
      } else {
        return "Unknown Document";
      }
    } catch (e) {
      return "Error fetching document";
    }
  }

  // Update an existing document.
  Future<void> updateDocument(String documentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('documents').doc(documentId).update(updates);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  // Delete a document.
  Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('documents').doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}
