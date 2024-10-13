import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stack_it/new_item_second_screen.dart';
import 'dart:developer'; // For logging
import 'dart:io'; // For File class
import 'package:image_picker/image_picker.dart';

class NewItemScreen extends StatefulWidget {
  @override
  _NewItemScreenState createState() => _NewItemScreenState();
}

// Create list of ItemModels which cosen move to second window where wwe will define new item by model attributes with model_id

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  String _name = ''; // Item name
  String _description = ''; // Item description
  String _imageUrl = ''; // Item image URL
  File? _image; // For selected image

  final List<dynamic> _items = []; // List to hold items
  bool _isLoading = true; // Loading state
  String? _errorMessage; // Error message

  @override
  void initState() {
    super.initState();
    _fetchItems(); // Fetch items when the screen is initialized
  }

  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Add New Item 1/2'),
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator()) // Show loading indicator
        : _errorMessage != null
            ? Center(child: Text('Error: $_errorMessage')) // Show error message
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'What do you want to add to your collection?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];

                        return ListTile(
                          title: Text(item['model_name'] ?? 'Unnamed Item'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NewItemSecondScreen(item: item),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
  );
}

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Store the selected image
      });
    }
  }

  Future<void> _fetchItems() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser; // Get the logged-in user
      if (user != null) {
        // Fetch items from the database
        final response =
            await Supabase.instance.client.from('ItemModels').select('*');
        // .eq('user_id', user.id);

        log('ItemModels: ${response}'); // Log the response data

        // Check for errors in the response
        if (response.error != null) {
          setState(() {
            _errorMessage = response.error!.message; // Set error message if any
            _isLoading = false;
          });
        } else {
          // The data is now accessible as response.data
          setState(() {
            _items.addAll(response); // Add the items to the list
            _isLoading = false; // Update loading state
          });
        }
      } else {
        setState(() {
          _errorMessage = "User not logged in.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Catch any errors
        _isLoading = false;
      });
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

          // If an image is selected, upload it to Supabase storage
          if (_image != null) {
            final fileName =
                '${user.id}-${DateTime.now().millisecondsSinceEpoch}.jpg'; // Unique file name
            final response = await Supabase.instance.client.storage
                .from('images')
                .upload(fileName, _image!);

            if (response.error != null) {
              log('Error uploading image: ${response.error!.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Error uploading image: ${response.error!.message}')),
              );
              return;
            }

            // Get the public URL of the uploaded image
            imageUrl = Supabase.instance.client.storage
                .from('images')
                .getPublicUrl(fileName);
          }

          // Insert the new item into the database
          final response =
              await Supabase.instance.client.from('CollectorItems').insert({
            'user_id': user.id, // Associate the item with the user
            'name': _name,
            'description': _description,
            'image_url': imageUrl, // Use uploaded image URL
          });

          if (response.error != null) {
            log('Error inserting item: ${response.error!.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error adding item: ${response.error!.message}')),
            );
          } else {
            // Successfully added the item
            Navigator.pop(context); // Go back to the previous screen
          }
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

extension on PostgrestList {
  get error => null;
}

extension on String {
  get error => null;
}
