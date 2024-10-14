import 'package:flutter/material.dart';
import 'package:stack_it/update_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer'; // For logging

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
    _fetchAttributes(); // Fetch item attributes when the screen is initialized
  }

  Future<void> _fetchAttributes() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser; // Get the logged-in user
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

  Future<void> _fetchItem() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser; // Get the logged-in user
      if (user != null) {
        // Fetch items with model names from the database using a JOIN
        final response = await Supabase.instance.client
            .from('CollectorItems')
            .select('*')
            .eq('id', widget.item['id']);
        log('data: ${response}'); // Log the response data

        widget.item['image_url'] = response[0]['image_url'];
        widget.item['image_url'] = response[0]['image_url'];
        widget.item['borrow_to'] = response[0]['borrow_to'];
        widget.item['name'] = response[0]['name'];

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

  Future<void> _deleteItem() async {
    try {
      // Start a transaction to ensure all deletions happen together
      final supabase = Supabase.instance.client;

      final response =
          await supabase.rpc('delete_item_and_attributes', params: {
        'item_id_param': widget.item['id'],
      });

      log(response.toString());

      if (response != null) {
        log('Error deleting item: ${response.error!.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error deleting item: ${response.error!.message}')),
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
    // Push the update screen, passing the current item
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateScreen(item: {
          'id': widget.item['id'],
          'name': widget.item['name'],
          'description': widget.item['description'],
          'borrow_to': widget.item['borrow_to'],
          'image_url': widget.item['image_url'],
          'attributes': _items, // Pass the attributes
        }),
      ),
    ).whenComplete(() async {
      _items.clear();

      await _fetchAttributes(); // Ensure this completes first

      await _fetchItem(); // Runs after _fetchAttributes is done
    });
  }

  @override
  Widget build(BuildContext context) {
    log(widget.item.toString());
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
              widget.item['image_url'] != null &&
                      widget.item['image_url'].isNotEmpty
                  ? Image.network(widget.item['image_url'],
                      fit: BoxFit.cover) // Display image
                  : SizedBox(
                      height: 200,
                      child: Center(child: Text('No Image Available'))),
              SizedBox(height: 16),
              widget.item['borrow_to'] != null && !widget.item['borrow_to'].isEmpty
                  ? Text(
                      'Borrowed to:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    )
                  : SizedBox(height: 0), // Display image
              widget.item['borrow_to'] != null && !widget.item['borrow_to'].isEmpty
                  ? Text(widget.item['borrow_to'])
                  : SizedBox(height: 0), // Display image
              SizedBox(height: 16),
              // Text(
              //   'Name:',
              //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              // ),
              // SizedBox(height: 4),
              // Text(widget.item['name'] ??
              //     'No description available'), // Display description
              // SizedBox(height: 16),
              // Text(
              //   'Description:',
              //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              // ),
              // SizedBox(height: 4),
              // Text(widget.item['description'] ??
              //     'No description available'), // Display description
              // SizedBox(height: 16),
              Text(
                'Created at:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 4),
              Text(widget.item['created_at'] ??
                  'No date available'), // Display creation date
              SizedBox(height: 16),
              ..._items.map((item) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['attribute_name'] ?? 'Attribute Name',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
