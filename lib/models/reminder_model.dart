// reminder_model.dart
class Reminder {
  final String reminderId;
  final String userId;
  final String documentId;
  final DateTime reminderDate;
  final bool isCompleted;

  Reminder({
    required this.reminderId,
    required this.userId,
    required this.documentId,
    required this.reminderDate,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'reminderId': reminderId,
        'userId': userId,
        'documentId': documentId,
        'reminderDate': reminderDate.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        reminderId: json['reminderId'],
        userId: json['userId'],
        documentId: json['documentId'],
        reminderDate: DateTime.parse(json['reminderDate']),
        isCompleted: json['isCompleted'],
      );
}