import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer'; // For logging
import 'new_item_second_screen.dart';

class DetailScreen extends StatefulWidget {
  final dynamic item;

  const DetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final List<dynamic> _items = []; // List to hold attributes
  bool _isLoading = true; // Loading state
  String? _errorMessage; // Error message

  @override
  void initState() {
    super.initState();
    _fetchItems(); // Fetch item attributes when the screen is initialized
  }

  Future<void> _fetchItems() async {
    try {
      final user = Supabase.instance.client.auth.currentUser; // Get the logged-in user
      if (user != null) {
        // Fetch attributes for the item from the database
        final response = await Supabase.instance.client
            .from('ItemAttributes')
            .select('*')
            .eq('item_id', widget.item['id']);

        log('Attributes: $response'); // Log the response data

        if (response.error != null) {
          setState(() {
            _errorMessage = response.error!.message; // Set error message
            _isLoading = false;
          });
        } else {
          setState(() {
            _items.addAll(response); // Add the attributes to the list
            _isLoading = false;
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

  Future<void> _deleteItem() async {
  try {
    // Start a transaction to ensure all deletions happen together
    final supabase = Supabase.instance.client;
    
    final response = await supabase.rpc('delete_item_and_attributes', params: {
      'item_id_param': widget.item['id'],
    });

    log(response.toString());

    if (response != null) {
      log('Error deleting item: ${response.error!.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: ${response.error!.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item and related data deleted successfully')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  } catch (e) {
    log('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}


  void _navigateToUpdateScreen() {
    // Assuming you have a screen for updating items, push to that screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewItemSecondScreen(item: widget.item), // Replace with your update screen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item['item_name'] ?? 'Item Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _navigateToUpdateScreen, // Navigate to update screen
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteItem, // Delete item
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the item image
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
              SizedBox(height: 16),
              ..._items.map((item) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['attribute_name'] ?? 'Attribute Name',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 4),
                    Text(item['value'] ?? 'No value available'),
                    SizedBox(height: 16), // Display item attributes
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _deleteItem,
        backgroundColor: Colors.red,
        child: Icon(Icons.delete),
      ),
    );
  }
}

extension on PostgrestList {
  get error => null;
}
