class DocumentLocation {
  final String documentId;
  final String locationId;

  DocumentLocation({
    required this.documentId,
    required this.locationId,
  });

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'locationId': locationId,
      };

  factory DocumentLocation.fromJson(Map<String, dynamic> json) => DocumentLocation(
        documentId: json['documentId'],
        locationId: json['locationId'],
      );
}
