import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../data/database.dart';
import '../../providers/database_provider.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  Shop? _selectedShop;
  final _priceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Price')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Product Selection
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Product>>(
                      stream: database.select(database.products).watch(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final products = snapshot.data!;
                        return DropdownButtonFormField<Product>(
                          decoration: const InputDecoration(
                            labelText: 'Product',
                          ),
                          value: _selectedProduct,
                          items: products.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text(product.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProduct = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a product' : null,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddProductDialog(context, database),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Shop Selection
              Row(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Shop>>(
                      stream: database.select(database.shops).watch(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final shops = snapshot.data!;
                        return DropdownButtonFormField<Shop>(
                          decoration: const InputDecoration(labelText: 'Shop'),
                          value: _selectedShop,
                          items: shops.map((shop) {
                            return DropdownMenuItem(
                              value: shop,
                              child: Text(shop.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedShop = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a shop' : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price Input
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  suffixText: '¥',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Selection
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(onPressed: _savePrice, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePrice() async {
    if (_formKey.currentState!.validate()) {
      final database = ref.read(databaseProvider);
      await database
          .into(database.prices)
          .insert(
            PricesCompanion(
              productId: drift.Value(_selectedProduct!.id),
              shopId: drift.Value(_selectedShop!.id),
              price: drift.Value(int.parse(_priceController.text)),
              date: drift.Value(_selectedDate),
            ),
          );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showAddProductDialog(
    BuildContext context,
    AppDatabase database,
  ) async {
    final nameController = TextEditingController();
    Category? selectedCategory;
    String? imagePath;
    final ImagePicker picker = ImagePicker();

    // Need a stateful builder for the dialog to handle dropdown and image changes
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Category>>(
                      stream: database.select(database.categories).watch(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        return DropdownButtonFormField<Category>(
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          value: selectedCategory,
                          items: snapshot.data!.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.name),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => selectedCategory = v),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (imagePath != null)
                          Image.file(
                            File(imagePath!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        else
                          const Icon(Icons.image, size: 50, color: Colors.grey),
                        TextButton.icon(
                          onPressed: () async {
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                            );
                            if (image != null) {
                              // Save to local storage
                              final directory =
                                  await getApplicationDocumentsDirectory();
                              final name = p.basename(image.path);
                              final savedImage = await File(
                                image.path,
                              ).copy('${directory.path}/$name');
                              setState(() {
                                imagePath = savedImage.path;
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Photo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        selectedCategory != null) {
                      await database
                          .into(database.products)
                          .insert(
                            ProductsCompanion(
                              name: drift.Value(nameController.text),
                              categoryId: drift.Value(selectedCategory!.id),
                              imagePath: drift.Value(imagePath),
                            ),
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
