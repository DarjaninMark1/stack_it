import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer'; // For logging
import 'package:image_picker/image_picker.dart';

class NewItemSecondScreen extends StatefulWidget {
  final dynamic item;

  const NewItemSecondScreen({Key? key, required this.item}) : super(key: key);

  @override
  _NewItemSecondScreenState createState() => _NewItemSecondScreenState();
}

class _NewItemSecondScreenState extends State<NewItemSecondScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  List<TextEditingController> _controllers = []; // Controllers for dynamic inputs
  List<String> _inputLabels = []; // Labels for dynamic fields
  String _imageUrl = ''; // Item image URL

  @override
  void initState() {
    super.initState();
    _fetchDynamicInputs(); // Fetch dynamic inputs when the screen is initialized
  }

  // Fetch dynamic form inputs from Supabase
  Future<void> _fetchDynamicInputs() async {
    try {
      final response = await Supabase.instance.client
          .from('ModelAttributes')
          .select('*')
          .eq('model_id', widget.item['id']); // Fetch based on model ID

      List<dynamic> inputs = response;
      _controllers.clear(); // Clear previous data
      _inputLabels.clear(); 

      // Create controllers and labels based on fetched inputs
      for (var input in inputs) {
        _controllers.add(TextEditingController());
        _inputLabels.add(input['attribute_name'].toString());
      }
      setState(() {}); // Rebuild UI with new data
    } catch (e) {
      log('Error fetching inputs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while fetching inputs: $e')),
      );
    }
  }

  // Function to pick an image from the gallery and upload to Supabase
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Upload the selected image file to Supabase
        String? imageUrl = await uploadFile(pickedFile);
        if (imageUrl != null) {
          setState(() {
            _imageUrl = imageUrl; // Store the image URL
          });
        }
      } else {
        log('No image selected');
      }
    } catch (e) {
      log('Error picking image: $e');
    }
  }

  // Function to upload the image to Supabase storage
  Future<String?> uploadFile(XFile file) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in')),
        );
        return null;
      }

      final filePath = 'images/${user.id}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await file.readAsBytes(); // Read the file bytes

      final response = await Supabase.instance.client.storage
          .from('images') // Correct bucket name
          .uploadBinary(filePath, fileBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

      // Get and return the public URL of the uploaded image
      final imageUrl = Supabase.instance.client.storage.from('images').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      log('Error uploading file: $e');
      return null;
    }
  }

  // Handle the full form submission process
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return; // Validate the form

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in')));
        return;
      }

      String? imageUrl = _imageUrl;

      // Step 1: If image is uploaded, use the image URL
      if (_imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload an image')));
        return;
      }

      // Step 2: Collect form data
      Map<String, String> formData = {};
      for (int i = 0; i < _controllers.length; i++) {
        formData[_inputLabels[i]] = _controllers[i].text;
      }

      // Step 3: Insert into `CollectorItems` table
      final itemResponse = await Supabase.instance.client.from('CollectorItems').insert({
        'user_id': user.id,
        'name': _controllers[0].text, // Assuming the first field is the name
        'description': _controllers[1].text, // Assuming the second field is the description
        'image_url': imageUrl,
        'model_id': widget.item['id'],
      }).select();

      // Get the inserted item ID
      final insertedItem = itemResponse[0];
      final itemId = insertedItem['id'];
      log('Inserted item ID: $itemId');

      // Step 4: Insert dynamic attributes into `ItemAttributes` table
      List<Map<String, dynamic>> attributeInserts = [];
      formData.forEach((key, value) {
        attributeInserts.add({
          'item_id': itemId,
          'attribute_name': key,
          'value': value,
        });
      });

      await Supabase.instance.client.from('ItemAttributes').insert(attributeInserts);

      // Step 5: Navigate to home on success
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      log('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Item 2/2')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Item Name Field
                TextFormField(
                  decoration: InputDecoration(labelText: 'Item Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter item name' : null,
                ),
                SizedBox(height: 16),

                // Description Field
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
                ),
                SizedBox(height: 16),

                // Dynamic Input Fields
                for (int i = 0; i < _controllers.length; i++)
                  TextFormField(
                    controller: _controllers[i],
                    decoration: InputDecoration(labelText: _inputLabels[i]),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter ${_inputLabels[i]}' : null,
                  ),
                SizedBox(height: 16),

                // Display the image from a network URL if it's uploaded
                _imageUrl.isNotEmpty
                    ? Image.network(_imageUrl, height: 100, width: 100, fit: BoxFit.cover)
                    : Text('No image uploaded'),

                // Image Picker Button
                ElevatedButton(onPressed: _pickAndUploadImage, child: Text('Pick & Upload Image')),

                SizedBox(height: 20),

                // Submit Button
                ElevatedButton(onPressed: _submitForm, child: Text('Add Item')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
