/// The Reminder model represents a scheduled reminder for a document.
class Reminder {
  final String reminderId;
  final String userId;
  final String documentId;
  final DateTime reminderDateTime; // Stores the full date and time.
  final bool isCompleted;

  Reminder({
    required this.reminderId,
    required this.userId,
    required this.documentId,
    required this.reminderDateTime,
    this.isCompleted = false,
  });

  /// Converts a Reminder instance to a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'reminderId': reminderId,
      'userId': userId,
      'documentId': documentId,
      'reminderDateTime': reminderDateTime.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  /// Creates a Reminder instance from a Map (e.g. data fetched from Firestore).
  static Reminder fromMap(Map<String, dynamic> map) {
    return Reminder(
      reminderId: map['reminderId'],
      userId: map['userId'],
      documentId: map['documentId'],
      reminderDateTime: DateTime.parse(map['reminderDateTime']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}