import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import 'settings_screen.dart';
import 'add_entry_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

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
      body: StreamBuilder<List<TypedResult>>(
        stream: database.select(database.products).join([
          leftOuterJoin(
            database.categories,
            database.categories.id.equalsExp(database.products.categoryId),
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

          if (results.isEmpty) {
            return const Center(
              child: Text('No products yet. Add some prices!'),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final row = results[index];
              final product = row.readTable(database.products);
              final category = row.readTableOrNull(database.categories);

              return ListTile(
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
                subtitle: Text(category?.name ?? 'No Category'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
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
