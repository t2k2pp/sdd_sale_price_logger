import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';
import '../dialogs/upsert_product_dialog.dart';
import '../dialogs/upsert_shop_dialog.dart';

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
    } else {
      _priceController = TextEditingController();
    }
  }

  Future<void> _loadInitialDataIfEditing() async {
    if (widget.entryToEdit == null) return;
    final db = ref.read(databaseProvider);

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
                          initialValue: _selectedProduct,
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
                      final newProduct = await showUpsertProductDialog(
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
                          initialValue: _selectedShop,
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
                      final newShop = await showUpsertShopDialog(
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

              FilledButton(onPressed: _savePrice, child: Text(l10n.save)),
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
        final updated = widget.entryToEdit!.copyWith(
          productId: _selectedProduct!.id,
          shopId: _selectedShop!.id,
          price: int.parse(_priceController.text),
          isTaxIncluded: _isTaxIncluded,
          date: _selectedDate,
        );
        await database.prices.replaceOne(updated);
      } else {
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
}
