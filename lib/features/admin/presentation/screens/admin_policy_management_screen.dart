import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../shared/data/models/policy_model.dart';
import '../../../shared/data/services/policy_firestore_service.dart';
import '../../data/providers/admin_provider.dart';

class AdminPolicyManagementView extends StatefulWidget {
  const AdminPolicyManagementView({super.key});

  @override
  State<AdminPolicyManagementView> createState() => _AdminPolicyManagementViewState();
}

class _AdminPolicyManagementViewState extends State<AdminPolicyManagementView> with SingleTickerProviderStateMixin {
  final PolicyFirestoreService _policyService = PolicyFirestoreService();
  late TabController _tabController;

  final List<Map<String, dynamic>> _policyTabs = [
    {'type': 'privacy_policy', 'labelEn': 'Privacy Policy', 'labelBn': 'গোপনীয়তা নীতি', 'icon': Icons.privacy_tip_outlined},
    {'type': 'support_policy', 'labelEn': 'Support Policy', 'labelBn': 'সাপোর্ট পলিসি', 'icon': Icons.support_agent_rounded},
    {'type': 'terms_conditions', 'labelEn': 'Terms & Conditions', 'labelBn': 'শর্তাবলী', 'icon': Icons.gavel_rounded},
    {'type': 'refund_policy', 'labelEn': 'Refund Policy', 'labelBn': 'রিফান্ড পলিসি', 'icon': Icons.replay_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _policyTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditSectionDialog({
    required BuildContext context,
    required String policyType,
    PolicySectionModel? existingSection,
    required bool isBn,
  }) {
    final headingEnController = TextEditingController(text: existingSection?.headingEn ?? '');
    final headingBnController = TextEditingController(text: existingSection?.headingBn ?? '');
    final contentEnController = TextEditingController(text: existingSection?.contentEn ?? '');
    final contentBnController = TextEditingController(text: existingSection?.contentBn ?? '');
    final orderController = TextEditingController(text: existingSection?.order.toString() ?? '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  existingSection == null ? Icons.add_circle_outline_rounded : Icons.edit_note_rounded,
                  color: AppColors.themeColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                existingSection == null
                    ? (isBn ? 'নতুন ধারা / সেকশন যোগ করুন' : 'Add New Section')
                    : (isBn ? 'ধারা / সেকশন সম্পাদনা' : 'Edit Section'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // English Heading
                    TextFormField(
                      controller: headingEnController,
                      decoration: const InputDecoration(
                        labelText: 'Heading (English) *',
                        hintText: 'e.g. 1. User Responsibilities',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required in English' : null,
                    ),
                    const SizedBox(height: 12),

                    // Bengali Heading
                    TextFormField(
                      controller: headingBnController,
                      decoration: const InputDecoration(
                        labelText: 'হেডিং (বাংলা) *',
                        hintText: 'যেমন: ১. ব্যবহারকারীর দায়িত্ব ও আচরণবিধি',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'বাংলায় পূরণ করা আবশ্যক' : null,
                    ),
                    const SizedBox(height: 12),

                    // English Content
                    TextFormField(
                      controller: contentEnController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Content / Description (English) *',
                        hintText: 'Enter comprehensive details or bullet points with •',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required in English' : null,
                    ),
                    const SizedBox(height: 12),

                    // Bengali Content
                    TextFormField(
                      controller: contentBnController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'বিবরণ / ধারা বিস্তারিত (বাংলা) *',
                        hintText: 'বিস্তারিত তথ্য অথবা • দিয়ে পয়েন্ট আকারে লিখুন',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'বাংলায় বিবরণ দেওয়া আবশ্যক' : null,
                    ),
                    const SizedBox(height: 12),

                    // Order Number
                    TextFormField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Display Order Sequence (ক্রম নম্বর)',
                        hintText: '1, 2, 3...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isBn ? 'বাতিল' : 'Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newSection = PolicySectionModel(
                    id: existingSection?.id ?? 'sec_${DateTime.now().millisecondsSinceEpoch}',
                    headingEn: headingEnController.text.trim(),
                    headingBn: headingBnController.text.trim(),
                    contentEn: contentEnController.text.trim(),
                    contentBn: contentBnController.text.trim(),
                    order: int.tryParse(orderController.text.trim()) ?? 1,
                    iconName: existingSection?.iconName ?? 'info_outline',
                  );

                  await _policyService.savePolicySection(policyType, newSection);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBn ? 'ধারাটি সফলভাবে সংরক্ষণ করা হয়েছে!' : 'Section saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(isBn ? 'সংরক্ষণ করুন' : 'Save Section'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteSection(BuildContext context, String policyType, String sectionId, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(isBn ? 'ধারা ডিলিট নিশ্চিতকরণ' : 'Delete Section?'),
          content: Text(
            isBn
                ? 'আপনি কি নিশ্চিত যে এই ধারাটি মুছে ফেলতে চান?'
                : 'Are you sure you want to permanently remove this clause?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
            FilledButton(
              onPressed: () async {
                await _policyService.deletePolicySection(policyType, sectionId);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn ? 'ধারাটি মুছে ফেলা হয়েছে' : 'Section deleted'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text(isBn ? 'ডিলিট' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetPolicy(BuildContext context, String policyType, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(isBn ? 'ডিফল্ট টেমপ্লেটে রিসেট' : 'Reset to Default Template?'),
          content: Text(
            isBn
                ? 'এটি সমস্ত কাস্টম পরিবর্তন মুছে প্রমিত দ্বৈতভাষিক (বাংলা ও ইংরেজি) মূল বাসাবন্ধু পলিসি ফিরিয়ে আনবে।'
                : 'This will reset all sections to the standard verified bilingual BashaBondhu template.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
            FilledButton(
              onPressed: () async {
                await _policyService.resetPolicyToDefault(policyType);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isBn ? 'ডিফল্ট পলিসি সফলভাবে লোড হয়েছে' : 'Default policy reloaded'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(isBn ? 'হ্যাঁ, রিসেট করুন' : 'Reset Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
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
                    isBn ? 'আইনি নীতিমালা ও শর্তাবলী (Legal Policies)' : 'Legal Policies & Terms Management',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.themeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBn
                        ? 'গোপনীয়তা নীতি, সাপোর্ট পলিসি, শর্তাবলী ও রিফান্ড পলিসি পরিচালনা করুন (বাংলা ও ইংরেজি)'
                        : 'Manage Privacy Policy, Support Policy, Terms & Conditions, and Refund Policy dynamically',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Policy Type Tabs
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2826) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.themeColor,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              indicatorColor: AppColors.themeColor,
              indicatorWeight: 3,
              tabs: _policyTabs.map((tab) {
                final label = isBn ? tab['labelBn'] as String : tab['labelEn'] as String;
                final icon = tab['icon'] as IconData;
                return Tab(
                  icon: Icon(icon, size: 18),
                  text: label,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Active Tab Policy Viewer & Editor
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final activeIndex = _tabController.index;
              final currentTab = _policyTabs[activeIndex];
              final policyType = currentTab['type'] as String;
              final policyTitle = isBn ? currentTab['labelBn'] as String : currentTab['labelEn'] as String;

              return StreamBuilder<AppPolicyModel>(
                stream: _policyService.streamPolicy(policyType),
                builder: (context, snapshot) {
                  final policy = snapshot.data;
                  final sections = policy?.sections ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Action Toolbar for this Policy
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2826) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$policyTitle (${sections.length} ${isBn ? "টি ধারা" : "Sections"})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _confirmResetPolicy(context, policyType, isBn),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: Text(isBn ? 'ডিফল্ট রিসেট' : 'Reset Default'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () => _showAddEditSectionDialog(
                                    context: context,
                                    policyType: policyType,
                                    isBn: isBn,
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(isBn ? 'নতুন ধারা যোগ' : 'Add Section'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.themeColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Sections List
                      if (sections.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2826) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const Icon(Icons.article_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(isBn ? 'কোনো ধারা যুক্ত নেই' : 'No sections found for this policy'),
                            ],
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sections.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final sec = sections[index];

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B2826) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.themeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#${sec.order}',
                                          style: const TextStyle(
                                            color: AppColors.themeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sec.headingEn,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            Text(
                                              sec.headingBn,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? Colors.tealAccent : const Color(0xFF007A6C),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                        tooltip: isBn ? 'এডিট করুন' : 'Edit',
                                        onPressed: () => _showAddEditSectionDialog(
                                          context: context,
                                          policyType: policyType,
                                          existingSection: sec,
                                          isBn: isBn,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        tooltip: isBn ? 'ডিলিট করুন' : 'Delete',
                                        onPressed: () => _confirmDeleteSection(context, policyType, sec.id, isBn),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 18),
                                  Text(
                                    '🇬🇧 English:\n${sec.contentEn}',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '🇧🇩 বাংলা:\n${sec.contentBn}',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
