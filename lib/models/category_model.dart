class Category {
  final String categoryId;
  final String name;
  final String description;

  Category({
    required this.categoryId,
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'name': name,
        'description': description,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId: json['categoryId'],
        name: json['name'],
        description: json['description'],
      );
}

// Document_service.dart

