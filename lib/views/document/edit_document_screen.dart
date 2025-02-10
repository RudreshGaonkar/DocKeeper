// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cunning_document_scanner/cunning_document_scanner.dart';
// import 'package:dockeeper/core/routes.dart';
// import 'package:dockeeper/models/document_model.dart';
// import 'package:dockeeper/models/reminder_model.dart';
// import 'package:dockeeper/services/auth_service.dart';
// import 'package:dockeeper/services/category_service.dart';
// import 'package:dockeeper/services/document_service.dart';
// import 'package:dockeeper/services/reminder_service.dart';
// import 'package:dockeeper/widgets/addScreen_textField.dart';
// import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';
// import 'package:dockeeper/widgets/custom_small_button.dart';
// import 'package:dockeeper/widgets/custom_text_field.dart';
// import 'package:dockeeper/widgets/loading_spinner.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';

// class UpdateDocumentScreen extends StatefulWidget {
//   final String documentId;

//   const UpdateDocumentScreen({Key? key, required this.documentId}) : super(key: key);

//   @override
//   _UpdateDocumentScreenState createState() => _UpdateDocumentScreenState();
// }

// class _UpdateDocumentScreenState extends State<UpdateDocumentScreen> {
//   // Controllers for text fields.
//   final TextEditingController titleController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController issueDateController = TextEditingController();
//   final TextEditingController expiryDateController = TextEditingController();
//   final TextEditingController reminderDateController = TextEditingController();

//   final String currentUserId = AuthService().currentUserId;

//   // Category-related variables.
//   String? selectedCategory; // Displayed category name.
//   List<String> categories = [];
//   Map<String, String> categoryMap = {}; // Maps category name -> categoryId.
//   String? selectedCategoryId; // Actual categoryId.

//   // List of new images selected for updating the file.
//   List<File> uploadedImages = [];

//   bool isLoading = false;
//   int currentTabIndex = 2;

//   // The current document fetched from Firestore.
//   Document? currentDocument;

//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//     _fetchDocumentData();
//   }

//   Future<void> _fetchDocumentData() async {
//     try {
//       setState(() => isLoading = true);
//       final docSnapshot = await FirebaseFirestore.instance
//           .collection('documents')
//           .doc(widget.documentId)
//           .get();
//       if (docSnapshot.exists) {
//         final data = docSnapshot.data() as Map<String, dynamic>;
//         currentDocument = Document.fromJson(data);
//         // Prepopulate fields.
//         titleController.text = currentDocument!.title;
//         descriptionController.text = currentDocument!.description;
//         issueDateController.text =
//             DateFormat('yyyy-MM-dd').format(currentDocument!.uploadDate);
//         expiryDateController.text =
//             DateFormat('yyyy-MM-dd').format(currentDocument!.expirationDate);
//         // Assuming reminderDate is stored with time.
//         reminderDateController.text = DateFormat('yyyy-MM-dd HH:mm')
//             .format(currentDocument!.reminderDate);
//         selectedCategoryId = currentDocument!.categoryId;
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching document: $e')),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _loadCategories() async {
//     try {
//       setState(() => isLoading = true);
//       final fetchedCategories = await CategoryService().fetchAllCategories();
//       setState(() {
//         categoryMap = {for (var cat in fetchedCategories) cat.name: cat.categoryId};
//         categories = categoryMap.keys.toList();
//         // If currentDocument is loaded, set selectedCategory accordingly.
//         if (currentDocument != null) {
//           selectedCategory = categoryMap.entries
//               .firstWhere((entry) => entry.value == currentDocument!.categoryId,
//                   orElse: () => const MapEntry("Unknown", ""))
//               .key;
//         }
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<File> _generatePdf(List<File> images) async {
//     final pdf = pw.Document();
//     for (var image in images) {
//       final imageBytes = await image.readAsBytes();
//       final pdfImage = pw.MemoryImage(imageBytes);
//       pdf.addPage(pw.Page(
//           build: (context) => pw.Center(child: pw.Image(pdfImage))));
//     }
//     final outputDir = await getApplicationDocumentsDirectory();
//     final pdfFile = File('${outputDir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf');
//     await pdfFile.writeAsBytes(await pdf.save());
//     return pdfFile;
//   }

//   /// Allows the user to pick a custom reminder date and time.
//   Future<void> _pickReminderDateTime() async {
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (pickedDate == null) return;
//     final TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay(hour: 8, minute: 0),
//     );
//     if (pickedTime == null) return;
//     final DateTime combined = DateTime(
//       pickedDate.year,
//       pickedDate.month,
//       pickedDate.day,
//       pickedTime.hour,
//       pickedTime.minute,
//     );
//     setState(() {
//       reminderDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(combined);
//     });
//   }

//   Future<void> _updateDocument() async {
//     final String title = titleController.text.trim();
//     final String description = descriptionController.text.trim();
//     final String issueDateText = issueDateController.text.trim();
//     final String expiryDateText = expiryDateController.text.trim();
//     final String reminderDateText = reminderDateController.text.trim();

//     if (title.isEmpty ||
//         selectedCategoryId == null ||
//         issueDateText.isEmpty ||
//         expiryDateText.isEmpty ||
//         reminderDateText.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Please fill in all required fields.')));
//       return;
//     }

//     try {
//       final DateTime issueDate = DateFormat('yyyy-MM-dd').parse(issueDateText);
//       final DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateText);
//       final DateTime reminderDate = DateFormat('yyyy-MM-dd HH:mm').parse(reminderDateText);

//       if (expiryDate.isBefore(issueDate)) {
//         throw Exception('Expiry date cannot be earlier than issue date.');
//       }
//       if (reminderDate.isBefore(issueDate) || reminderDate.isAfter(expiryDate)) {
//         throw Exception('Reminder date must be between issue date and expiry date.');
//       }

//       setState(() => isLoading = true);

//       // Use the existing file download URL unless new images are provided.
//       String fileDownloadUrl = currentDocument!.filePath ?? '';
//       File? pdfFile;
//       if (uploadedImages.isNotEmpty) {
//         pdfFile = await _generatePdf(uploadedImages);
//         fileDownloadUrl = await DocumentService().uploadFile(currentDocument!.documentId, pdfFile);
//       }

//       // Prepare updated data.
//       Map<String, dynamic> updates = {
//         'title': title,
//         'description': description.isNotEmpty ? description : 'No description provided',
//         'categoryId': selectedCategoryId,
//         'fileType': pdfFile != null ? 'PDF' : currentDocument!.fileType,
//         'filePath': fileDownloadUrl,
//         'uploadDate': issueDate.toIso8601String(),
//         'expirationDate': expiryDate.toIso8601String(),
//         'reminderDate': reminderDate.toIso8601String(),
//       };

//       await DocumentService().updateDocument(currentDocument!.documentId, updates);

//       // Optionally update reminder data via ReminderService.

//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Document updated successfully.')));
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error: $e')));
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _pickImages() async {
//     final picker = ImagePicker();
//     final images = await picker.pickMultiImage();
//     if (images != null) {
//       setState(() {
//         // Append new images.
//         uploadedImages.addAll(images.map((img) => File(img.path)));
//       });
//     }
//   }

//   Future<void> _scanDocuments() async {
//     try {
//       final scannedPaths = await CunningDocumentScanner.getPictures();
//       if (scannedPaths != null) {
//         setState(() {
//           uploadedImages.addAll(scannedPaths.map((path) => File(path)));
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Document scanning failed: $e')));
//     }
//   }

//   void _calculateReminderDate() {
//     if (expiryDateController.text.isNotEmpty) {
//       final DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateController.text);
//       DateTime reminderDate;
//       if (expiryDate.difference(DateTime.now()).inDays >= 60) {
//         reminderDate = expiryDate.subtract(Duration(days: 30));
//       } else if (expiryDate.difference(DateTime.now()).inDays >= 7) {
//         reminderDate = expiryDate.subtract(Duration(days: 7));
//       } else {
//         reminderDate = expiryDate.subtract(Duration(days: 3));
//       }
//       // Default time is as per user's selection in the reminder picker.
//       setState(() {
//         reminderDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(reminderDate);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Update Document'),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? LoadingSpinner()
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Section for updating file (optional).
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       CustomSmallButton(text: 'Upload New Images', onPressed: _pickImages),
//                       CustomSmallButton(text: 'Scan New Documents', onPressed: _scanDocuments),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   if (uploadedImages.isNotEmpty)
//                     Wrap(
//                       spacing: 10,
//                       children: uploadedImages.map((img) => Image.file(img, width: 100, height: 100)).toList(),
//                     ),
//                   const SizedBox(height: 20),
//                   CustomTextField(controller: titleController, labelText: 'Document Title', icon: Icons.title),
//                   const SizedBox(height: 20),
//                   CustomTextField(controller: descriptionController, labelText: 'Description', icon: Icons.description),
//                   const SizedBox(height: 20),
//                   DropdownButtonFormField(
//                     value: selectedCategory,
//                     items: categories.map((catName) {
//                       return DropdownMenuItem(
//                         value: catName,
//                         child: Text(catName),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedCategory = value as String;
//                         selectedCategoryId = categoryMap[selectedCategory];
//                       });
//                     },
//                     decoration: InputDecoration(
//                       labelText: 'Category',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   AddDocumentTextField(
//                     controller: issueDateController,
//                     labelText: 'Issue Date',
//                     icon: Icons.date_range,
//                     readOnly: true,
//                     onTap: () async {
//                       final DateTime? selectedDate = await showDatePicker(
//                         context: context,
//                         initialDate: issueDateController.text.isNotEmpty
//                             ? DateFormat('yyyy-MM-dd').parse(issueDateController.text)
//                             : DateTime.now(),
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                       );
//                       if (selectedDate != null) {
//                         issueDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   AddDocumentTextField(
//                     controller: expiryDateController,
//                     labelText: 'Expiry Date',
//                     icon: Icons.date_range,
//                     readOnly: true,
//                     onTap: () async {
//                       final DateTime? selectedDate = await showDatePicker(
//                         context: context,
//                         initialDate: expiryDateController.text.isNotEmpty
//                             ? DateFormat('yyyy-MM-dd').parse(expiryDateController.text)
//                             : DateTime.now(),
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                       );
//                       if (selectedDate != null) {
//                         expiryDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
//                         _calculateReminderDate();
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   AddDocumentTextField(
//                     controller: reminderDateController,
//                     labelText: 'Reminder Date & Time',
//                     icon: Icons.alarm,
//                     readOnly: true,
//                     onTap: _pickReminderDateTime,
//                   ),
//                   const SizedBox(height: 30),
//                   Center(child: CustomSmallButton(text: 'Update Document', onPressed: _updateDocument)),
//                 ],
//               ),
//             ),
//       bottomNavigationBar: CustomBottomNavBar(
//         currentIndex: currentTabIndex,
//         onTap: _onBottomNavTap,
//       ),
//     );
//   }

//   void _onBottomNavTap(int index) {
//     setState(() {
//       currentTabIndex = index;
//     });
//     switch (index) {
//       case 0:
//         Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
//         break;
//       case 1:
//         Navigator.pushReplacementNamed(context, reminderRoute);
//         break;
//       case 2:
//         Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
//         break;
//       case 3:
//         Navigator.pushNamedAndRemoveUntil(context, locationRoute, (route) => false);
//         break;
//       case 4:
//         Navigator.pushNamed(context, settingsRoute);
//         break;
//       default:
//         break;
//     }
//   }
// }
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class UpdateDocumentScreen extends StatefulWidget {
  final String documentId;

  const UpdateDocumentScreen({Key? key, required this.documentId}) : super(key: key);

  @override
  _UpdateDocumentScreenState createState() => _UpdateDocumentScreenState();
}

class _UpdateDocumentScreenState extends State<UpdateDocumentScreen> {
  // Controllers for text fields.
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController issueDateController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController reminderDateController = TextEditingController();
  // New controller for Issue Authority.
  final TextEditingController issueAuthorityController = TextEditingController();

  final String currentUserId = AuthService().currentUserId;

  // Category-related variables.
  String? selectedCategory; // Displayed category name.
  List<String> categories = [];
  Map<String, String> categoryMap = {}; // Maps category name -> categoryId.
  String? selectedCategoryId; // Actual categoryId.

  // List of new images selected for updating the file.
  List<File> uploadedImages = [];

  bool isLoading = false;
  int currentTabIndex = 2;

  // The current document fetched from Firestore.
  Document? currentDocument;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchDocumentData();
  }

  Future<void> _fetchDocumentData() async {
    try {
      setState(() => isLoading = true);
      final docSnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .doc(widget.documentId)
          .get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        currentDocument = Document.fromJson(data);
        // Prepopulate fields.
        titleController.text = currentDocument!.title;
        descriptionController.text = currentDocument!.description;
        issueDateController.text =
            DateFormat('yyyy-MM-dd').format(currentDocument!.uploadDate);
        expiryDateController.text =
            DateFormat('yyyy-MM-dd').format(currentDocument!.expirationDate);
        reminderDateController.text = DateFormat('yyyy-MM-dd HH:mm')
            .format(currentDocument!.reminderDate);
        // Prepopulate the new issueAuthority field.
        issueAuthorityController.text = currentDocument!.issueAuthority ?? '';

        selectedCategoryId = currentDocument!.categoryId;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching document: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => isLoading = true);
      final fetchedCategories = await CategoryService().fetchAllCategories();
      setState(() {
        categoryMap =
            {for (var cat in fetchedCategories) cat.name: cat.categoryId};
        categories = categoryMap.keys.toList();
        // If currentDocument is loaded, set selectedCategory accordingly.
        if (currentDocument != null) {
          selectedCategory = categoryMap.entries
              .firstWhere((entry) => entry.value == currentDocument!.categoryId,
                  orElse: () => const MapEntry("Unknown", ""))
              .key;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
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
    final pdfFile = File(
        '${outputDir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await pdfFile.writeAsBytes(await pdf.save());
    return pdfFile;
  }

  /// Allows the user to pick a custom reminder date and time.
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
      reminderDateController.text =
          DateFormat('yyyy-MM-dd HH:mm').format(combined);
    });
  }

  Future<void> _updateDocument() async {
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
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    try {
      final DateTime issueDate = DateFormat('yyyy-MM-dd').parse(issueDateText);
      final DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateText);
      final DateTime reminderDate =
          DateFormat('yyyy-MM-dd HH:mm').parse(reminderDateText);

      if (expiryDate.isBefore(issueDate)) {
        throw Exception('Expiry date cannot be earlier than issue date.');
      }
      if (reminderDate.isBefore(issueDate) || reminderDate.isAfter(expiryDate)) {
        throw Exception(
            'Reminder date must be between issue date and expiry date.');
      }

      setState(() => isLoading = true);

      // Use the existing file download URL unless new images are provided.
      String fileDownloadUrl = currentDocument!.filePath ?? '';
      File? pdfFile;
      if (uploadedImages.isNotEmpty) {
        pdfFile = await _generatePdf(uploadedImages);
        fileDownloadUrl = await DocumentService()
            .uploadFile(currentDocument!.documentId, pdfFile);
      }

      // Prepare updated data including the new issueAuthority field.
      Map<String, dynamic> updates = {
        'title': title,
        'description': description.isNotEmpty ? description : 'No description provided',
        'categoryId': selectedCategoryId,
        'fileType': pdfFile != null ? 'PDF' : currentDocument!.fileType,
        'filePath': fileDownloadUrl,
        'uploadDate': issueDate.toIso8601String(),
        'expirationDate': expiryDate.toIso8601String(),
        'reminderDate': reminderDate.toIso8601String(),
        'issueAuthority': issueAuthorityText, // New field added here.
      };

      await DocumentService()
          .updateDocument(currentDocument!.documentId, updates);

      // Optionally update associated reminder(s) via ReminderService.

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document updated successfully.')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null) {
      setState(() {
        // Append new images.
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
          SnackBar(content: Text('Document scanning failed: $e')));
    }
  }

  void _calculateReminderDate() {
    if (expiryDateController.text.isNotEmpty) {
      final DateTime expiryDate =
          DateFormat('yyyy-MM-dd').parse(expiryDateController.text);
      DateTime reminderDate;
      if (expiryDate.difference(DateTime.now()).inDays >= 60) {
        reminderDate = expiryDate.subtract(const Duration(days: 30));
      } else if (expiryDate.difference(DateTime.now()).inDays >= 7) {
        reminderDate = expiryDate.subtract(const Duration(days: 7));
      } else {
        reminderDate = expiryDate.subtract(const Duration(days: 3));
      }
      // Use the default time from the reminder picker (do not force change here).
      setState(() {
        reminderDateController.text =
            DateFormat('yyyy-MM-dd HH:mm').format(reminderDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Document'),
        centerTitle: true,
      ),
      body: isLoading
          ?  LoadingSpinner()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section for updating file (optional).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomSmallButton(
                          text: 'Upload New Images', onPressed: _pickImages),
                      CustomSmallButton(
                          text: 'Scan New Documents', onPressed: _scanDocuments),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (uploadedImages.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      children: uploadedImages
                          .map((img) => Image.file(img, width: 100, height: 100))
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  // Document Title.
                  CustomTextField(
                      controller: titleController,
                      labelText: 'Document Title',
                      icon: Icons.title),
                  const SizedBox(height: 20),
                  // Description.
                  CustomTextField(
                      controller: descriptionController,
                      labelText: 'Description',
                      icon: Icons.description),
                  const SizedBox(height: 20),
                  // New Issue Authority field.
                  CustomTextField(
                      controller: issueAuthorityController,
                      labelText: 'Issue Authority (Address)',
                      icon: Icons.location_on),
                  const SizedBox(height: 20),
                  // Dropdown for selecting category.
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
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Issue Date picker.
                  AddDocumentTextField(
                    controller: issueDateController,
                    labelText: 'Issue Date',
                    icon: Icons.date_range,
                    readOnly: true,
                    onTap: () async {
                      final DateTime? selectedDate =
                          await showDatePicker(
                        context: context,
                        initialDate: issueDateController.text.isNotEmpty
                            ? DateFormat('yyyy-MM-dd')
                                .parse(issueDateController.text)
                            : DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        issueDateController.text =
                            DateFormat('yyyy-MM-dd').format(selectedDate);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Expiry Date picker.
                  AddDocumentTextField(
                    controller: expiryDateController,
                    labelText: 'Expiry Date',
                    icon: Icons.date_range,
                    readOnly: true,
                    onTap: () async {
                      final DateTime? selectedDate =
                          await showDatePicker(
                        context: context,
                        initialDate: expiryDateController.text.isNotEmpty
                            ? DateFormat('yyyy-MM-dd')
                                .parse(expiryDateController.text)
                            : DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selectedDate != null) {
                        expiryDateController.text =
                            DateFormat('yyyy-MM-dd').format(selectedDate);
                        _calculateReminderDate();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Reminder Date & Time picker.
                  AddDocumentTextField(
                    controller: reminderDateController,
                    labelText: 'Reminder Date & Time',
                    icon: Icons.alarm,
                    readOnly: true,
                    onTap: _pickReminderDateTime,
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: CustomSmallButton(
                        text: 'Update Document', onPressed: _updateDocument),
                  ),
                ],
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
        Navigator.pushNamedAndRemoveUntil(
            context, homeRoute, (route) => false);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, reminderRoute);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
            context, addDocumentRoute, (route) => false);
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
            context, locationRoute, (route) => false);
        break;
      case 4:
        Navigator.pushNamed(context, settingsRoute);
        break;
      default:
        break;
    }
  }
}
