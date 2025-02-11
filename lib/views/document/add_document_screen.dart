import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:dockeeper/models/document_model.dart';
import 'package:dockeeper/models/reminder_model.dart';
import 'package:dockeeper/services/auth_service.dart';
import 'package:dockeeper/services/category_service.dart';
import 'package:dockeeper/services/document_service.dart';
import 'package:dockeeper/services/reminder_service.dart';
import 'package:dockeeper/services/notification_service.dart';
import 'package:dockeeper/widgets/addScreen_textField.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
import 'package:dockeeper/widgets/custom_small_button.dart';
import 'package:dockeeper/widgets/custom_text_field.dart';
import 'package:dockeeper/widgets/loading_spinner.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

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
  // New controller for Issue Authority (address).
  final TextEditingController issueAuthorityController = TextEditingController();

  final String currentUserId = AuthService().currentUserId;

  // Variables for category dropdown.
  String? selectedCategory; // Displayed category name.
  List<String> categories = [];
  Map<String, String> categoryMap = {}; // Maps category name -> categoryId.
  String? selectedCategoryId; // Actual categoryId.

  List<File> uploadedImages = [];
  bool isLoading = false;
  int currentTabIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    issueDateController.dispose();
    expiryDateController.dispose();
    reminderDateController.dispose();
    issueAuthorityController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => isLoading = true);
      final fetchedCategories = await CategoryService().fetchAllCategories();
      setState(() {
        categoryMap = {for (var cat in fetchedCategories) cat.name: cat.categoryId};
        categories = categoryMap.keys.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<File> _generatePdf(List<File> images) async {
    final pdf = pw.Document();
    for (var image in images) {
      final imageBytes = await image.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(pw.Page(
          build: (context) => pw.Center(child: pw.Image(pdfImage))));
    }
    final outputDir = await getApplicationDocumentsDirectory();
    final pdfFile = File('${outputDir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await pdfFile.writeAsBytes(await pdf.save());
    return pdfFile;
  }

  /// Lets the user pick both a date and a time for the reminder.
  Future<void> _pickReminderDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0),
    );
    if (pickedTime == null) return;
    final DateTime combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      reminderDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(combined);
    });
  }

  void _calculateReminderDate() {
    if (expiryDateController.text.isNotEmpty) {
      final DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateController.text);
      DateTime reminderDate;
      if (expiryDate.difference(DateTime.now()).inDays >= 60) {
        reminderDate = expiryDate.subtract(Duration(days: 30));
      } else if (expiryDate.difference(DateTime.now()).inDays >= 7) {
        reminderDate = expiryDate.subtract(Duration(days: 7));
      } else {
        reminderDate = expiryDate.subtract(Duration(days: 3));
      }
      // Set default time to 8 AM.
      reminderDate = reminderDate.add(Duration(hours: 8));
      setState(() {
        reminderDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(reminderDate);
      });
    }
  }

  Future<void> _addDocument() async {
    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final String issueDateText = issueDateController.text.trim();
    final String expiryDateText = expiryDateController.text.trim();
    final String reminderDateText = reminderDateController.text.trim();
    final String issueAuthorityText = issueAuthorityController.text.trim();

    if (title.isEmpty ||
        selectedCategoryId == null ||
        issueDateText.isEmpty ||
        expiryDateText.isEmpty ||
        reminderDateText.isEmpty ||
        issueAuthorityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    try {
      final DateTime issueDate = DateFormat('yyyy-MM-dd').parse(issueDateText);
      final DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateText);
      final DateTime reminderDate = DateFormat('yyyy-MM-dd HH:mm').parse(reminderDateText);

      if (expiryDate.isBefore(issueDate)) {
        throw Exception('Expiry date cannot be earlier than issue date.');
      }
      if (reminderDate.isBefore(issueDate) || reminderDate.isAfter(expiryDate)) {
        throw Exception('Reminder date must be between issue date and expiry date.');
      }

      setState(() => isLoading = true);

      // Generate a unique documentId.
      final String documentId = DateTime.now().millisecondsSinceEpoch.toString();

      // First, create the document with an empty filePath.
      final newDocument = Document(
        documentId: documentId,
        userId: currentUserId,
        title: title,
        description: description.isNotEmpty ? description : 'No description provided',
        categoryId: selectedCategoryId!,
        fileType: 'No File',
        filePath: '', // Empty for now.
        uploadDate: issueDate,
        expirationDate: expiryDate,
        reminderDate: reminderDate,
        issueAuthority: issueAuthorityText, // New field.
      );

      // Save the document to Firestore.
      await DocumentService().addDocument(newDocument);

      String fileDownloadUrl = '';
      File? pdfFile;
      if (uploadedImages.isNotEmpty) {
        pdfFile = await _generatePdf(uploadedImages);
        // Now that the document exists, upload the file and update the document.
        fileDownloadUrl = await DocumentService().uploadFile(documentId, pdfFile);
        await DocumentService().updateDocument(documentId, {
          'filePath': fileDownloadUrl,
          'fileType': 'PDF',
        });
      }

      // Create and add the reminder.
      final reminder = Reminder(
        reminderId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUserId,
        documentId: documentId,
        reminderDateTime: reminderDate,
        isCompleted: false,
      );

      await ReminderService().addReminder(reminder);

      // Schedule a notification for the reminder.
      await NotificationService.scheduleNotification(documentId, title, reminderDate);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document and reminder added successfully.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

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

  void _onBottomNavTap(int index) {
    setState(() {
      currentTabIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, reminderRoute);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, locationRoute, (route) => false);
        break;
      case 4:
        Navigator.pushNamed(context, settingsRoute);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Document')),
      body: isLoading
    ? LoadingSpinner()
    : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomSmallButton(text: 'Upload Images', onPressed: _pickImages),
                          CustomSmallButton(text: 'Scan Documents', onPressed: _scanDocuments),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        children: uploadedImages.map((img) => Image.file(img, width: 100, height: 100)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Document Details Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomTextField(controller: titleController, labelText: 'Document Title', icon: Icons.title),
                      const SizedBox(height: 20),
                      CustomTextField(controller: descriptionController, labelText: 'Description', icon: Icons.description),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: issueAuthorityController,
                        labelText: 'Issue Authority (Address)',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField(
                        value: selectedCategory,
                        items: categories.map((catName) {
                          return DropdownMenuItem(
                            value: catName,
                            child: Text(catName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value as String;
                            selectedCategoryId = categoryMap[selectedCategory];
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date Pickers Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      AddDocumentTextField(
                        controller: issueDateController,
                        labelText: 'Issue Date',
                        icon: Icons.date_range,
                        readOnly: true,
                        onTap: () async {
                          final DateTime? selectedDate = await showDatePicker(
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
                      const SizedBox(height: 20),
                      AddDocumentTextField(
                        controller: expiryDateController,
                        labelText: 'Expiry Date',
                        icon: Icons.date_range,
                        readOnly: true,
                        onTap: () async {
                          final DateTime? selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            expiryDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
                            _calculateReminderDate();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      AddDocumentTextField(
                        controller: reminderDateController,
                        labelText: 'Reminder Date & Time',
                        icon: Icons.alarm,
                        readOnly: true,
                        onTap: _pickReminderDateTime,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Submit Button Section
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CustomSmallButton(text: 'Add Document', onPressed: _addDocument),
                  ),
                ),
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
}

