import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer'; // For logging
import 'dart:io'; // For File class
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class NewItemSecondScreen extends StatefulWidget {
  final dynamic item;

  const NewItemSecondScreen({Key? key, required this.item}) : super(key: key);

  @override
  _NewItemSecondScreenState createState() => _NewItemSecondScreenState();
}

class _NewItemSecondScreenState extends State<NewItemSecondScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  List<TextEditingController> _controllers =
      []; // List to hold controllers for dynamic inputs
  List<String> _inputLabels =
      []; // List to hold input labels for dynamic fields
  String _imageUrl = ''; // Item image URL
  File? _image; // For selected image

  @override
  void initState() {
    super.initState();
    _fetchDynamicInputs(); // Fetch dynamic inputs when the screen is initialized
  }

  Future<void> _fetchDynamicInputs() async {
    try {
      // Fetch dynamic input configuration or data from Supabase
      // log(widget.item['id']);
      final response = await Supabase.instance.client
          .from('ModelAttributes')
          .select('*')
          .eq('model_id', widget.item['id']);

      if (response.error != null) {
        log('Error fetching dynamic inputs: ${response.error!.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error fetching dynamic inputs: ${response.error!.message}')),
        );
      } else {
        // Assuming response.data is a list of maps
        List<dynamic> inputs = response;

        // Clear previous controllers and labels
        _controllers.clear();
        _inputLabels.clear();

        // Create controllers and labels based on fetched data
        for (var input in inputs) {
          // Create a controller for each input field
          _controllers.add(TextEditingController());

          // Add label, converting to String if necessary
          _inputLabels.add(input['attribute_name']?.toString() ??
              ''); // Convert to String to avoid TypeError
        }

        setState(() {}); // Rebuild UI with new controllers
      }
    } catch (e) {
      log('Error fetching inputs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Item 2/2'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Build dynamic input fields based on fetched data
                for (int i = 0; i < _controllers.length; i++)
                  TextFormField(
                    controller: _controllers[i],
                    decoration: InputDecoration(labelText: _inputLabels[i]),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter ${_inputLabels[i]}'; // Custom error message for each input
                      }
                      return null;
                    },
                  ),
                _image != null
                    ? Image.file(_image!,
                        height: 100, width: 100, fit: BoxFit.cover)
                    : Text('No image selected'),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick Image'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Add Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Store the selected image in a File object
      setState(() {
        _image = File(pickedFile.path);
      });

      // Upload the selected image file
      await uploadFile(_image!);
    } else {
      log('No image selected');
    }
  }

// Function to upload file to Supabase storage
// Function to upload file to Supabase storage
  Future<void> uploadFile(File file) async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      // Create a unique file path using the user ID and current timestamp
      final filePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      log(filePath);
      log("filePath10");

      // Read the file's bytes using readAsBytes
      final Uint8List fileBytes = await file.readAsBytes();
      // log(fileBytes.toString());

      log("filePath1");

      // Upload the file to Supabase storage
      final response = await Supabase.instance.client.storage
          .from('images') // Replace with your actual bucket name
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      log("filePath2");

      // Check for errors during upload
      if (response.error != null) {
        log('Error uploading image: ${response.error!.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error uploading image: ${response.error!.message}')),
        );
      } else {
        log('Image uploaded successfully: $filePath');

        // Get the public URL of the uploaded image
        final imageUrl = Supabase.instance.client.storage
            .from('images')
            .getPublicUrl(filePath);
        log('Image URL: $imageUrl');

        // You can store or use the imageUrl as needed
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Save form data

      try {
        final user =
            Supabase.instance.client.auth.currentUser; // Get the logged-in user
        if (user != null) {
          String imageUrl = _imageUrl;

          // Step 1: Upload image if available
          if (_image != null) {
            final fileName =
                '${user.id}-${DateTime.now().millisecondsSinceEpoch}.jpg'; // Unique file name

            final uploadResponse = await Supabase.instance.client.storage
                .from('images') // Use the correct bucket name
                .upload(fileName, _image!);

            if (uploadResponse.error != null) {
              log('Error uploading image: ${uploadResponse.error!.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Error uploading image: ${uploadResponse.error!.message}')),
              );
              return; // Exit if image upload fails
            }

            // Get the public URL of the uploaded image
            imageUrl = Supabase.instance.client.storage
                .from('images')
                .getPublicUrl(fileName)!;
          }

          // Step 2: Build dynamic map of form inputs based on controllers
          Map<String, String> formData = {};
          for (int i = 0; i < _controllers.length; i++) {
            formData[_inputLabels[i]] = _controllers[i]
                .text; // Using label as the key and controller's text as the value
          }

          log(formData.toString());

          // Step 3: Insert into `CollectorItems` table
          final firstInsertResponse =
              await Supabase.instance.client.from('CollectorItems').insert({
            'user_id': user.id, // Associate the item with the user
            'name':
                _controllers[0].text, // Assuming the first input is the name
            'description': _controllers[1]
                .text, // Assuming the second input is the description
            'image_url': imageUrl, // Use uploaded image URL
          }).select();

          // Access the inserted data, including the item ID
          final insertedItem =
              firstInsertResponse![0]; // Safely access the first item
          final itemId = insertedItem['id']; // Get the auto-generated item ID

          log('Inserted item ID: $itemId');

          // Step 4: Insert dynamic attributes into `ItemAttributes` table
          List<Map<String, dynamic>> attributeInserts = [];

          formData.forEach((key, value) {
            attributeInserts.add({
              'item_id': itemId, // Associate the item with the `itemId`
              'attribute_name':
                  key, // Use the key from the form data as the attribute name
              'value': value, // Use the value from the form data
            });
          });

          final secondInsertResponse = await Supabase.instance.client
              .from('ItemAttributes')
              .insert(
                  attributeInserts); // Batch insert the array of key-value pairs


          // Step 5: If both inserts pass, navigate to the home screen
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not logged in')),
          );
        }
      } catch (e) {
        log('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }
}

extension on String {
  get error => null;
}

extension on PostgrestList {
  get error => null;
}
