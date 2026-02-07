import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../providers/database_provider.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';

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
                onTap: () => _showAddDialog(context, ref),
              );
            }
            final category = categories[index];
            return ListTile(title: Text(category.name));
          },
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    double taxRate = 10.0;

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
                    autofocus: true,
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
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      final database = ref.read(databaseProvider);
                      database
                          .into(database.categories)
                          .insert(
                            CategoriesCompanion(
                              name: drift.Value(controller.text),
                              taxRate: drift.Value(taxRate),
                            ),
                          );
                      Navigator.pop(context);
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
                onTap: () => _showAddDialog(context, ref),
              );
            }
            final shop = shops[index];
            return ListTile(title: Text(shop.name));
          },
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.addShop),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.name),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final database = ref.read(databaseProvider);
                  database
                      .into(database.shops)
                      .insert(
                        ShopsCompanion(name: drift.Value(controller.text)),
                      );
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
  }
}
