import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import '../../data/database.dart';
import 'package:sdd_sale_price_logger/l10n/app_localizations.dart';

Future<Category?> showUpsertCategoryDialog(
  BuildContext context,
  AppDatabase database, {
  Category? existingCategory,
}) async {
  final controller = TextEditingController(text: existingCategory?.name);
  double taxRate = existingCategory?.taxRate ?? 10.0;
  Category? result;

  await showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final isEdit = existingCategory != null;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Category' : l10n.addCategory),
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
                    if (isEdit) {
                      final updated = existingCategory.copyWith(
                        name: controller.text,
                        taxRate: taxRate,
                      );
                      await database.categories.replaceOne(updated);
                      result = updated;
                    } else {
                      result = await database
                          .into(database.categories)
                          .insertReturning(
                            CategoriesCompanion(
                              name: drift.Value(controller.text),
                              taxRate: drift.Value(taxRate),
                            ),
                          );
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(isEdit ? l10n.save : l10n.add),
              ),
            ],
          );
        },
      );
    },
  );
  return result;
}

Future<Product?> showUpsertProductDialog(
  BuildContext context,
  AppDatabase database, {
  Product? existingProduct,
}) async {
  final nameController = TextEditingController(text: existingProduct?.name);
  final emojiController = TextEditingController(text: existingProduct?.emoji);
  Category? selectedCategory;
  String? imagePath = existingProduct?.imagePath;
  final ImagePicker picker = ImagePicker();
  Product? result;

  // If editing, fetch the current category
  if (existingProduct != null) {
    selectedCategory = await (database.select(
      database.categories,
    )..where((t) => t.id.equals(existingProduct.categoryId))).getSingleOrNull();
  }

  if (!context.mounted) return null;

  await showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final isEdit = existingProduct != null;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              isEdit ? 'Edit Product' : l10n.newProduct,
            ), // Need l10n for Edit
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
                          stream: database.select(database.categories).watch(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            var categories = snapshot.data!;
                            // Ensure selected category is in list (incase of deletion/etc logic, though here it's stream)
                            if (selectedCategory != null &&
                                !categories
                                    .map((e) => e.id)
                                    .contains(selectedCategory!.id)) {
                              // If locally selected category is not in stream (e.g. just added?), append it?
                              // Stream should have it.
                            }

                            return DropdownButtonFormField<Category>(
                              decoration: InputDecoration(
                                labelText: l10n.category,
                              ),
                              value:
                                  selectedCategory, // Objects must implement == correctly or use ID
                              // Category is a data class, equality checks all fields.
                              // If fields changed in DB, equality might fail.
                              // Better to use ID for value, or ensure objects match.
                              // For simplicity, let's try object. If it fails, I'll switch to ID.
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
                          final newCategory = await showUpsertCategoryDialog(
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
                    if (isEdit) {
                      final updated = existingProduct.copyWith(
                        name: nameController.text,
                        categoryId: selectedCategory!.id,
                        imagePath: drift.Value(imagePath),
                        emoji: drift.Value(
                          emojiController.text.isEmpty
                              ? null
                              : emojiController.text,
                        ),
                      );
                      await database.products.replaceOne(updated);
                      result = updated;
                    } else {
                      result = await database
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
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(isEdit ? l10n.save : l10n.add),
              ),
            ],
          );
        },
      );
    },
  );
  return result;
}
