import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'settings_screen.dart';
import 'add_entry_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _isAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              controller: _searchController,
              leading: const Icon(Icons.search),
              hintText: l10n.searchHint,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
              ],
            ),
          ),
          // Filter and Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: StreamBuilder<List<Category>>(
                    stream: database.select(database.categories).watch(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final categories = snapshot.data!;
                      return DropdownButton<int?>(
                        isExpanded: true,
                        value: _selectedCategoryId,
                        hint: Text(l10n.categories),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n.categories), // "All" effectively
                          ),
                          ...categories.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Sort Toggle
                IconButton(
                  icon: Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  ),
                  tooltip: _isAscending ? 'Sort Ascending' : 'Sort Descending',
                  onPressed: () {
                    setState(() {
                      _isAscending = !_isAscending;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TypedResult>>(
              stream: database.select(database.products).join([
                leftOuterJoin(
                  database.categories,
                  database.categories.id.equalsExp(
                    database.products.categoryId,
                  ),
                ),
              ]).watch(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = snapshot.data!;
                var filteredResults = results.where((row) {
                  final product = row.readTable(database.products);
                  final category = row.readTableOrNull(database.categories);
                  final query = _searchQuery.toLowerCase();

                  // Search Filter
                  final matchesSearch =
                      product.name.toLowerCase().contains(query) ||
                      (category?.name.toLowerCase().contains(query) ?? false);

                  // Category Filter
                  final matchesCategory =
                      _selectedCategoryId == null ||
                      product.categoryId == _selectedCategoryId;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredResults.isEmpty) {
                  return Center(child: Text(l10n.noProductsFound));
                }

                // Sort
                filteredResults.sort((a, b) {
                  final productA = a.readTable(database.products);
                  final productB = b.readTable(database.products);
                  final comparison = productA.name.toLowerCase().compareTo(
                    productB.name.toLowerCase(),
                  );
                  return _isAscending ? comparison : -comparison;
                });

                // Group by Category (if not filtered by single category, or even if it is)
                final grouped = <String, List<TypedResult>>{};
                for (var row in filteredResults) {
                  final category = row.readTableOrNull(database.categories);
                  final categoryName = category?.name ?? 'Uncategorized';
                  if (!grouped.containsKey(categoryName)) {
                    grouped[categoryName] = [];
                  }
                  grouped[categoryName]!.add(row);
                }

                // Flatten list
                final flattenList = <Widget>[];
                // Sort categories logic: If we sort products by name,
                // generally we still group by category.
                // The requirements said "Sort by Name Asc/Desc".
                // If grouped, sorting products globally might break groups or sort groups?
                // Usually "Sort by Name" implies ignoring groups or sorting groups by name then products by name.
                // However, the "Grouping" feature was a specific request.
                // Let's keep grouping, and sort Categories alphabetically, and products within groups by Name.
                // Wait, if "Ascending" is toggled, maybe we reverse Category order too?
                // Let's stick to: Sort Categories A-Z (or Z-A), then Products A-Z (or Z-A).

                final sortedKeys = grouped.keys.toList();
                sortedKeys.sort((a, b) {
                  final comp = a.compareTo(b);
                  return _isAscending ? comp : -comp;
                });

                for (var key in sortedKeys) {
                  flattenList.add(
                    Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      width: double.infinity,
                      child: Text(
                        key,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                  // Products are already sorted by name above, but let's re-ensure list order
                  // Actually the above sort was global. Now we are splitting into buckets.
                  // The buckets need to be sorted.
                  // Groups are already populated from the global list? No, `grouped` is a map.
                  // The insertion order into the list depends on the loop over `filteredResults`.
                  // If we use `grouped[key]!.add(row)`, the list `grouped[key]` preserves insertion order.
                  // So yes, products inside are sorted by Name.

                  for (var row in grouped[key]!) {
                    final product = row.readTable(database.products);
                    flattenList.add(
                      ListTile(
                        leading: product.imagePath != null
                            ? Image.file(
                                File(product.imagePath!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                              )
                            : product.emoji != null
                            ? SizedBox(
                                width: 50,
                                height: 50,
                                child: Center(
                                  child: Text(
                                    product.emoji!,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                ),
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(product.name),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      ),
                    );
                  }
                }

                return ListView(children: flattenList);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEntryScreen()),
          );
        },
        tooltip: 'Add Price',
        child: const Icon(Icons.add),
      ),
    );
  }
}
