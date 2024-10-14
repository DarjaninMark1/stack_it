import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Image picker
import 'dart:developer'; // For logging

class UpdateScreen extends StatefulWidget {
  final dynamic item; // The item to be updated

  const UpdateScreen({Key? key, required this.item}) : super(key: key);

  @override
  _UpdateScreenState createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _borrowerController; // Added for borrow_to
  final List<TextEditingController> _attributeControllers = [];
  List<dynamic> _attributes = [];
  String? _previousImageUrl; // Track the previous image URL for deletion

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing item values
    _nameController = TextEditingController(text: widget.item['name']);
    _descriptionController =
        TextEditingController(text: widget.item['description']);
    _imageUrlController = TextEditingController(text: widget.item['image_url']);
    _borrowerController = TextEditingController(
        text: widget.item['borrow_to']); // Initialize borrow_to controller

    _previousImageUrl = widget.item['image_url']; // Store the current image URL
    _initializeAttributeControllers();
  }

  // Initialize dynamic attribute controllers
  void _initializeAttributeControllers() {
    _attributes = widget.item['attributes'] ?? [];
    for (var attribute in _attributes) {
      _attributeControllers
          .add(TextEditingController(text: attribute['value']));
    }
  }

  // Pick an image from the gallery and upload it to Supabase
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Before uploading, store the current image URL for possible deletion
        String? newImageUrl = await _uploadFile(pickedFile);
        if (newImageUrl != null) {
          setState(() {
            _imageUrlController.text =
                newImageUrl; // Update the image URL controller with the new one
          });

          // Delete the previous image if a new one was successfully uploaded
          if (_previousImageUrl != null && _previousImageUrl!.isNotEmpty) {
            await _deletePreviousImage(_previousImageUrl!);
          }

          // Set the new image URL as the previous one
          _previousImageUrl = newImageUrl;
        }
      } else {
        log('No image selected');
      }
    } catch (e) {
      log('Error picking image: $e');
    }
  }

  // Upload the selected image to Supabase storage
  Future<String?> _uploadFile(XFile file) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('User not logged in')));
        return null;
      }

      final filePath =
          'images/${user.id}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await file.readAsBytes();

      final response = await Supabase.instance.client.storage
          .from('images') // Replace with your correct bucket name
          .uploadBinary(filePath, fileBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'));

      final imageUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      log('Error uploading file: $e');
      return null;
    }
  }

  // Delete the previous image from Supabase storage
  Future<void> _deletePreviousImage(String imageUrl) async {
    try {
      final filePath = imageUrl.replaceAll(
        Supabase.instance.client.storage.from('images').getPublicUrl(''),
        '',
      );

      final response = await Supabase.instance.client.storage
          .from('images')
          .remove([filePath]);

      log('Previous image deleted: $filePath');
    } catch (e) {
      log('Error deleting previous image: $e');
    }
  }

  // Update the item and its attributes in the database
  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      // Step 1: Update item details in the CollectorItems table
      final itemResponse = await Supabase.instance.client
          .from('CollectorItems') // Change to your actual items table name
          .update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'image_url': _imageUrlController.text,
        'borrow_to': _borrowerController.text,
      }).eq('id', widget.item['id']); // Don't forget to call execute()

      if (itemResponse != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error updating item: ${itemResponse.error!.message}')),
        );
        return; // Exit if there's an error
      }

      final List<Map<String, dynamic>> attributeInserts = [];
      // Step 2: Update attributes in the ItemAttributes table
      for (int i = 0; i < _attributes.length; i++) {
        attributeInserts.add({
          'id': _attributes[i]['id'], // Associate the item with the `itemId`
          'value': _attributeControllers[i].text,
        });
        log(_attributes[i].toString());
      }

      final secondInsertResponse = await Supabase.instance.client
          .from('ItemAttributes')
          .upsert(attributeInserts);

      // On success, show confirmation and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item updated successfully!')),
      );
      Navigator.pop(context); // Go back to the previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the image or a placeholder message
                _imageUrlController.text.isNotEmpty
                    ? Image.network(
                        _imageUrlController.text,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text('Error loading image');
                        },
                      )
                    : Container(
                        height: 200,
                        width: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            'No image available',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                // Button to pick and upload an image
                ElevatedButton(
                  onPressed: _pickAndUploadImage,
                  child: Text('Pick & Upload New Image'),
                ),
                SizedBox(height: 10),

                // Display fields for attributes
                ..._attributes.map((attribute) {
                  int index = _attributes.indexOf(attribute);
                  return TextFormField(
                    controller: _attributeControllers[index],
                    decoration:
                        InputDecoration(labelText: attribute['attribute_name']),
                  );
                }).toList(),
                SizedBox(height: 20),

                // Borrower input
                TextFormField(
                  controller: _borrowerController,
                  decoration: InputDecoration(labelText: 'Borrower'),
                ),
                SizedBox(height: 20),

                // Update Button
                ElevatedButton(
                  onPressed: _updateItem,
                  child: Text('Update Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of controllers to free resources
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _borrowerController.dispose(); // Dispose of borrow_to controller
    for (var controller in _attributeControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
