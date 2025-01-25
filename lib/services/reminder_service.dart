// reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new reminder
  Future<void> addReminder(Reminder reminder) async {
    try {
      await _firestore.collection('reminders').add(reminder.toJson());
    } catch (e) {
      throw Exception('Failed to add reminder: $e');
    }
  }

  // Fetch all reminders for a specific user
  Future<List<Reminder>> fetchReminders({required String userId}) async {
    try {
      final querySnapshot = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Reminder.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reminders: $e');
    }
  }

  // Update an existing reminder
  Future<void> updateReminder(String reminderId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).update(updates);
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }
}