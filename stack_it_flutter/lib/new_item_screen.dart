// lib/new_item_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer'; // For logging

class NewItemScreen extends StatefulWidget {
  @override
  _NewItemScreenState createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  String _name = ''; // Item name
  String _description = ''; // Item description
  String _imageUrl = ''; // Item image URL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the item name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Image URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an image URL';
                  }
                  return null;
                },
                onSaved: (value) {
                  _imageUrl = value!;
                },
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
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Save form data

      try {
        final user = Supabase.instance.client.auth.currentUser; // Get the logged-in user
        if (user != null) {
          // Insert the new item into the database
          final response = await Supabase.instance.client
              .from('CollectorItems')
              .insert({
                'user_id': user.id, // Associate the item with the user
                'name': _name,
                'description': _description,
                'image_url': _imageUrl,
              });

          if (response.error != null) {
            // Handle error if any
            log('Error inserting item: ${response.error!.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding item: ${response.error!.message}')),
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
