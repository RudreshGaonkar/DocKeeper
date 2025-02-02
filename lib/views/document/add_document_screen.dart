// import 'dart:io';
// import 'dart:typed_data';
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
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';

// class AddDocumentScreen extends StatefulWidget {
//   @override
//   _AddDocumentScreenState createState() => _AddDocumentScreenState();
// }

// class _AddDocumentScreenState extends State<AddDocumentScreen> {
//   final TextEditingController titleController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   final TextEditingController issueDateController = TextEditingController();
//   final TextEditingController expiryDateController = TextEditingController();
//   final TextEditingController reminderDateController = TextEditingController();

//   final currentUserId = AuthService().currentUserId;

//   String? selectedCategory;
//   List<String> categories = [];
//   List<File> uploadedImages = [];
//   bool isLoading = false;

//   int currentTabIndex = 2;

//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//   }

//   // Future<void> _loadCategories() async {
//   //   try {
//   //     setState(() => isLoading = true);
//   //     final fetchedCategories = await CategoryService().fetchAllCategories();
//   //     setState(() => categories = fetchedCategories.map((cat) => cat.name).toList());
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Failed to load categories: $e')),
//   //     );
//   //   } finally {
//   //     setState(() => isLoading = false);
//   //   }
//   // }

//   Map<String, String> categoryMap = {}; // Map to store categoryName -> categoryId
//   String? selectedCategoryId; // Store the selected categoryId

//   Future<void> _loadCategories() async {
//     try {
//       setState(() => isLoading = true);
//       final fetchedCategories = await CategoryService().fetchAllCategories();

//       setState(() {
//         // Populate categoryMap with name -> id pairs
//         categoryMap = {
//           for (var cat in fetchedCategories) cat.name: cat.categoryId,
//         };
//         categories = categoryMap.keys.toList(); // Extract category names for dropdown
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load categories: $e')),
//       );
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
//         build: (context) => pw.Center(
//           child: pw.Image(pdfImage),
//         ),
//       ));
//     }

//     final outputDir = await getApplicationDocumentsDirectory();
//     final pdfFile = File('${outputDir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf');
//     await pdfFile.writeAsBytes(await pdf.save());
//     return pdfFile;
//   }

//   Future<void> _addDocument() async {
//     final title = titleController.text.trim();
//     final description = descriptionController.text.trim();
//     final issueDateText = issueDateController.text.trim();
//     final expiryDateText = expiryDateController.text.trim();
//     final reminderDateText = reminderDateController.text.trim();

//     if (title.isEmpty || selectedCategoryId == null || issueDateText.isEmpty || expiryDateText.isEmpty || reminderDateText.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please fill in all required fields.')),
//       );
//       return;
//     }

//     try {
//       final issueDate = DateFormat('yyyy-MM-dd').parse(issueDateText);
//       final expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateText);
//       final reminderDate = DateFormat('yyyy-MM-dd').parse(reminderDateText);

//       if (expiryDate.isBefore(issueDate)) {
//         throw Exception('Expiry date cannot be earlier than issue date.');
//       }
//       if (reminderDate.isBefore(issueDate) || reminderDate.isAfter(expiryDate)) {
//         throw Exception('Reminder date must be between issue date and expiry date.');
//       }

//       setState(() => isLoading = true);

//       File? pdfFile;
//       String fileDownloadUrl = ''; // Default empty string for non-null safety
//       final documentId = DateTime.now().millisecondsSinceEpoch.toString(); 


//       if (uploadedImages.isNotEmpty) {
//         pdfFile = await _generatePdf(uploadedImages);

//         // Ensure that `uploadFile` gets the file path as a String
//         // fileDownloadUrl = await DocumentService().uploadFile(pdfFile.path); 
//         fileDownloadUrl = await DocumentService().uploadFile(
//           documentId, 
//           pdfFile, // ✅ File (actual document)
//         );

//       }

//       // final documentId = DateTime.now().millisecondsSinceEpoch.toString(); 

//       final newDocument = Document(
//         documentId: documentId,
//         userId: currentUserId,
//         title: title,
//         description: description.isNotEmpty ? description : 'No description provided',
//         categoryId: selectedCategoryId!,
//         fileType: pdfFile != null ? 'PDF' : 'No File',
//         uploadDate: issueDate,
//         expirationDate: expiryDate,
//         reminderDate: reminderDate,
//         filePath: fileDownloadUrl, // Now guaranteed to be a non-null string
//       );

//       await DocumentService().addDocument(newDocument);

//       final reminder = Reminder(
//         reminderId: DateTime.now().millisecondsSinceEpoch.toString(),
//         userId: currentUserId,
//         documentId: documentId,
//         reminderDate: reminderDate,
//         isCompleted: false,
//       );

//       await ReminderService().addReminder(reminder);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Document and reminder added successfully.')),
//       );
//       Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }



//   Future<void> _pickImages() async {
//     final picker = ImagePicker();
//     final images = await picker.pickMultiImage();
//     if (images != null) {
//       setState(() {
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
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Document scanning failed: $e')),
//       );
//     }
//   }

//   void _calculateReminderDate() {
//     if (expiryDateController.text.isNotEmpty) {
//       final expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateController.text);
//       DateTime reminderDate;

//       if (expiryDate.difference(DateTime.now()).inDays >= 60) {
//         reminderDate = expiryDate.subtract(Duration(days: 30));
//       } else if (expiryDate.difference(DateTime.now()).inDays >= 7) {
//         reminderDate = expiryDate.subtract(Duration(days: 7));
//       } else {
//         reminderDate = expiryDate.subtract(Duration(days: 3));
//       }

//       setState(() {
//         reminderDateController.text = DateFormat('yyyy-MM-dd').format(reminderDate);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Add Document'),
//       ),
//       body: isLoading
//           ? LoadingSpinner()
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         CustomSmallButton(text: 'Upload Images', onPressed: _pickImages),
//                         CustomSmallButton(text: 'Scan Documents', onPressed: _scanDocuments),
//                       ],
//                     ),
//                     SizedBox(height: 20),
//                     Wrap(
//                       spacing: 10,
//                       children: uploadedImages.map((img) => Image.file(img, width: 100, height: 100)).toList(),
//                     ),
//                     SizedBox(height: 20),
//                     CustomTextField(controller: titleController, labelText: 'Document Title', icon: Icons.title),
//                     SizedBox(height: 20),
//                     CustomTextField(controller: descriptionController, labelText: 'Description', icon: Icons.description),
//                     SizedBox(height: 20),
//                     DropdownButtonFormField(
//                       value: selectedCategory,
//                       items: categories.map((catName) {
//                         return DropdownMenuItem(
//                           value: catName,
//                           child: Text(catName),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedCategory = value as String; // Selected category name
//                           selectedCategoryId = categoryMap[selectedCategory]; // Get corresponding ID
//                         });
//                       },
//                       decoration: InputDecoration(
//                         labelText: 'Category',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),

//                     SizedBox(height: 20),
//                     AddDocumentTextField(
//                       controller: issueDateController,
//                       labelText: 'Issue Date',
//                       icon: Icons.date_range,
//                       readOnly: true,
//                       onTap: () async {
//                         final selectedDate = await showDatePicker(
//                           context: context,
//                           initialDate: DateTime.now(),
//                           firstDate: DateTime(2000),
//                           lastDate: DateTime(2100),
//                         );
//                         if (selectedDate != null) {
//                           issueDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
//                         }
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     AddDocumentTextField(
//                       controller: expiryDateController,
//                       labelText: 'Expiry Date',
//                       icon: Icons.date_range,
//                       readOnly: true,
//                       onTap: () async {
//                         final selectedDate = await showDatePicker(
//                           context: context,
//                           initialDate: DateTime.now(),
//                           firstDate: DateTime.now(),
//                           lastDate: DateTime(2100),
//                         );
//                         if (selectedDate != null) {
//                           expiryDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
//                           _calculateReminderDate();
//                         }
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     AddDocumentTextField(
//                       controller: reminderDateController,
//                       labelText: 'Reminder Date',
//                       icon: Icons.alarm,
//                       readOnly: true,
//                       onTap: () async {
//                         final selectedDate = await showDatePicker(
//                           context: context,
//                           initialDate: DateTime.now(),
//                           firstDate: DateTime(2000),
//                           lastDate: DateTime(2100),
//                         );
//                         if (selectedDate != null) {
//                           reminderDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
//                         }
//                       },
//                     ),
//                     SizedBox(height: 30),
//                     CustomSmallButton(text: 'Add Document', onPressed: _addDocument),
//                   ],
//                 ),
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
//         // Navigator.pushReplacementNamed(context, reminderRoute);
//         break;
//       case 2:
//         Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
//         break;
//       case 3:
//         // Navigator.pushReplacementNamed(context, locationRoute);
//         break;
//       case 4:
//         Navigator.pushNamed(context, settingsRoute);
//         break;
//     }
//   }
// }
import 'dart:io';
import 'dart:typed_data';

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
import 'package:pdf/pdf.dart';
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

  final String currentUserId = AuthService().currentUserId;

  String? selectedCategory;
  List<String> categories = [];
  List<File> uploadedImages = [];
  bool isLoading = false;
  int currentTabIndex = 2;

  // Map to store categoryName -> categoryId
  Map<String, String> categoryMap = {};
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
    final pdfFile = File('${outputDir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await pdfFile.writeAsBytes(await pdf.save());
    return pdfFile;
  }

  Future<void> _addDocument() async {
    final String title = titleController.text.trim();
    final String description = descriptionController.text.trim();
    final String issueDateText = issueDateController.text.trim();
    final String expiryDateText = expiryDateController.text.trim();
    final String reminderDateText = reminderDateController.text.trim();

    if (title.isEmpty ||
        selectedCategoryId == null ||
        issueDateText.isEmpty ||
        expiryDateText.isEmpty ||
        reminderDateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    try {
      final DateTime issueDate = DateFormat('yyyy-MM-dd').parse(issueDateText);
      final DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateText);
      final DateTime reminderDate = DateFormat('yyyy-MM-dd').parse(reminderDateText);

      if (expiryDate.isBefore(issueDate)) {
        throw Exception('Expiry date cannot be earlier than issue date.');
      }
      if (reminderDate.isBefore(issueDate) || reminderDate.isAfter(expiryDate)) {
        throw Exception('Reminder date must be between issue date and expiry date.');
      }

      setState(() => isLoading = true);

      // Generate a unique documentId BEFORE creating the document
      final String documentId = DateTime.now().millisecondsSinceEpoch.toString();

      File? pdfFile;
      String fileDownloadUrl = '';
      if (uploadedImages.isNotEmpty) {
        pdfFile = await _generatePdf(uploadedImages);
        // Now call uploadFile with the documentId and pdfFile
        fileDownloadUrl = await DocumentService().uploadFile(documentId, pdfFile);
      }

      final newDocument = Document(
        documentId: documentId,
        userId: currentUserId,
        title: title,
        description: description.isNotEmpty ? description : 'No description provided',
        categoryId: selectedCategoryId!,
        fileType: pdfFile != null ? 'PDF' : 'No File',
        filePath: fileDownloadUrl, // Download URL from Firebase Storage\n        uploadDate: issueDate,
        uploadDate: issueDate,
        expirationDate: expiryDate,
        reminderDate: reminderDate,
      );

      await DocumentService().addDocument(newDocument);

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
      setState(() {
        reminderDateController.text = DateFormat('yyyy-MM-dd').format(reminderDate);
      });
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
                      decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
                    AddDocumentTextField(
                      controller: reminderDateController,
                      labelText: 'Reminder Date',
                      icon: Icons.alarm,
                      readOnly: true,
                      onTap: () async {
                        final DateTime? selectedDate = await showDatePicker(
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
                    Center(child: CustomSmallButton(text: 'Add Document', onPressed: _addDocument)),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: currentTabIndex, onTap: _onBottomNavTap),
    );
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
        // Navigator.pushReplacementNamed(context, reminderRoute);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, addDocumentRoute, (route) => false);
        break;
      case 3:
        // Navigator.pushReplacementNamed(context, locationRoute);
        break;
      case 4:
        Navigator.pushNamed(context, settingsRoute);
        break;
      default:
        break;
    }
  }
}

