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
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;

class AddEntryScreen extends ConsumerStatefulWidget {
  final Product? initialProduct;
  final Price? entryToEdit;

  const AddEntryScreen({super.key, this.initialProduct, this.entryToEdit});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  Shop? _selectedShop;
  late TextEditingController _priceController;
  bool _isTaxIncluded = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.initialProduct;
    final entry = widget.entryToEdit;
    if (entry != null) {
      _priceController = TextEditingController(text: entry.price.toString());
      _isTaxIncluded = entry.isTaxIncluded;
      _selectedDate = entry.date;
      // We need to fetch Shop and Product if not set?
      // Product might be passed in initialProduct, but if editing from History list...
      // The history list has the product.
      // We need to set _selectedShop and _selectedProduct based on IDs.
      // But _selectedShop needs the Shop object.
      // Unlike String, we need the object from the list to make Dropdown work well
      // (equality check).
      // However, we don't have the list here yet (it's in the stream).
      // We can use `useEffect` or just let the StreamBuilder handle it?
      // No, we need to set the initial value.
      // Better: Fetch the explicit Shop/Product in initState?
      // Or: The Dropdown value `_selectedShop` can be null initially,
      // but we need to match it when data arrives.
      // But `_selectedShop` holds the object.
      // Strategy: In build, if `_selectedShop` is null AND `entryToEdit` is not null,
      // try to find the shop in the snapshot and set it?
      // That's risky (setState during build).
      // Better: Load the specific Shop/Product in initState async (or just assume we have them if passed?)
      // We only have IDs in `Price`.
      // Let's rely on `ref.read` in initState? No, should replace `initState` logic or use `FutureBuilder`?
      // Simpler: The caller (ProductDetailScreen) likely has the Product and Shop objects!
      // Pass them in!
    } else {
      _priceController = TextEditingController();
    }
  }

  // Helper to load initial data if editing
  Future<void> _loadInitialDataIfEditing() async {
    if (widget.entryToEdit == null) return;
    final db = ref.read(databaseProvider);

    // If shop not set, fetch it
    if (_selectedShop == null) {
      final shop =
          await (db.select(db.shops)
                ..where((t) => t.id.equals(widget.entryToEdit!.shopId)))
              .getSingleOrNull();
      if (shop != null && mounted) {
        setState(() {
          _selectedShop = shop;
        });
      }
    }
    // If product not set
    if (_selectedProduct == null) {
      final product =
          await (db.select(db.products)
                ..where((t) => t.id.equals(widget.entryToEdit!.productId)))
              .getSingleOrNull();
      if (product != null && mounted) {
        setState(() {
          _selectedProduct = product;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.entryToEdit != null) {
      _loadInitialDataIfEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addPrice)),
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
                        var products = snapshot.data!;
                        if (_selectedProduct != null &&
                            !products.contains(_selectedProduct)) {
                          products = [...products, _selectedProduct!];
                        }
                        return DropdownButtonFormField<Product>(
                          decoration: InputDecoration(
                            labelText: l10n.productName,
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
                          validator: (value) => value == null
                              ? l10n.error('Please select a product')
                              : null,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final newProduct = await _showAddProductDialog(
                        context,
                        database,
                      );
                      if (newProduct != null) {
                        setState(() {
                          _selectedProduct = newProduct;
                        });
                      }
                    },
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
                        var shops = snapshot.data!;
                        if (_selectedShop != null &&
                            !shops.contains(_selectedShop)) {
                          shops = [...shops, _selectedShop!];
                        }
                        return DropdownButtonFormField<Shop>(
                          decoration: InputDecoration(labelText: l10n.shop),
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
                          validator: (value) => value == null
                              ? l10n.error('Please select a shop')
                              : null,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final newShop = await _showAddShopDialog(
                        context,
                        database,
                      );
                      if (newShop != null) {
                        setState(() {
                          _selectedShop = newShop;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: l10n.price,
                        suffixText: '¥',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.error('Please enter a price');
                        }
                        if (int.tryParse(value) == null) {
                          return l10n.error('Please enter a valid number');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ToggleButtons(
                    isSelected: [_isTaxIncluded, !_isTaxIncluded],
                    onPressed: (index) {
                      setState(() {
                        _isTaxIncluded = index == 0;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(l10n.taxIncluded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(l10n.taxExcluded),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Selection
              ListTile(
                title: Text(l10n.date),
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

              ElevatedButton(onPressed: _savePrice, child: Text(l10n.save)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePrice() async {
    if (_formKey.currentState!.validate()) {
      final database = ref.read(databaseProvider);

      if (widget.entryToEdit != null) {
        // Update
        final updated = widget.entryToEdit!.copyWith(
          productId: _selectedProduct!.id,
          shopId: _selectedShop!.id,
          price: int.parse(_priceController.text),
          isTaxIncluded: _isTaxIncluded,
          date: _selectedDate,
        );
        await database.prices.replaceOne(updated);
      } else {
        // Insert
        await database
            .into(database.prices)
            .insert(
              PricesCompanion(
                productId: drift.Value(_selectedProduct!.id),
                shopId: drift.Value(_selectedShop!.id),
                price: drift.Value(int.parse(_priceController.text)),
                isTaxIncluded: drift.Value(_isTaxIncluded),
                date: drift.Value(_selectedDate),
              ),
            );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<Product?> _showAddProductDialog(
    BuildContext context,
    AppDatabase database,
  ) async {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();
    Category? selectedCategory;
    String? imagePath;
    final ImagePicker picker = ImagePicker();
    Product? createdProduct;

    // Need a stateful builder for the dialog to handle dropdown and image changes
    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.newProduct),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.name),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<Category>>(
                            stream: database
                                .select(database.categories)
                                .watch(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }
                              var categories = snapshot.data!;
                              if (selectedCategory != null &&
                                  !categories.contains(selectedCategory)) {
                                categories = [...categories, selectedCategory!];
                              }
                              return DropdownButtonFormField<Category>(
                                decoration: InputDecoration(
                                  labelText: l10n.category,
                                ),
                                value: selectedCategory,
                                items: categories.map((c) {
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
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final newCategory = await _showAddCategoryDialog(
                              context,
                              database,
                            );
                            if (newCategory != null) {
                              setState(() {
                                selectedCategory = newCategory;
                              });
                            }
                          },
                        ),
                      ],
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
                          label: Text(l10n.photo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '${l10n.emoji}: ',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return emoji.EmojiPicker(
                                  onEmojiSelected:
                                      (
                                        emoji.Category? category,
                                        emoji.Emoji emojiStr,
                                      ) {
                                        emojiController.text = emojiStr.emoji;
                                        Navigator.pop(context);
                                      },
                                  config: emoji.Config(
                                    height: 256,
                                    checkPlatformCompatibility: true,
                                    viewOrderConfig:
                                        const emoji.ViewOrderConfig(),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: ValueListenableBuilder(
                                valueListenable: emojiController,
                                builder: (context, value, child) {
                                  return Text(
                                    value.text.isEmpty ? '😀' : value.text,
                                    style: const TextStyle(fontSize: 24),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (emojiController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              emojiController.clear();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        selectedCategory != null) {
                      createdProduct = await database
                          .into(database.products)
                          .insertReturning(
                            ProductsCompanion(
                              name: drift.Value(nameController.text),
                              categoryId: drift.Value(selectedCategory!.id),
                              imagePath: drift.Value(imagePath),
                              emoji: drift.Value(
                                emojiController.text.isEmpty
                                    ? null
                                    : emojiController.text,
                              ),
                            ),
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
    return createdProduct;
  }

  Future<Shop?> _showAddShopDialog(
    BuildContext context,
    AppDatabase database,
  ) async {
    final controller = TextEditingController();
    Shop? createdShop;
    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.addShop),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  createdShop = await database
                      .into(database.shops)
                      .insertReturning(
                        ShopsCompanion(name: drift.Value(controller.text)),
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
    return createdShop;
  }

  Future<Category?> _showAddCategoryDialog(
    BuildContext context,
    AppDatabase database,
  ) async {
    final controller = TextEditingController();
    double taxRate = 10.0;
    Category? createdCategory;
    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.addCategory),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: l10n.name),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: taxRate.toString(),
                    decoration: InputDecoration(
                      labelText: l10n.taxRate,
                      suffixText: '%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null) {
                        setState(() => taxRate = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    if (controller.text.isNotEmpty) {
                      createdCategory = await database
                          .into(database.categories)
                          .insertReturning(
                            CategoriesCompanion(
                              name: drift.Value(controller.text),
                              taxRate: drift.Value(taxRate),
                            ),
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
    return createdCategory;
  }
}
