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
              FilledButton(
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

/// Show a bottom sheet to pick camera or gallery
Future<ImageSource?> _showImageSourcePicker(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectImageSource,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(l10n.camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.photo_library,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(l10n.gallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Pick image from selected source and save to app documents
Future<String?> _pickAndSaveImage(
  BuildContext context,
  ImagePicker picker,
) async {
  final source = await _showImageSourcePicker(context);
  if (source == null) return null;

  final XFile? image = await picker.pickImage(source: source);
  if (image == null) return null;

  final directory = await getApplicationDocumentsDirectory();
  final name = p.basename(image.path);
  final savedImage = await File(image.path).copy('${directory.path}/$name');
  return savedImage.path;
}

Future<Product?> showUpsertProductDialog(
  BuildContext context,
  AppDatabase database, {
  Product? existingProduct,
}) async {
  final nameController = TextEditingController(text: existingProduct?.name);
  final emojiController = TextEditingController(text: existingProduct?.emoji);
  final volumeController = TextEditingController(
    text: existingProduct?.volume != null
        ? (existingProduct!.volume! % 1 == 0
              ? existingProduct.volume!.toInt().toString()
              : existingProduct.volume.toString())
        : '',
  );
  Category? selectedCategory;
  String? imagePath = existingProduct?.imagePath;
  String? selectedVolumeUnit = existingProduct?.volumeUnit;
  final ImagePicker picker = ImagePicker();
  Product? result;

  final volumeUnits = ['g', 'kg', 'ml', 'L', 'pcs'];

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
            title: Text(isEdit ? l10n.editProduct : l10n.newProduct),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.name),
                  ),
                  const SizedBox(height: 12),
                  // Category
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<Category>>(
                          stream: database.select(database.categories).watch(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final categories = snapshot.data!;
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
                  const SizedBox(height: 12),
                  // Volume Input (F4)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: volumeController,
                          decoration: InputDecoration(
                            labelText: l10n.volume,
                            hintText: '300',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: l10n.volumeUnit,
                          ),
                          value: selectedVolumeUnit,
                          items: volumeUnits.map((u) {
                            return DropdownMenuItem(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => selectedVolumeUnit = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Photo (F8 - Camera/Gallery selection)
                  Row(
                    children: [
                      if (imagePath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(imagePath!),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image,
                            size: 28,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final path = await _pickAndSaveImage(context, picker);
                          if (path != null) {
                            setState(() => imagePath = path);
                          }
                        },
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: Text(l10n.photo),
                      ),
                      if (imagePath != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => imagePath = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Emoji
                  Row(
                    children: [
                      Text(
                        '${l10n.emoji}: ',
                        style: const TextStyle(fontSize: 14),
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
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
                          icon: const Icon(Icons.clear, size: 18),
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
              FilledButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      selectedCategory != null) {
                    final vol = double.tryParse(volumeController.text);
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
                        volume: drift.Value(vol),
                        volumeUnit: drift.Value(
                          selectedVolumeUnit?.isEmpty ?? true
                              ? null
                              : selectedVolumeUnit,
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
                              volume: drift.Value(vol),
                              volumeUnit: drift.Value(
                                selectedVolumeUnit?.isEmpty ?? true
                                    ? null
                                    : selectedVolumeUnit,
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
