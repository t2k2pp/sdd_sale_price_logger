import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';
import '../dialogs/upsert_shop_dialog.dart';
import '../dialogs/upsert_product_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.categories),
            Tab(text: l10n.shops),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_CategoryList(), _ShopList()],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return StreamBuilder<List<Category>>(
      stream: database.select(database.categories).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!;

        return ListView.builder(
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            final l10n = AppLocalizations.of(context)!;
            if (index == categories.length) {
              return ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.addCategory),
                onTap: () async {
                  await showUpsertCategoryDialog(context, database);
                },
              );
            }
            final category = categories[index];
            return ListTile(
              title: Text(category.name),
              subtitle: Text('${l10n.taxRate}: ${category.taxRate}%'),
              onTap: () async {
                await showUpsertCategoryDialog(
                  context,
                  database,
                  existingCategory: category,
                );
              },
              onLongPress: () async {
                // Check dependencies
                final productsCount =
                    await (database.select(database.products)
                          ..where((t) => t.categoryId.equals(category.id)))
                        .get()
                        .then((l) => l.length);
                // Need to join to count prices via products
                // Or simple query: select count(*) from prices join products on ... where products.category_id = ...
                // Drift approach:
                final priceCountQuery = database.select(database.prices).join([
                  drift.innerJoin(
                    database.products,
                    database.products.id.equalsExp(database.prices.productId),
                  ),
                ])..where(database.products.categoryId.equals(category.id));
                final priceCount = await priceCountQuery.get().then(
                  (l) => l.length,
                );

                if (!context.mounted) return;

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category?'),
                    content: Text(
                      'Deleting this category will delete $productsCount products and $priceCount price records.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Cascade Delete safely
                          await database.transaction(() async {
                            // 1. Delete prices for products in this category
                            // We need IDs of products to delete prices efficiently or use join delete if supported (Drift delete with join is tricky).
                            // Easier: Fetch product IDs first.
                            final products =
                                await (database.select(database.products)
                                      ..where(
                                        (t) => t.categoryId.equals(category.id),
                                      ))
                                    .get();
                            final productIds = products
                                .map((p) => p.id)
                                .toList();

                            if (productIds.isNotEmpty) {
                              await (database.delete(
                                    database.prices,
                                  )..where((t) => t.productId.isIn(productIds)))
                                  .go();
                            }
                            // 2. Delete products
                            await (database.delete(database.products)..where(
                                  (t) => t.categoryId.equals(category.id),
                                ))
                                .go();
                            // 3. Delete category
                            await (database.delete(
                              database.categories,
                            )..where((t) => t.id.equals(category.id))).go();
                          });
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ShopList extends ConsumerWidget {
  const _ShopList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return StreamBuilder<List<Shop>>(
      stream: database.select(database.shops).watch(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final shops = snapshot.data!;

        return ListView.builder(
          itemCount: shops.length + 1,
          itemBuilder: (context, index) {
            final l10n = AppLocalizations.of(context)!;
            if (index == shops.length) {
              return ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.addShop),
                onTap: () async {
                  await showUpsertShopDialog(context, database);
                },
              );
            }
            final shop = shops[index];
            return ListTile(
              title: Text(shop.name),
              onTap: () async {
                await showUpsertShopDialog(
                  context,
                  database,
                  existingShop: shop,
                );
              },
              onLongPress: () async {
                final count =
                    await (database.select(database.prices)
                          ..where((t) => t.shopId.equals(shop.id)))
                        .get()
                        .then((l) => l.length);

                if (!context.mounted) return;

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Shop?'),
                    content: Text(
                      'Deleting this shop will delete $count price records.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          await database.transaction(() async {
                            await (database.delete(
                              database.prices,
                            )..where((t) => t.shopId.equals(shop.id))).go();
                            await (database.delete(
                              database.shops,
                            )..where((t) => t.id.equals(shop.id))).go();
                          });
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
