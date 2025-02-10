class Document {
  final String documentId;
  final String userId;
  final String title;
  final String description;
  final String categoryId;
  final String fileType;
  final String? filePath; // Made nullable, if needed
  final DateTime uploadDate;
  final DateTime expirationDate;
  final DateTime reminderDate;
  final String issueAuthority;

  Document({
    required this.documentId,
    required this.userId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.fileType,
    required this.filePath, // Nullable now
    required this.uploadDate,
    required this.expirationDate,
    required this.reminderDate,
    required this.issueAuthority,
  });

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'userId': userId,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'fileType': fileType,
        'filePath': filePath ?? '', // Save as empty string if null, or keep as null if your rules allow it
        'uploadDate': uploadDate.toIso8601String(),
        'expirationDate': expirationDate.toIso8601String(),
        'reminderDate': reminderDate.toIso8601String(),
        'issueAuthority': issueAuthority,
      };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        documentId: json['documentId'],
        userId: json['userId'],
        title: json['title'],
        description: json['description'],
        categoryId: json['categoryId'],
        fileType: json['fileType'],
        filePath: json['filePath'], // If null, you'll need to handle that downstream\n
        uploadDate: DateTime.parse(json['uploadDate']),
        expirationDate: DateTime.parse(json['expirationDate']),
        reminderDate: DateTime.parse(json['reminderDate']),
        issueAuthority: json['issueAuthority'] ?? '',
      );
}
