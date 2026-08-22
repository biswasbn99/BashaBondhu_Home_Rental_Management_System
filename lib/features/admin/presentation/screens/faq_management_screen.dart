import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class FaqManagementView extends StatefulWidget {
  const FaqManagementView({super.key});

  @override
  State<FaqManagementView> createState() => _FaqManagementViewState();
}

class _FaqManagementViewState extends State<FaqManagementView> {
  final AdminFirestoreService _adminService = AdminFirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.streamFaqs(),
      builder: (context, snapshot) {
        final faqs = snapshot.data ?? [];

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
                        isBn ? 'সচরাচর জিজ্ঞাসা (FAQ Management)' : 'FAQ Management',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.themeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn
                            ? 'ব্যবহারকারীদের প্রশ্নের উত্তর ও গাইড পরিচালনা করুন (${faqs.length} টি প্রশ্নোত্তর)'
                            : 'Manage frequently asked questions and user guides (${faqs.length} FAQs)',
                        style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddOrEditFaqDialog(context, null, isBn),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(isBn ? 'নতুন FAQ যোগ করুন' : 'Add FAQ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // FAQ List
              if (faqs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2625) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                  child: Center(
                    child: Text(isBn ? 'কোনো FAQ পাওয়া যায়নি' : 'No FAQs available'),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final faq = faqs[idx];
                    final qEn = faq['questionEn']?.toString() ?? '';
                    final qBn = faq['questionBn']?.toString() ?? qEn;
                    final aEn = faq['answerEn']?.toString() ?? '';
                    final aBn = faq['answerBn']?.toString() ?? aEn;
                    final cat = faq['category']?.toString() ?? 'General';

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2625) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.themeColor.withValues(alpha: 0.12),
                          child: const Icon(Icons.question_mark_rounded, color: AppColors.themeColor, size: 18),
                        ),
                        title: Text(
                          isBn ? qBn : qEn,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        subtitle: Text(
                          '${isBn ? "ক্যাটাগরি:" : "Category:"} $cat',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 18),
                              tooltip: isBn ? 'সম্পাদনা' : 'Edit',
                              onPressed: () => _showAddOrEditFaqDialog(context, faq, isBn),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              tooltip: isBn ? 'মুছুন' : 'Delete',
                              onPressed: () => _showDeleteFaqDialog(context, faq['id'], isBn),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 6),
                                Text(
                                  isBn ? aBn : aEn,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.grey[300] : const Color(0xFF4A5A58),
                                    height: 1.5,
                                  ),
                                ),
                                if (qEn.isNotEmpty && qBn.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    isBn ? "English: $qEn\n$aEn" : "বাংলা: $qBn\n$aBn",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOrEditFaqDialog(BuildContext context, Map<String, dynamic>? faq, bool isBn) {
    final qEnController = TextEditingController(text: faq?['questionEn']?.toString() ?? '');
    final qBnController = TextEditingController(text: faq?['questionBn']?.toString() ?? '');
    final aEnController = TextEditingController(text: faq?['answerEn']?.toString() ?? '');
    final aBnController = TextEditingController(text: faq?['answerBn']?.toString() ?? '');
    final catController = TextEditingController(text: faq?['category']?.toString() ?? 'General');
    final bool isEditing = faq != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? (isBn ? 'FAQ সম্পাদনা' : 'Edit FAQ') : (isBn ? 'নতুন FAQ যোগ করুন' : 'Add New FAQ')),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qEnController,
                  decoration: InputDecoration(
                    labelText: isBn ? 'প্রশ্ন (English)' : 'Question (English)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qBnController,
                  decoration: InputDecoration(
                    labelText: isBn ? 'প্রশ্ন (বাংলা)' : 'Question (Bangla)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aEnController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isBn ? 'উত্তর (English)' : 'Answer (English)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aBnController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isBn ? 'উত্তর (বাংলা)' : 'Answer (Bangla)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catController,
                  decoration: InputDecoration(
                    labelText: isBn ? 'ক্যাটাগরি' : 'Category',
                    hintText: 'General, Verification, Tenant, Owner',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            onPressed: () async {
              final qEn = qEnController.text.trim();
              final qBn = qBnController.text.trim();
              final aEn = aEnController.text.trim();
              final aBn = aBnController.text.trim();
              final cat = catController.text.trim();

              if (qEn.isEmpty && qBn.isEmpty) return;

              Navigator.pop(ctx);
              final Map<String, dynamic> data = {
                'questionEn': qEn.isNotEmpty ? qEn : qBn,
                'questionBn': qBn.isNotEmpty ? qBn : qEn,
                'answerEn': aEn.isNotEmpty ? aEn : aBn,
                'answerBn': aBn.isNotEmpty ? aBn : aEn,
                'category': cat.isNotEmpty ? cat : 'General',
              };

              if (isEditing) {
                await _adminService.updateFaq(faq['id'], data);
              } else {
                await _adminService.addFaq(data);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'FAQ সফলভাবে সংরক্ষিত হয়েছে!' : 'FAQ Saved!'), backgroundColor: Colors.green),
                );
              }
            },
            child: Text(isBn ? 'সংরক্ষণ' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFaqDialog(BuildContext context, String faqId, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'FAQ মুছে ফেলুন' : 'Delete FAQ'),
        content: Text(isBn ? 'আপনি কি নিশ্চিত যে এই FAQ ডিলিট করতে চান?' : 'Are you sure you want to delete this FAQ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.deleteFaq(faqId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'FAQ মুছে ফেলা হয়েছে।' : 'FAQ deleted.'), backgroundColor: Colors.redAccent),
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
