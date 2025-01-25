//add_document_screen.dart

import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:dockeeper/models/document_model.dart';
import 'package:dockeeper/models/reminder_model.dart';
import 'package:dockeeper/services/auth_service.dart';
import 'package:dockeeper/services/category_service.dart';
import 'package:dockeeper/services/document_service.dart';
import 'package:dockeeper/services/reminder_service.dart';
import 'package:dockeeper/widgets/addScreen_textField.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
import 'package:dockeeper/widgets/custom_small_button.dart';
import 'package:dockeeper/widgets/custom_text_field.dart';
import 'package:dockeeper/widgets/loading_spinner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddDocumentScreen extends StatefulWidget {
  @override
  _AddDocumentScreenState createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController issueDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController reminderDateController = TextEditingController();

  final currentUserId = AuthService().currentUserId;

  String? selectedCategory;
  List<String> categories = [];
  List<File> uploadedImages = [];
  bool isLoading = false;

  int currentTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => isLoading = true);
      final fetchedCategories = await CategoryService().fetchAllCategories();
      setState(() => categories = fetchedCategories.map((cat) => cat.name).toList());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addDocument() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final issueDateText = issueDateController.text.trim();
    final expiryDateText = expiryDateController.text.trim();
    final reminderDateText = reminderDateController.text.trim();

    if (title.isEmpty || selectedCategory == null || issueDateText.isEmpty || expiryDateText.isEmpty || reminderDateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    try {
      final issueDate = DateFormat('yyyy-MM-dd').parse(issueDateText);
      final expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateText);
      final reminderDate = DateFormat('yyyy-MM-dd').parse(reminderDateText);

      // Validation checks
      if (expiryDate.isBefore(issueDate)) {
        throw Exception('Expiry date cannot be earlier than issue date.');
      }
      if (reminderDate.isBefore(issueDate) || reminderDate.isAfter(expiryDate)) {
        throw Exception('Reminder date must be between issue date and expiry date.');
      }

      // Save document details
      final documentId = DateTime.now().millisecondsSinceEpoch.toString();
      final newDocument = Document(
        documentId: documentId,
        userId: currentUserId,
        title: title,
        description: description.isNotEmpty ? description : 'No description provided',
        categoryId: selectedCategory!,
        fileType: uploadedImages.isEmpty ? 'No File' : 'Image',
        uploadDate: issueDate,
        expirationDate: expiryDate,
        reminderDate: reminderDate,
      );

      await DocumentService().addDocument(newDocument);

      // Save uploaded images
      for (final File image in uploadedImages) {
        await DocumentService().uploadFile(documentId, image);
      }

      // Create reminder
      final reminder = Reminder(
        reminderId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUserId,
        documentId: documentId,
        reminderDate: reminderDate,
        isCompleted: false,
      );

      await ReminderService().addReminder(reminder);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document and reminder added successfully.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }




  // Future<void> _addDocument() async {
  //   final title = titleController.text.trim();
  //   final description = descriptionController.text.trim();
  //   final issueDateText = issueDateController.text.trim();
  //   final expiryDateText = expiryDateController.text.trim();
  //   final reminderDateText = reminderDateController.text.trim();

  //   if (title.isEmpty || selectedCategory == null || issueDateText.isEmpty || expiryDateText.isEmpty || reminderDateText.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please fill in all required fields.')),
  //     );
  //     return;
  //   }

  //   try {
  //     // Parse dates
  //     final issueDate = DateFormat('yyyy-MM-dd').parse(issueDateText);
  //     final expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateText);
  //     final reminderDate = DateFormat('yyyy-MM-dd').parse(reminderDateText);

  //     // Generate a unique documentId (this can also be done in the backend)
  //     final documentId = DateTime.now().millisecondsSinceEpoch.toString();

  //     // Create a Document object
  //     final newDocument = Document(
  //       documentId: documentId,
  //       userId: currentUserId,
  //       title: title,
  //       description: description.isNotEmpty ? description : 'No description provided',
  //       categoryId: selectedCategory!,
  //       fileType: uploadedImages.isEmpty ? 'No File' : 'Image',
  //       uploadDate: issueDate,
  //       expirationDate: expiryDate,
  //       reminderDate: reminderDate,
  //     );

  //     // Call the service to add the document
  //     await DocumentService().addDocument(newDocument);

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Document added successfully.')),
  //     );
  //     Navigator.pop(context);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e')),
  //     );
  //   }
  // }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null) {
      setState(() {
        uploadedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  Future<void> _scanDocuments() async {
    try {
      final scannedPaths = await CunningDocumentScanner.getPictures();
      if (scannedPaths != null) {
        setState(() {
          uploadedImages.addAll(scannedPaths.map((path) => File(path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document scanning failed: $e')),
      );
    }
  }

  void _calculateReminderDate() {
    if (expiryDateController.text.isNotEmpty) {
      final expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateController.text);
      DateTime reminderDate;

      // Calculate reminder date based on expiry period
      if (expiryDate.difference(DateTime.now()).inDays >= 60) {
        reminderDate = expiryDate.subtract(Duration(days: 30)); // 30 days before
      } else if (expiryDate.difference(DateTime.now()).inDays >= 7) {
        reminderDate = expiryDate.subtract(Duration(days: 7)); // 7 days before
      } else {
        reminderDate = expiryDate.subtract(Duration(days: 3)); // 3 days before
      }

      setState(() {
        reminderDateController.text = DateFormat('yyyy-MM-dd').format(reminderDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Document'),
      ),
      body: isLoading
          ? LoadingSpinner()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomSmallButton(text: 'Upload Images', onPressed: _pickImages),
                        CustomSmallButton(text: 'Scan Documents', onPressed: _scanDocuments),
                      ],
                    ),
                    SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      children: uploadedImages.map((img) => Image.file(img, width: 100, height: 100)).toList(),
                    ),
                    SizedBox(height: 20),
                    CustomTextField(controller: titleController, labelText: 'Document Title', icon: Icons.title),
                    SizedBox(height: 20),
                    CustomTextField(controller: descriptionController, labelText: 'Description', icon: Icons.description),
                    SizedBox(height: 20),
                    DropdownButtonFormField(
                      value: selectedCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) => setState(() => selectedCategory = value),
                      decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 20),
                    AddDocumentTextField(
                      controller: issueDateController,
                      labelText: 'Issue Date',
                      icon: Icons.date_range,
                      readOnly: true,
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          issueDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    AddDocumentTextField(
                      controller: expiryDateController,
                      labelText: 'Expiry Date',
                      icon: Icons.date_range,
                      readOnly: true,
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          expiryDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                          _calculateReminderDate();
                        }
                      },
                    ),
                    SizedBox(height: 20),
                    AddDocumentTextField(
                      controller: reminderDateController,
                      labelText: 'Reminder Date',
                      icon: Icons.alarm,
                      readOnly: true,
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          reminderDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                        }
                      },
                    ),
                    SizedBox(height: 30),
                    CustomSmallButton(text: 'Add Document', onPressed: _addDocument),
                  ],
                ),
              ),
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
    }
  }
}
