import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
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
  bool _showLowestPrice = false; // false=latest, true=lowest

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(databaseProvider);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SearchBar(
            controller: _searchController,
            leading: Icon(Icons.search, color: colorScheme.outline),
            hintText: l10n.searchHint,
            elevation: const WidgetStatePropertyAll(0.5),
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
        // Filter, Sort, and Price Toggle Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(l10n.categories),
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
              // Sort Toggle
              IconButton(
                icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                ),
                tooltip: _isAscending ? 'Sort Ascending' : 'Sort Descending',
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending;
                  });
                },
              ),
              const SizedBox(width: 4),
              // Price Display Toggle
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(
                      l10n.latestPrice,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(
                      l10n.lowestPrice,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
                selected: {_showLowestPrice},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _showLowestPrice = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TypedResult>>(
            stream: database.select(database.products).join([
              leftOuterJoin(
                database.categories,
                database.categories.id.equalsExp(database.products.categoryId),
              ),
            ]).watch(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(l10n.error(snapshot.error.toString())),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final results = snapshot.data!;
              var filteredResults = results.where((row) {
                final product = row.readTable(database.products);
                final category = row.readTableOrNull(database.categories);
                final query = _searchQuery.toLowerCase();

                final matchesSearch =
                    product.name.toLowerCase().contains(query) ||
                    (category?.name.toLowerCase().contains(query) ?? false);

                final matchesCategory =
                    _selectedCategoryId == null ||
                    product.categoryId == _selectedCategoryId;

                return matchesSearch && matchesCategory;
              }).toList();

              if (filteredResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noProductsFound,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
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

              // Group by Category
              final grouped = <String, List<TypedResult>>{};
              for (var row in filteredResults) {
                final category = row.readTableOrNull(database.categories);
                final categoryName = category?.name ?? 'Uncategorized';
                if (!grouped.containsKey(categoryName)) {
                  grouped[categoryName] = [];
                }
                grouped[categoryName]!.add(row);
              }

              final sortedKeys = grouped.keys.toList();
              sortedKeys.sort((a, b) {
                final comp = a.compareTo(b);
                return _isAscending ? comp : -comp;
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: sortedKeys.length,
                itemBuilder: (context, sectionIndex) {
                  final key = sortedKeys[sectionIndex];
                  final items = grouped[key]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Text(
                          key,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ...items.map((row) {
                        final product = row.readTable(database.products);
                        return _ProductCard(
                          product: product,
                          database: database,
                          showLowest: _showLowestPrice,
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final AppDatabase database;
  final bool showLowest;

  const _ProductCard({
    required this.product,
    required this.database,
    required this.showLowest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: _buildLeading(),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildVolumeLabel(),
        trailing: _PriceDisplay(
          productId: product.id,
          database: database,
          showLowest: showLowest,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeading() {
    if (product.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(product.imagePath!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
        ),
      );
    } else if (product.emoji != null) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Text(product.emoji!, style: const TextStyle(fontSize: 28)),
        ),
      );
    }
    return const SizedBox(
      width: 48,
      height: 48,
      child: Icon(Icons.shopping_bag_outlined, size: 28),
    );
  }

  Widget? _buildVolumeLabel() {
    if (product.volume != null && product.volumeUnit != null) {
      final volStr = product.volume! % 1 == 0
          ? product.volume!.toInt().toString()
          : product.volume.toString();
      return Text(
        '$volStr${product.volumeUnit}',
        style: const TextStyle(fontSize: 12),
      );
    }
    return null;
  }
}

class _PriceDisplay extends StatelessWidget {
  final int productId;
  final AppDatabase database;
  final bool showLowest;

  const _PriceDisplay({
    required this.productId,
    required this.database,
    required this.showLowest,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Price>>(
      stream:
          (database.select(database.prices)
                ..where((t) => t.productId.equals(productId))
                ..orderBy([
                  (t) =>
                      OrderingTerm(expression: t.date, mode: OrderingMode.desc),
                ]))
              .watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('--', style: TextStyle(color: Colors.grey));
        }

        final prices = snapshot.data!;
        final Price displayPrice;
        if (showLowest) {
          displayPrice = prices.reduce((a, b) => a.price <= b.price ? a : b);
        } else {
          displayPrice = prices.first; // already sorted desc by date
        }

        return Text(
          '¥${displayPrice.price}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
