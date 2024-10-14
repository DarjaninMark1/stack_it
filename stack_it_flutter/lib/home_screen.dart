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
  String? _selectedModelId; // For filtering by model
  bool _showBorrowedOnly = false; // For filtering by "borrowed to" status
  List<dynamic> _filteredItems = [];
  List<dynamic> _models = []; // For storing available models

  @override
  void initState() {
    super.initState();
    _fetchItems(); // Fetch items when the screen is initialized
    _fetchModels();
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

        setState(() {
          _items.addAll(response); // Add the items to the list
          _filteredItems.addAll(response); // Add the items to the filtered list
          _isLoading = false; // Update loading state
        });
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

  Future<void> _fetchModels() async {
    try {
      // Fetch all available models from ItemModels table
      final response = await Supabase.instance.client
          .from('ItemModels')
          .select('id, model_name');

      setState(() {
        _models = response;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _dialogFilter(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Items'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize:
                    MainAxisSize.min, // Ensure the column takes minimal height
                children: [
                  // Dropdown for model selection
                  DropdownButton<String>(
                    hint: const Text('Filter by Model'),
                    value: _selectedModelId,
                    isExpanded: true, // Ensure the dropdown takes up full width
                    items: _models.map<DropdownMenuItem<String>>((model) {
                      return DropdownMenuItem<String>(
                        value: model['id'].toString(),
                        child: Text(model['model_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedModelId = value;
                      });
                    },
                  ),
                  // Checkbox for "borrowed to" filtering
                  CheckboxListTile(
                    title: const Text("Show Borrowed Only"),
                    value: _showBorrowedOnly,
                    onChanged: (bool? value) {
                      setState(() {
                        _showBorrowedOnly = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            // Reset Filters Button
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Reset Filters'),
              onPressed: () {
                setState(() {
                  _selectedModelId = null; // Clear model filter
                  _showBorrowedOnly = false; // Clear borrowed status filter
                  _filteredItems = List.from(_items); // Reset to all items
                });
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Apply'),
              onPressed: () {
                _applyFilters(); // Apply filters
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Apply filters based on selected model and borrowed status
  void _applyFilters() {
    log(_selectedModelId.toString());
    log('message');
    log(_filteredItems.toString());
    log(_items.toString());
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesModel =
            _selectedModelId == null || item['model_id'].toString() == _selectedModelId;
        final matchesBorrowed = !_showBorrowedOnly ||
            (item['borrow_to'] != null && item['borrow_to'].isNotEmpty);
        return matchesModel && matchesBorrowed;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Collector Items'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_alt),
            onPressed: () => _dialogFilter(context), // Open filter dialog
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : _errorMessage != null
              ? Center(
                  child: Text('Error: $_errorMessage')) // Show error message
              : ListView.builder(
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return ListTile(
                      leading: item['image_url'] != null &&
                              item['image_url'].isNotEmpty
                          ? Image.network(item['image_url'],
                              fit: BoxFit.fitHeight)
                          : Text('No Image Available'),
                      title: Text(item['name'] ?? 'Unnamed Item'),
                      subtitle: Text(
                          item['ItemModels']['model_name'] ?? 'No model name'),
                      trailing: Text(item['borrow_to'] ?? ''),
                      onTap: () {
                        // Navigate to DetailScreen and pass the selected item
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(item: item),
                          ),
                        ).whenComplete(() {
                          _items.clear();
                          _filteredItems.clear();
                          _fetchItems(); // Refresh items after returning from detail screen
                        });
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to add a new item
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
