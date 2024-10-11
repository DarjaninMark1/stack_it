import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:developer'; // For logging


class DetailScreen extends StatefulWidget {
  final dynamic item;

  const DetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {

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
      final user = Supabase.instance.client.auth.currentUser; // Get the logged-in user
      if (user != null) {
        // Fetch items from the database
        final response = await Supabase.instance.client
            .from('ItemAttributes')
            .select('*');
            // .eq('item_id', widget.item['id']);

        log('madafaka data: ${response}'); // Log the response data

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
        title: Text(widget.item['item_name'] ?? 'Item Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the thumbnail image
            widget.item['image_url'] != null
                ? Image.network(widget.item['image_url'], fit: BoxFit.cover) // Display image
                : SizedBox(height: 200, child: Center(child: Text('No Image Available'))),
            SizedBox(height: 16),
            Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 4),
            Text(widget.item['description'] ?? 'No description available'), // Display description
            SizedBox(height: 16),
            Text(
              'Created at:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 4),
            Text(widget.item['created_at'] ?? 'No date available'), // Display creation date
          ],
        ),
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;
}

