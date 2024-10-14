import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    // Initialize attribute controllers
    _initializeAttributeControllers();
  }

  void _initializeAttributeControllers() {
    _attributes = widget.item['attributes'] ?? [];
    for (var attribute in _attributes) {
      _attributeControllers
          .add(TextEditingController(text: attribute['value']));
    }
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      // Step 1: Update item details in the CollectorItems table
      // log(_borrowerController['text'].toString());
      final itemResponse = await Supabase.instance.client
          .from('CollectorItems') // Change to your actual items table name
          .update({
        'name': _nameController.text.toString(),
        'description': _descriptionController.text.toString(),
        'image_url': _imageUrlController.text.toString(),
        'borrow_to': _borrowerController.text.toString(),
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
      final List<Map<String, dynamic>> attributeUpdates = [];
      // Step 2: Update attributes in the ItemAttributes table
      for (int i = 0; i < _attributes.length; i++) {
        attributeInserts.add({
          'id': _attributes[i]['id'], // Associate the item with the `itemId`
          'value':_attributeControllers[i].text, // Associate the item with the `itemId`
        });
        log(_attributes[i].toString());
      }

      final secondInsertResponse = await Supabase.instance.client
    .from('ItemAttributes')
    .upsert(attributeInserts);


      // for (int i = 0; i < _attributes.length; i++) {
      //   // log('Attributes: $_attributes'); // Log the response data
      //   final attributeID = _attributes[i]['id'];
      //   log('_attributeControllers[i].text');
      //   log(_attributeControllers[i].text);
      //   log(_attributeControllers[i].toString());
      //   log(_attributeControllers[i].toString());
      //   log(_attributes[i].toString());
      //   log('AttributeID: $attributeID');
      //   final updateResponse = await Supabase.instance.client
      //       .from(
      //           'ItemAttributes') // Change to your actual attributes table name
      //       .update({
      //     'value': _attributeControllers[i].text.toString(),
      //   }).eq('id', attributeID); // Don't forget to call execute()
      //   // .eq('attribute_name', attribute['attribute_name']); // Don't forget to call execute()

      //   if (updateResponse.error != null) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //           content: Text(
      //               'Error updating attribute: ${updateResponse.error!.message}')),
      //     );
      //     return; // Exit if there's an error
      //   }
      // }

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
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align items to the start
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(labelText: 'Image URL'),
              ),
              TextFormField(
                controller: _borrowerController, // Add borrow_to input field
                decoration: InputDecoration(labelText: 'Borrower'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter borrow_to\'s name';
                  }
                  return null;
                },
              ),
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
              ElevatedButton(
                onPressed: _updateItem,
                child: Text('Update Item'),
              ),
            ],
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
