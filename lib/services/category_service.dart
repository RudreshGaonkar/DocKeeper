import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import 'auth_service.dart'; 

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch public categories
  Future<List<Category>> fetchPublicCategories() async {
    try {
      final querySnapshot = await _firestore.collection('public_categories').get();
      return querySnapshot.docs
          .map((doc) => Category.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch public categories: $e');
    }
  }

  // Fetch user-specific categories
  Future<List<Category>> fetchUserCategories() async {
    try {
      final userId = AuthService().currentUserId; 
      if (userId == null) {
        throw Exception('User is not logged in');
      }

      final querySnapshot = await _firestore
          .collection('user_categories')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => Category.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user categories: $e');
    }
  }

  // Combine public and user-specific categories
  Future<List<Category>> fetchAllCategories() async {
    try {
      final publicCategories = await fetchPublicCategories();
      final userCategories = await fetchUserCategories();
      return [...publicCategories, ...userCategories];
    } catch (e) {
      throw Exception('Failed to fetch all categories: $e');
    }
  }

  // Add a new category (user-specific)
  Future<void> addCategory(Category category) async {
    try {
      final userId = AuthService().currentUserId;
      if (userId == null) {
        throw Exception('User is not logged in');
      }

      // Check if category name is unique (both public and user-specific)
      final publicCategoriesQuery = await _firestore
          .collection('public_categories')
          .where('name', isEqualTo: category.name)
          .get();

      final userCategoriesQuery = await _firestore
          .collection('user_categories')
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: category.name)
          .get();

      if (publicCategoriesQuery.docs.isNotEmpty || userCategoriesQuery.docs.isNotEmpty) {
        throw Exception('Category name already exists.');
      }

      // Add the category with userId
      final categoryWithUserId = category.toJson()..['userId'] = userId;
      await _firestore.collection('user_categories').add(categoryWithUserId);
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // Add default public categories (only needed once or managed elsewhere)
  Future<void> addDefaultCategories() async {
    try {
      final defaultCategories = [
        Category(categoryId: '1', name: 'Personal Document', description: 'Personal-related files'),
        Category(categoryId: '2', name: 'Vehicle Document', description: 'Vehicle-related files'),
        Category(categoryId: '3', name: 'Travel Document', description: 'Travel-related files'),
      ];
      final batch = _firestore.batch();

      for (final category in defaultCategories) {
        // Ensure category names are unique before adding
        final existingCategory = await _firestore
            .collection('public_categories')
            .where('name', isEqualTo: category.name)
            .get();

        if (existingCategory.docs.isEmpty) {
          final docRef = _firestore.collection('public_categories').doc(category.categoryId);
          batch.set(docRef, category.toJson());
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add default categories: $e');
    }
  }
}
