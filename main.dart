// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EztVeddMeg', // Application title
      theme: ThemeData.light(), // Light theme for the application
      darkTheme: ThemeData.dark(), // Dark theme for the application
      themeMode: ThemeMode.system, // Theme mode set to system default
      home: const ShoppingListScreen(), // Home screen of the application
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ShoppingListScreenState createState() => ShoppingListScreenState();
}

class ShoppingListScreenState extends State<ShoppingListScreen> {
  List<Map<String, dynamic>> _shoppingItems = []; // List of shopping items

  @override
  void initState() {
    super.initState();
    _getShoppingList(); // Fetch shopping list on page initialization
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _getShoppingList(); // Periodically refresh the shopping list
    });
  }

  // Function to fetch the shopping list from the API
  Future<void> _getShoppingList() async {
    const String apiUrl = 'http://lopert.ddns.net:3000/mylist';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _shoppingItems = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception(
            'Nem sikerült betölteni a bevásárlólistát'); // Failed to load the shopping list
      }
    } catch (error) {
      print(
          'Hiba a bevásárlólista betöltésekor: $error'); // Error loading the shopping list
    }
  }

  // Function to add an item to the shopping list
  Future<void> _addItem(String name) async {
    const String apiUrl = 'http://lopert.ddns.net:3000/additem';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Hozzáadott tétel: ${data['name']}'); // Added item
        _getShoppingList();
      } else {
        throw Exception('Sikertelen tétel hozzáadása'); // Failed to add item
      }
    } catch (error) {
      print('Hiba az elem hozzáadásakor: $error'); // Error adding item
    }
  }

  // Function to update an item in the shopping list
  Future<void> _updateItem(String id, String name) async {
    final String apiUrl = 'http://lopert.ddns.net:3000/updateitem/$id';

    try {
      final TextEditingController nameController =
          TextEditingController(text: name);
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Tétel nevének szerkesztése'), // Edit item name
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  hintText: 'Új tétel neve'), // New item name
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Mégsem'), // Cancel
              ),
              TextButton(
                onPressed: () async {
                  final String newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    final response = await http.put(
                      Uri.parse(apiUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({'name': newName}),
                    );
                    if (response.statusCode == 200) {
                      print('Frissített tétel: $newName'); // Updated item
                      _getShoppingList();
                    } else {
                      throw Exception(
                          'A tétel frissítése sikertelen'); // Failed to update item
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Mentés'), // Save
              ),
            ],
          );
        },
      );
    } catch (error) {
      print('Hiba az elem frissítésekor: $error'); // Error updating item
    }
  }

  // Function to delete an item from the shopping list
  Future<void> _deleteItem(String id) async {
    final String apiUrl = 'http://lopert.ddns.net:3000/deleteitem/$id';

    try {
      final response = await http.delete(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        print('A tétel törölve'); // Item deleted
        _getShoppingList();
      } else {
        throw Exception(
            'Nem sikerült törölni a tételt'); // Failed to delete item
      }
    } catch (error) {
      print('Hiba az elem törlésekor: $error'); // Error deleting item
    }
  }

  // Function to add a product to the shopping list
  Future<void> _addProduct(String name, String barcode) async {
    const String apiUrl = 'http://lopert.ddns.net:3000/addproduct';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'barcode': barcode}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Hozzáadott termék: ${data['productName']}'); // Added product
      } else {
        throw Exception(
            'Termék hozzáadása sikertelen'); // Failed to add product
      }
    } catch (error) {
      print('Hiba a termék hozzáadásakor: $error'); // Error adding product
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bevásárlólista'), // Shopping list
      ),
      body: ListView.builder(
        itemCount: _shoppingItems.length,
        itemBuilder: (context, index) {
          final item = _shoppingItems[index];
          return ListTile(
            title: Text(item['name']),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteItem(item['id'].toString()),
            ),
            onTap: () => _updateItem(item['id'].toString(), item['name']),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final TextEditingController nameController =
                      TextEditingController();
                  return AlertDialog(
                    title: const Text('Tétel hozzáadása'), // Add item
                    content: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          hintText: 'Tétel neve'), // Item name
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Mégsem'), // Cancel
                      ),
                      TextButton(
                        onPressed: () {
                          final String name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            _addItem(name);
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('Hozzáadás'), // Add
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final TextEditingController nameController =
                      TextEditingController();
                  final TextEditingController barcodeController =
                      TextEditingController();
                  return AlertDialog(
                    title: const Text('Termék hozzáadása'), // Add product
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                              hintText: 'Termék neve'), // Product name
                        ),
                        TextField(
                          controller: barcodeController,
                          decoration: const InputDecoration(
                              hintText: 'Termék vonalkódja'), // Product barcode
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Mégsem'), // Cancel
                      ),
                      TextButton(
                        onPressed: () {
                          final String name = nameController.text.trim();
                          final String barcode = barcodeController.text.trim();
                          if (name.isNotEmpty && barcode.isNotEmpty) {
                            _addProduct(name, barcode);
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('Hozzáadás'), // Add
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(Icons.shopping_bag),
          ),
        ],
      ),
    );
  }
}
