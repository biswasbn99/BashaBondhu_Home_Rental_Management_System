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
  String _selectedAudienceFilter = 'all'; // 'all', 'tenant', 'house_owner'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.streamFaqs(),
      builder: (context, snapshot) {
        final allFaqs = snapshot.data ?? [];

        final faqs = allFaqs.where((f) {
          if (_selectedAudienceFilter == 'all') return true;
          final aud = f['targetAudience']?.toString() ?? 'all';
          return aud == 'all' || aud == _selectedAudienceFilter;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Add Button with Wrap
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'সচরাচর জিজ্ঞাসা (FAQ Management)' : 'FAQ Management',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.themeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBn
                            ? 'ভাড়াটিয়া ও বাড়িওয়ালাদের জন্য পৃথক প্রশ্নোত্তর পরিচালনা করুন (${faqs.length} টি FAQ)'
                            : 'Manage role-targeted FAQs for Tenants and House Owners (${faqs.length} FAQs)',
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddOrEditFaqDialog(context, null, isBn),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isBn ? 'নতুন FAQ যোগ করুন' : 'Add New FAQ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- 👥 ROLE AUDIENCE FILTER CHIPS ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAudienceChip(
                      id: 'all',
                      labelBn: 'সকল FAQ (${allFaqs.length})',
                      labelEn: 'All FAQs (${allFaqs.length})',
                      icon: Icons.all_inclusive_rounded,
                      isBn: isBn,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildAudienceChip(
                      id: 'tenant',
                      labelBn: 'ভাড়াটিয়া FAQ (Tenant)',
                      labelEn: 'Tenant FAQs (${allFaqs.where((f) => (f['targetAudience'] ?? 'all') == 'tenant' || (f['targetAudience'] ?? 'all') == 'all').length})',
                      icon: Icons.person_pin_circle_rounded,
                      isBn: isBn,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildAudienceChip(
                      id: 'house_owner',
                      labelBn: 'বাড়িওয়ালা FAQ (House Owner)',
                      labelEn: 'House Owner FAQs (${allFaqs.where((f) => (f['targetAudience'] ?? 'all') == 'house_owner' || (f['targetAudience'] ?? 'all') == 'all').length})',
                      icon: Icons.apartment_rounded,
                      isBn: isBn,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                    child: Column(
                      children: [
                        const Icon(Icons.question_answer_outlined, size: 44, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          isBn ? 'এই ক্যাটাগরিতে কোনো FAQ পাওয়া যায়নি' : 'No FAQs found for this audience filter',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
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
                    final audience = faq['targetAudience']?.toString() ?? 'all';

                    final audienceColor = audience == 'tenant'
                        ? Colors.blueAccent
                        : audience == 'house_owner'
                            ? Colors.orangeAccent
                            : Colors.teal;

                    final audienceLabel = audience == 'tenant'
                        ? (isBn ? 'ভাড়াটিয়া' : 'Tenant')
                        : audience == 'house_owner'
                            ? (isBn ? 'বাড়িওয়ালা' : 'House Owner')
                            : (isBn ? 'উভয়' : 'All Users');

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                      ),
                      child: Material(
                        color: isDark ? const Color(0xFF1E2625) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.themeColor.withValues(alpha: 0.12),
                            child: const Icon(Icons.question_mark_rounded, color: AppColors.themeColor, size: 16),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: audienceColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  audienceLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: audienceColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isBn ? qBn : qEn,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${isBn ? "ক্যাটাগরি:" : "Category:"} $cat',
                            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161C1B) : const Color(0xFFF9FBFB),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? aBn : aEn,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[300] : const Color(0xFF4A5A58),
                                      height: 1.4,
                                    ),
                                  ),
                                  if (qEn.isNotEmpty && qBn.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      isBn ? "🇬🇧 English:\nQ: $qEn\nA: $aEn" : "🇧🇩 বাংলা:\nপ্রশ্ন: $qBn\nউত্তর: $aBn",
                                      style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildAudienceChip({
    required String id,
    required String labelBn,
    required String labelEn,
    required IconData icon,
    required bool isBn,
    required bool isDark,
  }) {
    final isSelected = _selectedAudienceFilter == id;
    final label = isBn ? labelBn : labelEn;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.themeColor,
      backgroundColor: isDark ? const Color(0xFF1E2625) : Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.themeColor : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAudienceFilter = id;
          });
        }
      },
    );
  }

  void _showAddOrEditFaqDialog(BuildContext context, Map<String, dynamic>? faq, bool isBn) {
    final qEnController = TextEditingController(text: faq?['questionEn']?.toString() ?? '');
    final qBnController = TextEditingController(text: faq?['questionBn']?.toString() ?? '');
    final aEnController = TextEditingController(text: faq?['answerEn']?.toString() ?? '');
    final aBnController = TextEditingController(text: faq?['answerBn']?.toString() ?? '');
    final catController = TextEditingController(text: faq?['category']?.toString() ?? 'general');
    String selectedAudience = faq?['targetAudience']?.toString() ?? 'all';
    final bool isEditing = faq != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEditing ? (isBn ? 'FAQ সম্পাদনা' : 'Edit FAQ') : (isBn ? 'নতুন FAQ যোগ করুন' : 'Add New FAQ')),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Audience Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedAudience,
                      decoration: InputDecoration(
                        labelText: isBn ? 'লক্ষ্যমাত্রা / ইউজার টাইপ (Target Audience) *' : 'Target Audience *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(isBn ? '🌐 সকল ব্যবহারকারী (Both Tenant & House Owner)' : '🌐 All Users (Both Roles)'),
                        ),
                        DropdownMenuItem(
                          value: 'tenant',
                          child: Text(isBn ? '🏠 কেবল ভাড়াটিয়া (Tenant Only)' : '🏠 Tenant Only'),
                        ),
                        DropdownMenuItem(
                          value: 'house_owner',
                          child: Text(isBn ? '🏢 কেবল বাড়িওয়ালা (House Owner Only)' : '🏢 House Owner Only'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedAudience = val;
                          });
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        selectedAudience == 'all'
                            ? (isBn ? '💡 এই FAQ ভাড়াটিয়া ও বাড়িওয়ালা উভয়ের অ্যাকাউন্ট থেকেই দেখা যাবে।' : '💡 This FAQ will be visible to both Tenant and House Owner.')
                            : selectedAudience == 'tenant'
                                ? (isBn ? '💡 এই FAQ কেবলমাত্র ভাড়াটিয়া (Tenant) অ্যাকাউন্ট থেকে দেখা যাবে।' : '💡 This FAQ will be visible ONLY in Tenant accounts.')
                                : (isBn ? '💡 এই FAQ কেবলমাত্র বাড়িওয়ালা (House Owner) অ্যাকাউন্ট থেকে দেখা যাবে।' : '💡 This FAQ will be visible ONLY in House Owner accounts.'),
                        style: TextStyle(
                          fontSize: 11,
                          color: selectedAudience == 'tenant'
                              ? Colors.blue
                              : selectedAudience == 'house_owner'
                                  ? Colors.orange[800]
                                  : AppColors.themeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: qEnController,
                      decoration: InputDecoration(
                        labelText: isBn ? 'প্রশ্ন (English) *' : 'Question (English) *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: qBnController,
                      decoration: InputDecoration(
                        labelText: isBn ? 'প্রশ্ন (বাংলা) *' : 'Question (Bangla) *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: aEnController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isBn ? 'উত্তর (English) *' : 'Answer (English) *',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: aBnController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isBn ? 'উত্তর (বাংলা) *' : 'Answer (Bangla) *',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: catController,
                      decoration: InputDecoration(
                        labelText: isBn ? 'ক্যাটাগরি (Category)' : 'Category',
                        hintText: 'general, finding_home, posting, management, safety',
                        border: const OutlineInputBorder(),
                        isDense: true,
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
                    'category': cat.isNotEmpty ? cat : 'general',
                    'targetAudience': selectedAudience,
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
          );
        },
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
