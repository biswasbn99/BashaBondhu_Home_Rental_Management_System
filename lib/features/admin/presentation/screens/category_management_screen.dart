import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});

  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
  final AdminFirestoreService _adminService = AdminFirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.streamCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'ক্যাটাগরি ম্যানেজমেন্ট' : 'Category Management',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.themeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn
                            ? 'বাসাভাড়ার ক্যাটাগরি ও ধরনসমূহ পরিচালনা করুন (${categories.length} টি ক্যাটাগরি)'
                            : 'Manage Property Types and Accommodation Categories (${categories.length} categories)',
                        style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddOrEditCategoryDialog(context, null, isBn),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(isBn ? 'নতুন ক্যাটাগরি' : 'Add Category'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Categories Grid
              if (categories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2625) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                  child: Center(
                    child: Text(isBn ? 'কোনো ক্যাটাগরি পাওয়া যায়নি' : 'No categories available'),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final name = cat['name']?.toString() ?? 'Category';
                        final bnName = cat['bnName']?.toString() ?? name;
                        final bool isActive = cat['isActive'] as bool? ?? true;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2625) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isActive ? AppColors.themeColor : Colors.grey).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.category_rounded, color: isActive ? AppColors.themeColor : Colors.grey, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isBn ? bnName : name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isBn ? name : bnName,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                                        tooltip: isBn ? 'সম্পাদনা' : 'Edit',
                                        onPressed: () => _showAddOrEditCategoryDialog(context, cat, isBn),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        tooltip: isBn ? 'মুছুন' : 'Delete',
                                        onPressed: () => _showDeleteCategoryDialog(context, cat['id'], isBn),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOrEditCategoryDialog(BuildContext context, Map<String, dynamic>? category, bool isBn) {
    final nameController = TextEditingController(text: category?['name']?.toString() ?? '');
    final bnNameController = TextEditingController(text: category?['bnName']?.toString() ?? '');
    final bool isEditing = category != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? (isBn ? 'ক্যাটাগরি সম্পাদনা' : 'Edit Category') : (isBn ? 'নতুন ক্যাটাগরি যুক্ত করুন' : 'Add New Category')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isBn ? 'ক্যাটাগরির নাম (English)' : 'Category Name (English)',
                hintText: 'e.g. Family Flat, Bachelor',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bnNameController,
              decoration: InputDecoration(
                labelText: isBn ? 'ক্যাটাগরির নাম (বাংলা)' : 'Category Name (Bangla)',
                hintText: 'যেমন: ফ্যামিলি ফ্ল্যাট, ব্যাচেলর',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            onPressed: () async {
              final name = nameController.text.trim();
              final bnName = bnNameController.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(ctx);
              if (isEditing) {
                await _adminService.updateCategory(category['id'], {
                  'name': name,
                  'bnName': bnName.isNotEmpty ? bnName : name,
                });
              } else {
                await _adminService.addCategory({
                  'name': name,
                  'bnName': bnName.isNotEmpty ? bnName : name,
                  'isActive': true,
                });
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'ক্যাটাগরি সফলভাবে সংরক্ষিত হয়েছে!' : 'Category Saved!'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text(isBn ? 'সংরক্ষণ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, String categoryId, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'ক্যাটাগরি মুছে ফেলুন' : 'Delete Category'),
        content: Text(isBn ? 'আপনি কি নিশ্চিত যে এই ক্যাটাগরি ডিলিট করতে চান?' : 'Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.deleteCategory(categoryId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'ক্যাটাগরি মুছে ফেলা হয়েছে।' : 'Category deleted.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'ডিলিট' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
