// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer'; // For logging

// Import the DetailScreen
import 'detail_screen.dart'; // Make sure to create this file
import 'new_item_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<dynamic> _items = []; // List to hold items
  bool _isLoading = true; // Loading state
  String? _errorMessage; // Error message

  @override
  void initState() {
    super.initState();
    _fetchItems(); // Fetch items when the screen is initialized
  }

  Future<void> _fetchItems() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser; // Get the logged-in user
      if (user != null) {
        // Fetch items with model names from the database using a JOIN
        final response = await Supabase.instance.client
            .from('CollectorItems')
            .select('*, ItemModels(model_name)')
            .eq('user_id', user.id);

        log('data: ${response}'); // Log the response data

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Collector Items'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : _errorMessage != null
              ? Center(
                  child: Text('Error: $_errorMessage')) // Show error message
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    log(item.toString());
                    log(item['model_name'].toString());
                    return ListTile(
                      leading: Image.network(item['image_url'],
                          fit: BoxFit.fitHeight),
                      title: Text(item['name'] ??
                          'Unnamed Item'), // Replace with your item name field
                      subtitle: Text(item['ItemModels']['model_name'] ?? 'No model name'),
                      trailing: Text(item['borrow_to'] ?? ''),
                      onTap: () {
                        // Navigate to DetailScreen and pass the selected item
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to add a new item
          // You can navigate to a new screen or show a dialog here
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NewItemScreen(), // Ensure this screen is created
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add New Item', // Tooltip text
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;
}
