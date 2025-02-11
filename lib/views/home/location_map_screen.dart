import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dockeeper/core/routes.dart';
import 'package:dockeeper/models/category_model.dart';
import 'package:dockeeper/models/document_model.dart';
import 'package:dockeeper/services/category_service.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dockeeper/widgets/custom_bottom_nav_bar.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<Document> _documents = [];
  Document? _selectedDocument;
  LatLng? _documentLocation;
  bool isLoading = false;

  GoogleMapController? _mapController;
  int currentTabIndex = 3; // Assuming index 3 corresponds to LocationScreen

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoading = true;
    });
    try {
      final cats = await CategoryService().fetchAllCategories();
      setState(() {
        _categories = cats;
      });
    } catch (e) {
      print("Error fetching categories: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching categories: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDocumentsForCategory(Category category) async {
    setState(() {
      isLoading = true;
      _documents = [];
      _selectedDocument = null;
      _documentLocation = null;
    });
    try {
      // Query Firestore for documents with the selected categoryId.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .where('categoryId', isEqualTo: category.categoryId)
          .get();
      final docs = querySnapshot.docs
          .map((doc) => Document.fromJson(doc.data()))
          .toList();
      setState(() {
        _documents = docs;
      });
    } catch (e) {
      print("Error fetching documents: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching documents: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Converts an address into a LatLng using the geocoding package.
  Future<LatLng> _getLatLngFromAddress(String? address) async {
    if (address == null || address.trim().isEmpty) {
      throw Exception("No address provided.");
    }
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      } else {
        throw Exception("No location found for address.");
      }
    } catch (e) {
      throw Exception("Error geocoding address: $e");
    }
  }

  /// Called when a document is selected.
  Future<void> _onDocumentSelected(Document document) async {
    setState(() {
      _selectedDocument = document;
      _documentLocation = null;
    });
    try {
      final String? address = document.issueAuthority;
      if (address == null || address.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Selected document has no issue authority address.")),
        );
        return;
      }
      final latLng = await _getLatLngFromAddress(address);
      setState(() {
        _documentLocation = latLng;
      });
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      }
    } catch (e) {
      print("Error geocoding address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error geocoding address: $e")),
      );
    }
  }

  /// Launches the default maps application with directions to the document's location.
  Future<void> _launchMapsApp() async {
    if (_documentLocation == null) return;
    final double lat = _documentLocation!.latitude;
    final double lng = _documentLocation!.longitude;
    final String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch maps app.")),
      );
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, homeRoute);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, reminderRoute);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, addDocumentRoute);
        break;
      case 3:
        // Already on LocationScreen.
        break;
      case 4:
        Navigator.pushReplacementNamed(context, settingsRoute);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown to select a category.
                  DropdownButtonFormField<Category>(
                    decoration: InputDecoration(
                      labelText: "Select Category",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    items: _categories.map((Category cat) {
                      return DropdownMenuItem<Category>(
                        value: cat,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (Category? newCat) {
                      if (newCat != null) {
                        setState(() {
                          _selectedCategory = newCat;
                        });
                        _fetchDocumentsForCategory(newCat);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Dropdown to select a document.
                  DropdownButtonFormField<Document>(
                    decoration: InputDecoration(
                      labelText: "Select Document",
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedDocument,
                    items: _documents.map((Document doc) {
                      return DropdownMenuItem<Document>(
                        value: doc,
                        child: Text(doc.title),
                      );
                    }).toList(),
                    onChanged: (Document? newDoc) {
                      if (newDoc != null) {
                        _onDocumentSelected(newDoc);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Google Map view.
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Soft rounded corners
                      ),
                      elevation: 4, // Adds a shadow for a lifted effect
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12), // Ensures rounded corners
                        child: _documentLocation == null
                            ? const Center(
                                child: Text(
                                  "Location will appear here.",
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              )
                            : GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _documentLocation!,
                                  zoom: 15,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId("docLocation"),
                                    position: _documentLocation!,
                                    infoWindow: InfoWindow(
                                      title: _selectedDocument?.title ?? "",
                                      snippet: _selectedDocument?.issueAuthority ?? "",
                                    ),
                                  ),
                                },
                                onMapCreated: (GoogleMapController controller) {
                                  _mapController = controller;
                                },
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Button to open maps app for directions.
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _launchMapsApp,
                      icon: const Icon(Icons.directions),
                      label: const Text("Get Directions"),
                    ),
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
}
