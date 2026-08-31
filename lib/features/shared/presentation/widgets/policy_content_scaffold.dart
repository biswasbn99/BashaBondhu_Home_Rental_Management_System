import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../data/models/policy_model.dart';
import '../../data/services/policy_firestore_service.dart';

class PolicyContentScaffold extends StatefulWidget {
  final String policyType; // 'privacy_policy', 'support_policy', 'terms_conditions', 'refund_policy'
  final IconData defaultIcon;

  const PolicyContentScaffold({
    super.key,
    required this.policyType,
    required this.defaultIcon,
  });

  @override
  State<PolicyContentScaffold> createState() => _PolicyContentScaffoldState();
}

class _PolicyContentScaffoldState extends State<PolicyContentScaffold> {
  final PolicyFirestoreService _policyService = PolicyFirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _resolveIcon(String? iconName) {
    if (iconName == null) return widget.defaultIcon;
    switch (iconName.toLowerCase()) {
      case 'info_outline':
        return Icons.info_outline_rounded;
      case 'person_outline':
        return Icons.person_outline_rounded;
      case 'cookie_outlined':
        return Icons.cookie_outlined;
      case 'payment_outlined':
        return Icons.payment_rounded;
      case 'delete_outline':
        return Icons.delete_outline_rounded;
      case 'mail_outline':
        return Icons.mail_outline_rounded;
      case 'support_agent_outlined':
        return Icons.support_agent_rounded;
      case 'contact_phone_outlined':
        return Icons.contact_phone_outlined;
      case 'schedule_outlined':
        return Icons.schedule_rounded;
      case 'rule_outlined':
        return Icons.rule_rounded;
      case 'gavel_outlined':
        return Icons.gavel_rounded;
      case 'home_work_outlined':
        return Icons.home_work_outlined;
      case 'account_balance_wallet_outlined':
        return Icons.account_balance_wallet_outlined;
      case 'account_balance_outlined':
        return Icons.account_balance_rounded;
      case 'replay_outlined':
        return Icons.replay_rounded;
      case 'timer_outlined':
        return Icons.timer_outlined;
      case 'highlight_off_outlined':
        return Icons.highlight_off_rounded;
      case 'mark_email_read_outlined':
        return Icons.mark_email_read_outlined;
      default:
        return widget.defaultIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final languageCode = localeProvider.currentLocale.languageCode;
    final isBn = languageCode == 'bn';

    return StreamBuilder<AppPolicyModel>(
      stream: _policyService.streamPolicy(widget.policyType),
      builder: (context, snapshot) {
        final policy = snapshot.data;
        final title = policy?.getTitle(languageCode) ?? '';
        final subtitle = policy?.getSubtitle(languageCode) ?? '';
        final sections = policy?.sections ?? [];

        final filteredSections = sections.where((sec) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final h = sec.getHeading(languageCode).toLowerCase();
          final c = sec.getContent(languageCode).toLowerCase();
          return h.contains(q) || c.contains(q);
        }).toList();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF101918) : const Color(0xFFF7FBF9),
          appBar: AppBar(
            elevation: 0,
            title: Text(
              title,
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
          body: snapshot.connectionState == ConnectionState.waiting && policy == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.themeColor))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Hero Header Card ---
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(widget.defaultIcon, color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'BashaBondhu Rental Management',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Colors.white, size: 13),
                                      const SizedBox(width: 5),
                                      Text(
                                        isBn ? 'সর্বশেষ আপডেট: আগস্ট ২০২৬' : 'Last Updated: August 2026',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Search / Filter Field ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2826) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                            hintText: isBn ? 'শর্ত বা নীতি খুঁজুন...' : 'Search policy clauses...',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
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
                      const SizedBox(height: 18),

                      // --- Section Cards List ---
                      if (filteredSections.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                isBn ? 'কোনো ফলাফল পাওয়া যায়নি' : 'No matching clauses found',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ...filteredSections.map((sec) {
                          return _PolicySectionCard(
                            section: sec,
                            languageCode: languageCode,
                            isDark: isDark,
                            icon: _resolveIcon(sec.iconName),
                          );
                        }),
                      ],

                      const SizedBox(height: 20),

                      // --- Bottom Support Contact Card ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162321) : const Color(0xFFE8F6F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.themeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.themeColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.headset_mic_rounded, color: AppColors.themeColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? 'আরও তথ্য বা সহায়তা প্রয়োজন?' : 'Need More Assistance?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: AppColors.themeColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isBn
                                        ? 'আমাদের হেল্পডেস্কে সরাসরি ইমেইল করুন: support@bashabondhu.com অথবা হটলাইনে যোগাযোগ করুন।'
                                        : 'Reach our dedicated helpdesk directly at: support@bashabondhu.com or connect via hotline.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  final PolicySectionModel section;
  final String languageCode;
  final bool isDark;
  final IconData icon;

  const _PolicySectionCard({
    required this.section,
    required this.languageCode,
    required this.isDark,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final heading = section.getHeading(languageCode);
    final content = section.getContent(languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2826) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.themeColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    heading,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF142321),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildFormattedContent(content, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String text, bool isDark) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 4);

        if (trimmed.startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.themeColor, fontWeight: FontWeight.bold, fontSize: 13)),
                Expanded(
                  child: Text(
                    trimmed.substring(1).trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: isDark ? Colors.grey[300] : const Color(0xFF3B4E4B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            trimmed,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? Colors.grey[300] : const Color(0xFF3B4E4B),
            ),
          ),
        );
      }).toList(),
    );
  }
}
