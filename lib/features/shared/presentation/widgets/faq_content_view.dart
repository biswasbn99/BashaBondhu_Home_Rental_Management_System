import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../data/models/policy_model.dart';
import '../../data/services/policy_firestore_service.dart';

class FaqContentView extends StatefulWidget {
  final String targetAudience; // 'tenant', 'house_owner', or 'all'

  const FaqContentView({
    super.key,
    this.targetAudience = 'all',
  });

  @override
  State<FaqContentView> createState() => _FaqContentViewState();
}

class _FaqContentViewState extends State<FaqContentView> {
  final PolicyFirestoreService _policyService = PolicyFirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final languageCode = localeProvider.currentLocale.languageCode;
    final isBn = languageCode == 'bn';
    final isTenant = widget.targetAudience == 'tenant';
    final isOwner = widget.targetAudience == 'house_owner';

    final categories = [
      {'id': 'all', 'labelBn': 'সবগুলো', 'labelEn': 'All FAQs'},
      {'id': 'general', 'labelBn': 'বাসাবন্ধু সম্পর্কে', 'labelEn': 'About Platform'},
      if (!isOwner) {'id': 'finding_home', 'labelBn': 'বাসা খোঁজা ও চাহিদা', 'labelEn': 'Finding Homes'},
      if (!isTenant) {'id': 'posting', 'labelBn': 'বিজ্ঞাপন পোস্ট', 'labelEn': 'Listing Posts'},
      if (!isTenant) {'id': 'management', 'labelBn': 'ভাড়া ও সাবস্ক্রিপশন', 'labelEn': 'Management & Plans'},
      {'id': 'safety', 'labelBn': 'নিরাপত্তা ও সহায়তা', 'labelEn': 'Safety & Trust'},
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101918) : const Color(0xFFF7FBF9),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          isTenant
              ? (isBn ? 'ভাড়াটিয়া প্রশ্নোত্তর (FAQ)' : 'Tenant FAQs')
              : isOwner
                  ? (isBn ? 'বাড়িওয়ালা প্রশ্নোত্তর (FAQ)' : 'Landlord FAQs')
                  : (isBn ? 'সচরাচর জিজ্ঞাসা (FAQ)' : 'Frequently Asked Questions'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          // Language Switch Button
          TextButton.icon(
            onPressed: () {
              final newLang = isBn ? 'en' : 'bn';
              localeProvider.changeLocale(Locale(newLang));
            },
            icon: const Icon(Icons.translate_rounded, size: 16),
            label: Text(
              isBn ? 'English' : 'বাংলা',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<List<FaqModel>>(
        stream: _policyService.streamFaqs(
          category: _selectedCategory,
          targetAudience: widget.targetAudience,
        ),
        builder: (context, snapshot) {
          final allFaqs = snapshot.data ?? [];

          final filteredFaqs = allFaqs.where((f) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final question = f.getQuestion(languageCode).toLowerCase();
            final answer = f.getAnswer(languageCode).toLowerCase();
            return question.contains(q) || answer.contains(q);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Header Hero Banner ---
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A896), AppColors.themeColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.themeColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTenant
                                  ? (isBn ? 'ভাড়াটিয়াদের সাধারণ প্রশ্ন ও উত্তর' : 'Tenant Help & Queries')
                                  : isOwner
                                      ? (isBn ? 'বাড়িওয়ালাদের সাধারণ প্রশ্ন ও উত্তর' : 'Landlord Help & Queries')
                                      : (isBn ? 'কীভাবে সাহায্য করতে পারি?' : 'How Can We Help You?'),
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isTenant
                                  ? (isBn
                                      ? 'বাসা খোঁজা, বুকিং ও ভাড়ার চাহিদা সম্পর্কিত সকল সাধারণ সমাধান।'
                                      : 'Find answers regarding finding homes, booking visits, and posting demands.')
                                  : isOwner
                                      ? (isBn
                                          ? 'বিজ্ঞাপন পোস্ট, সাবস্ক্রিপশন প্ল্যান ও ভাড়াটিয়া পাওয়ার সমাধান।'
                                          : 'Find answers on publishing listings, boosts, and finding verified tenants.')
                                      : (isBn
                                          ? 'বাসা খোঁজা, বিজ্ঞাপন পোস্ট ও ভাড়া ম্যানেজমেন্টের সাধারণ প্রশ্ন।'
                                          : 'Find quick answers for both tenants and landlords.'),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Search Bar ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2826) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search_rounded, size: 20, color: AppColors.themeColor),
                      hintText: isBn ? 'প্রশ্ন বা বিষয় লিখে খুঁজুন...' : 'Search questions or keywords...',
                      hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Category Filter Chips ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat['id'];
                      final label = isBn ? cat['labelBn']! : cat['labelEn']!;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.themeColor,
                          backgroundColor: isDark ? const Color(0xFF1B2826) : Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.themeColor
                                : isDark
                                    ? const Color(0xFF2C3E3B)
                                    : const Color(0xFFE2E9E7),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat['id']!;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // --- FAQs List Accordion ---
                if (filteredFaqs.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.contact_support_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          isBn ? 'কোনো প্রশ্নোত্তর পাওয়া যায়নি' : 'No FAQs matched your search',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...filteredFaqs.map((faq) {
                    return _FaqAccordionCard(
                      faq: faq,
                      languageCode: languageCode,
                      isDark: isDark,
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // --- Bottom Action Card ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162321) : const Color(0xFFE8F6F4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.forum_rounded, color: AppColors.themeColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'আপনার প্রশ্নের উত্তর পাননি?' : 'Still Have Questions?',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.themeColor),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isTenant
                                  ? (isBn
                                      ? 'আমাদের টেন্যান্ট সাপোর্ট টিমের সাথে সরাসরি চ্যাট বা ইমেইলে যোগাযোগ করুন।'
                                      : 'Reach out directly to tenant support: tenant-support@bashabondhu.com')
                                  : isOwner
                                      ? (isBn
                                          ? 'আমাদের বাড়িওয়ালা সাপোর্ট টিমের সাথে সরাসরি চ্যাট বা ইমেইলে যোগাযোগ করুন।'
                                          : 'Reach out directly to landlord support: owner-support@bashabondhu.com')
                                      : (isBn
                                          ? 'আমাদের সাপোর্ট টিমের সাথে সরাসরি চ্যাট বা ইমেইলে যোগাযোগ করুন।'
                                          : 'Reach out to our support team directly via email or chat assistance.'),
                              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FaqAccordionCard extends StatelessWidget {
  final FaqModel faq;
  final String languageCode;
  final bool isDark;

  const _FaqAccordionCard({
    required this.faq,
    required this.languageCode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final question = faq.getQuestion(languageCode);
    final answer = faq.getAnswer(languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7),
        ),
      ),
      child: Material(
        color: isDark ? const Color(0xFF1B2826) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline_rounded, color: AppColors.themeColor, size: 18),
            ),
            title: Text(
              question,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[100] : const Color(0xFF142321),
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131E1C) : const Color(0xFFF6FAF9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : const Color(0xFF3B4E4B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
