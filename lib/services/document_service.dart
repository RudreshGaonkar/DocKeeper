import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document_model.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds a new document to Firestore using your provided documentId.
  Future<void> addDocument(Document document) async {
    try {
      // Use the documentId as the document key.
      await _firestore.collection('documents').doc(document.documentId).set(document.toJson());
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  /// Uploads a file to Firebase Storage under a folder structure based on documentId.
  /// It then updates the document in Firestore with the download URL.
  Future<String> uploadFile(String documentId, File file) async {
    try {
      // Create a reference with a path like 'documents/{documentId}/{filename}'
      final storageRef = FirebaseStorage.instance.ref('documents/$documentId/${file.path.split('/').last}');
      final uploadTask = storageRef.putFile(file);

      // Listen for progress updates.
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload is ${progress.toStringAsFixed(0)}% complete.');
      });

      // Wait for the upload to complete.
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get the download URL.
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('File uploaded successfully. Download URL: $downloadUrl');

        // Update the document in Firestore with the filePath (download URL).
        await _firestore.collection('documents').doc(documentId).update({
          'filePath': downloadUrl,
        });
        return downloadUrl;
      } else {
        throw Exception('File upload failed. Task state: ${snapshot.state}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Updates an existing document.
  Future<void> updateDocument(String documentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('documents').doc(documentId).update(updates);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  /// Deletes a document from Firestore.
  Future<void> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('documents').doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Fetches the document's title by documentId (used for display purposes).
  Future<String> fetchDocumentName(String documentId) async {
    try {
      final docSnapshot = await _firestore.collection('documents').doc(documentId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['title'] ?? "Unknown Document";
      } else {
        return "Unknown Document";
      }
    } catch (e) {
      return "Error fetching document";
    }
  }
}
