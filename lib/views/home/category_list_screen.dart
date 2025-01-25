// category_list_screen.dart
import 'package:dockeeper/core/routes.dart';
// import 'package:dockeeper/views/home/document_list_screen.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:dockeeper/models/category_model.dart';
import 'package:dockeeper/services/category_service.dart';
// import 'package:dockeeper/widgets/custom_small_button.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> categories = [];
  bool isLoading = false;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    try {
      setState(() => isLoading = true);
      await CategoryService().addDefaultCategories();
      final fetchedCategories = await CategoryService().fetchAllCategories();
      setState(() => categories = fetchedCategories);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToDocuments(Category category) {
    print(category.categoryId);
      Navigator.pushNamed(
        context,
        documentRoute, // The route name defined in my MaterialApp or onGenerateRoute
        arguments: {'categoryId': category.categoryId}, // Passing categoryId as argument
    );

  }

  Future<void> _addCategory() async {
    TextEditingController categoryNameController = TextEditingController();
    TextEditingController categoryDescriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryNameController,
              decoration: InputDecoration(labelText: 'Category Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: categoryDescriptionController,
              decoration: InputDecoration(labelText: 'Category Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = categoryNameController.text.trim();
              final description = categoryDescriptionController.text.trim();
              if (name.isNotEmpty) {
                final newCategory = Category(
                  categoryId: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: description.isNotEmpty ? description : 'No description provided',
                );
                try {
                  await CategoryService().addCategory(newCategory);
                  setState(() => categories.add(newCategory));
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add category: $e')),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Categories')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () => _navigateToDocuments(category),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder, size: 40, color: Colors.blue),
                            SizedBox(height: 10),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: CustomBottomNavBar(
      currentIndex: currentTabIndex,
      onTap: _onBottomNavTap,
    ),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      currentTabIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, homeRoute);
        break;
      case 1:
        // Navigator.pushReplacementNamed(context, reminderRoute);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
        break;
      case 3:
        // Navigator.pushReplacementNamed(context, locationRoute);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, settingsRoute);
        break;
      default:
        break;
    }
  }
}
