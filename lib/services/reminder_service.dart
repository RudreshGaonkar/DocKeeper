import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/models/reminder_model.dart';

/// Service to manage reminder CRUD operations.
class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new reminder to Firestore.
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _firestore.collection('reminders').add(reminder.toMap());
    } catch (e) {
      throw Exception('Failed to add reminder: $e');
    }
  }

  /// Fetch all reminders for a specific user.
  Future<List<Reminder>> fetchReminders({required String userId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Reminder.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  /// Returns a stream of reminders for the given user.
  Stream<List<Reminder>> fetchRemindersStream({required String userId}) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList());
  }

  /// Update an existing reminder in Firestore.
  Future<void> updateReminder(String reminderId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).update(updates);
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  /// Delete a reminder from Firestore.
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }
}