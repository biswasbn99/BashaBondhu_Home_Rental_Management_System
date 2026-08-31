import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../data/models/policy_model.dart';
import '../../data/services/policy_firestore_service.dart';

class PolicyContentScaffold extends StatefulWidget {
  final String policyType; // 'privacy_policy', 'support_policy', 'terms_conditions', 'refund_policy'
  final String targetAudience; // 'tenant' or 'house_owner'
  final IconData defaultIcon;

  const PolicyContentScaffold({
    super.key,
    required this.policyType,
    this.targetAudience = 'tenant',
    this.defaultIcon = Icons.article_outlined,
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
    switch (iconName) {
      case 'privacy_tip_outlined':
        return Icons.privacy_tip_outlined;
      case 'support_agent_rounded':
        return Icons.support_agent_rounded;
      case 'gavel_rounded':
        return Icons.gavel_rounded;
      case 'replay_rounded':
        return Icons.replay_rounded;
      case 'security_rounded':
        return Icons.security_rounded;
      case 'lock_outline_rounded':
        return Icons.lock_outline_rounded;
      case 'delete_forever_outlined':
        return Icons.delete_forever_outlined;
      case 'home_work_outlined':
        return Icons.home_work_outlined;
      case 'verified_user_outlined':
        return Icons.verified_user_outlined;
      case 'account_balance_wallet_outlined':
        return Icons.account_balance_wallet_outlined;
      case 'domain_verification_rounded':
        return Icons.domain_verification_rounded;
      case 'visibility_outlined':
        return Icons.visibility_outlined;
      case 'speed_rounded':
        return Icons.speed_rounded;
      case 'handshake_outlined':
        return Icons.handshake_outlined;
      case 'check_circle_outline_rounded':
        return Icons.check_circle_outline_rounded;
      case 'shield_outlined':
        return Icons.shield_outlined;
      case 'campaign_outlined':
        return Icons.campaign_outlined;
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
    final isTenant = widget.targetAudience == 'tenant';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101918) : const Color(0xFFF7FBF9),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          isTenant
              ? (isBn ? 'ভাড়াটিয়া পলিসি ও শর্তাবলী' : 'Tenant Legal & Policy')
              : (isBn ? 'বাড়িওয়ালা পলিসি ও শর্তাবলী' : 'Landlord Legal & Policy'),
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
      body: StreamBuilder<AppPolicyModel>(
        stream: _policyService.streamPolicy(
          widget.policyType,
          targetAudience: widget.targetAudience,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final policy = snapshot.data;
          if (policy == null) {
            return Center(
              child: Text(
                isBn ? 'পলিসি লোড করা যায়নি' : 'Unable to load policy.',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            );
          }

          final title = policy.getTitle(languageCode);
          final subtitle = policy.getSubtitle(languageCode);
          final allSections = policy.sections;

          // Filter sections based on search query
          final filteredSections = allSections.where((sec) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final h = sec.getHeading(languageCode).toLowerCase();
            final c = sec.getContent(languageCode).toLowerCase();
            return h.contains(q) || c.contains(q);
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header Hero Banner ---
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                  child: Icon(widget.defaultIcon, color: Colors.white, size: 28),
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
                                        'BashaBondhu • ${isTenant ? (isBn ? "ভাড়াটিয়া পোর্টাল" : "Tenant Portal") : (isBn ? "বাড়িওয়ালা পোর্টাল" : "Landlord Portal")}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.white.withValues(alpha: 0.9),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isTenant ? Icons.person_pin_circle_rounded : Icons.apartment_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isTenant
                                            ? (isBn ? 'ভাড়াটিয়া নির্দেশিকা' : 'Tenant Guidelines')
                                            : (isBn ? 'বাড়িওয়ালা নির্দেশিকা' : 'Landlord Guidelines'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
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
                            hintText: isBn ? 'ধারা বা বিষয় লিখে খুঁজুন...' : 'Search clauses or keywords...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
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
                      const SizedBox(height: 16),

                      // --- Sections List ---
                      if (filteredSections.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2826) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                                    isTenant
                                        ? (isBn
                                            ? 'বাসা খোঁজা বা ভাড়ার চাহিদা সংক্রান্ত যেকোনো সমস্যায় আমাদের টেন্যান্ট হেল্পডেস্কে ইমেইল করুন: tenant-support@bashabondhu.com'
                                            : 'For queries regarding home search or demands, contact our tenant desk: tenant-support@bashabondhu.com')
                                        : (isBn
                                            ? 'বিজ্ঞাপন পোস্ট বা লিস্টিং সংক্রান্ত যেকোনো সমস্যায় আমাদের বাড়িওয়ালা হেল্পডেস্কে ইমেইল করুন: owner-support@bashabondhu.com'
                                            : 'For listing verification or management assistance, contact our landlord desk: owner-support@bashabondhu.com'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.grey[300] : const Color(0xFF334A47),
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
              ),
            ],
          );
        },
      ),
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
        if (trimmed.isEmpty) return const SizedBox(height: 6);

        if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
          final bulletText = trimmed.replaceFirst(RegExp(r'^[•\-]\s*'), '');
          return Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.themeColor, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    bulletText,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: isDark ? const Color(0xFFC7D5D3) : const Color(0xFF3B4E4B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            trimmed,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: isDark ? const Color(0xFFC7D5D3) : const Color(0xFF3B4E4B),
            ),
          ),
        );
      }).toList(),
    );
  }
}
