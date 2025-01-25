class Document {
  final String documentId;
  final String userId;
  final String title;
  final String description;
  final String categoryId;
  final String fileType;
  final DateTime uploadDate;
  final DateTime expirationDate;
  final DateTime reminderDate;

  Document({
    required this.documentId,
    required this.userId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.fileType,
    required this.uploadDate,
    required this.expirationDate,
    required this.reminderDate,
  });

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'userId': userId,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'fileType': fileType,
        'uploadDate': uploadDate.toIso8601String(),
        'expirationDate': expirationDate.toIso8601String(),
        'reminderDate': reminderDate.toIso8601String(),
      };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        documentId: json['documentId'],
        userId: json['userId'],
        title: json['title'],
        description: json['description'],
        categoryId: json['categoryId'],
        fileType: json['fileType'],
        uploadDate: DateTime.parse(json['uploadDate']),
        expirationDate: DateTime.parse(json['expirationDate']),
        reminderDate: DateTime.parse(json['reminderDate']),
      );
}