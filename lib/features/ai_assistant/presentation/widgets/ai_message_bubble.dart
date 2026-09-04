import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/home/data/models/property_model.dart';
import '../../../../features/home/presentation/screens/property_details_screen.dart';
import '../../../../features/shared/presentation/screens/my_profile_screen.dart';
import '../../../../features/subscription/presentation/screens/house_owner_subscription_screen.dart';
import '../../../../features/subscription/presentation/screens/subscription_history_screen.dart';
import '../../../../features/subscription/presentation/screens/tenant_subscription_screen.dart';
import '../../../../features/tenant/presentation/screens/show_demand_details_screen.dart';
import '../../data/models/ai_message_model.dart';
import '../providers/ai_assistant_provider.dart';

class AIMessageBubble extends StatelessWidget {
  final AIMessageModel message;
  final UserModel user;
  final String languageCode;
  final Function(String) onChipTapped;

  const AIMessageBubble({
    super.key,
    required this.message,
    required this.user,
    required this.languageCode,
    required this.onChipTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == AIMessageSender.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A896), AppColors.themeColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.themeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Text Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.themeColor
                        : isDark
                            ? const Color(0xFF1E2C2A)
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isUser
                          ? AppColors.themeColor
                          : isDark
                              ? const Color(0xFF2C3E3B)
                              : const Color(0xFFE2E9E7),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormattedText(message.text, isUser, isDark),

                      // TTS Audio Speaker Icon on AI message
                      if (!isUser) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Consumer<AIAssistantProvider>(
                              builder: (context, provider, _) {
                                final isPlaying = provider.currentlyPlayingMessageId == message.id;
                                return InkWell(
                                  onTap: () {
                                    provider.speakMessage(message, languageCode);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPlaying ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                                          size: 16,
                                          color: isPlaying ? Colors.amber : AppColors.themeColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isPlaying
                                              ? (languageCode == 'bn' ? 'শুনছেন...' : 'Playing...')
                                              : (languageCode == 'bn' ? 'শুনুন' : 'Listen'),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isPlaying ? Colors.amber : AppColors.themeColor,
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
                      ],
                    ],
                  ),
                ),

                // 1-Tap Selectable Option Chips
                if (message.interactiveChips != null && message.interactiveChips!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.interactiveChips!.map((chipText) {
                      final isSearchNow = chipText.contains('🔍') || chipText.toLowerCase().contains('search');
                      final isConfirm = chipText.contains('✅') || chipText.toLowerCase().contains('publish');
                      final isCancel = chipText.contains('❌') || chipText.toLowerCase().contains('cancel');

                      return ActionChip(
                        onPressed: () => onChipTapped(chipText),
                        backgroundColor: isConfirm
                            ? Colors.green
                            : isCancel
                                ? Colors.redAccent
                                : isSearchNow
                                    ? AppColors.themeColor
                                    : isDark
                                        ? const Color(0xFF1B2826)
                                        : Colors.white,
                        elevation: isSearchNow || isConfirm ? 2 : 0,
                        side: BorderSide(
                          color: isConfirm
                              ? Colors.green
                              : isCancel
                                  ? Colors.redAccent
                                  : isSearchNow
                                      ? AppColors.themeColor
                                      : isDark
                                          ? const Color(0xFF2C3E3B)
                                          : const Color(0xFFCCE2DD),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        label: Text(
                          chipText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSearchNow || isConfirm ? FontWeight.bold : FontWeight.w600,
                            color: isConfirm || isCancel || isSearchNow
                                ? Colors.white
                                : isDark
                                    ? Colors.grey[200]
                                    : Colors.grey[900],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Action Card Types
                if (message.actionCardType == AIActionCardType.subscriptionHistory) ...[
                  const SizedBox(height: 10),
                  _SubscriptionHistoryCard(languageCode: languageCode, isDark: isDark),
                ] else if (message.actionCardType == AIActionCardType.subscriptionPackages) ...[
                  const SizedBox(height: 10),
                  _SubscriptionPackagesCard(user: user, languageCode: languageCode, isDark: isDark),
                ] else if (message.actionCardType == AIActionCardType.myProfile) ...[
                  const SizedBox(height: 10),
                  _MyProfileCard(user: user, languageCode: languageCode, isDark: isDark),
                ] else if (message.actionCardType == AIActionCardType.demandDraft && message.demandDraft != null) ...[
                  const SizedBox(height: 10),
                  _DemandDraftConfirmationCard(
                    draft: message.demandDraft!,
                    user: user,
                    languageCode: languageCode,
                    isDark: isDark,
                  ),
                ] else if (message.actionCardType == AIActionCardType.adminStats && message.adminStats != null) ...[
                  const SizedBox(height: 10),
                  _AdminStatsCard(stats: message.adminStats!, languageCode: languageCode, isDark: isDark),
                ],

                // Live Property Cards Carousel
                if (message.properties != null && message.properties!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _PropertyCardsCarousel(
                    properties: message.properties!,
                    languageCode: languageCode,
                    isDark: isDark,
                  ),
                ],

                // Live Matching Tenant Demands Carousel
                if (message.matchingDemands != null && message.matchingDemands!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _MatchingDemandsCarousel(
                    matchingDemands: message.matchingDemands!,
                    languageCode: languageCode,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.45,
        color: isUser
            ? Colors.white
            : isDark
                ? Colors.grey[100]
                : Colors.grey[900],
      ),
    );
  }
}

// ==========================================
// ACTION CARDS
// ==========================================

class _SubscriptionHistoryCard extends StatelessWidget {
  final String languageCode;
  final bool isDark;

  const _SubscriptionHistoryCard({required this.languageCode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isBn = languageCode == 'bn';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182422) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                isBn ? 'সাবস্ক্রিপশন ও পেমেন্ট হিস্ট্রি' : 'Subscription & Payment History',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isBn
                ? 'আপনার বিগত সকল সাবস্ক্রিপশন প্ল্যান, পেমেন্ট ট্রানজেকশন ও ডিজিটাল মানি রিসিট দেখতে পারবেন।'
                : 'View past subscription plans, payment transactions, and official invoices.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, SubscriptionHistoryScreen.name);
              },
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: Text(isBn ? 'হিস্ট্রি ও রিসিট দেখুন >' : 'View History & Invoices >'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionPackagesCard extends StatelessWidget {
  final UserModel user;
  final String languageCode;
  final bool isDark;

  const _SubscriptionPackagesCard({
    required this.user,
    required this.languageCode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isBn = languageCode == 'bn';
    final isOwner = user.isHouseOwner;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182422) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text(
                isBn ? 'প্রিমিয়াম সাবস্ক্রিপশন প্যাকেজ' : 'Premium Subscription Packages',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isOwner
                ? (isBn ? 'সীমাহীন টেন্যান্ট ডিমান্ড আনলক, ইনস্ট্যান্ট এসএমএস এলার্ট ও টপ বুস্টিং সুবিধা পান।' : 'Unlock unlimited tenant demands, instant SMS alerts, and top priority boosting.')
                : (isBn ? 'সীমাহীন সরাসরি মালিকের নম্বর আনলক, ভেরিফাইড ব্যাজ ও ৩০ কিমি রেডিয়াস সার্চ উপভোগ করুন।' : 'Unlock unlimited owner contact details, verified badge, and 30km radius search.'),
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (isOwner) {
                  Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
                } else {
                  Navigator.pushNamed(context, TenantSubscriptionScreen.name);
                }
              },
              icon: const Icon(Icons.stars_rounded, size: 16),
              label: Text(isBn ? 'প্যাকেজসমূহ দেখুন ও আপগ্রেড করুন >' : 'View Packages & Upgrade >'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyProfileCard extends StatelessWidget {
  final UserModel user;
  final String languageCode;
  final bool isDark;

  const _MyProfileCard({required this.user, required this.languageCode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isBn = languageCode == 'bn';
    final name = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182422) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.themeColor.withValues(alpha: 0.2),
                child: Text(
                  user.initials,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.themeColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(
                      '${user.userType} • ${user.mobile}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, MyProfileScreen.name);
              },
              icon: const Icon(Icons.person_rounded, size: 16),
              label: Text(isBn ? 'প্রোফাইল ওপেন করুন >' : 'Open My Profile >'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.themeColor,
                side: const BorderSide(color: AppColors.themeColor),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemandDraftConfirmationCard extends StatelessWidget {
  final DemandDraftModel draft;
  final UserModel user;
  final String languageCode;
  final bool isDark;

  const _DemandDraftConfirmationCard({
    required this.draft,
    required this.user,
    required this.languageCode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isBn = languageCode == 'bn';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152220) : const Color(0xFFF2FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
              const SizedBox(width: 8),
              Text(
                isBn ? 'ডিমান্ড খসড়া ও রিভিউ' : 'Demand Draft Review',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
              ),
            ],
          ),
          const Divider(height: 18),
          _itemRow('📍 এলাকা:', '${draft.area ?? "মিরপুর"} ${draft.subArea != null ? "(${draft.subArea})" : ""}'),
          _itemRow('💰 বাজেট:', '৳ ${(draft.budgetRange ?? "15000").toLocalizedDigits(languageCode)}'),
          _itemRow('🛏️ রুম / ধরণ:', '${draft.roomOrSeat ?? "Bedroom - 2"} • ${draft.tenantType ?? "Family"}'),
          _itemRow('📱 মোবাইল নম্বর:', draft.userMobile ?? user.mobile),
          _itemRow('🏢 লিফট / পার্কিং:', '${draft.hasLift == true ? "লিফট আছে" : "লিফট নেই"}, ${draft.hasParking == true ? "পার্কিং আছে" : "পার্কিং নেই"}'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AIAssistantProvider>().confirmAndPublishDemand(
                      draft: draft,
                      user: user,
                      languageCode: languageCode,
                    );
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(isBn ? '✅ হ্যাঁ, ডিমান্ড পোস্ট করুন' : '✅ Yes, Publish Demand'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _AdminStatsCard extends StatelessWidget {
  final AdminStatsModel stats;
  final String languageCode;
  final bool isDark;

  const _AdminStatsCard({required this.stats, required this.languageCode, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isBn = languageCode == 'bn';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152220) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.themeColor, size: 18),
              const SizedBox(width: 6),
              Text(
                isBn ? 'লাইভ প্ল্যাটফর্ম ডাটা' : 'Live Platform Metrics',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.themeColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metricBox('মোট প্রপার্টি', stats.totalProperties.toString(), Colors.blue, languageCode)),
              const SizedBox(width: 8),
              Expanded(child: _metricBox('মোট ইউজার', stats.totalUsers.toString(), Colors.purple, languageCode)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _metricBox('মোট ডিমান্ড', stats.totalDemands.toString(), Colors.orange, languageCode)),
              const SizedBox(width: 8),
              Expanded(child: _metricBox('রেভিনিউ (টাকা)', '৳${stats.totalRevenue.toInt()}', Colors.green, languageCode)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color, String lang) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value.toLocalizedDigits(lang),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PROPERTY CARDS CAROUSEL
// ==========================================

class _PropertyCardsCarousel extends StatelessWidget {
  final List<PropertyModel> properties;
  final String languageCode;
  final bool isDark;

  const _PropertyCardsCarousel({
    required this.properties,
    required this.languageCode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: properties.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final prop = properties[index];
          final imgUrl = prop.images.isNotEmpty ? prop.images.first : '';

          return Container(
            width: 190,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2826) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailsScreen(property: prop),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: imgUrl.isNotEmpty
                          ? Image.network(
                              imgUrl,
                              height: 95,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '৳ ${prop.amount.toLocalizedDigits(languageCode)}/মাস',
                            style: const TextStyle(
                              color: AppColors.themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${prop.area.getLocalizedName(languageCode)}, ${prop.district.getLocalizedName(languageCode)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            prop.roomOrSeat,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                languageCode == 'bn' ? 'বিস্তারিত দেখুন >' : 'Details >',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 95,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.home_rounded, color: Colors.grey, size: 36),
      ),
    );
  }
}

// ==========================================
// MATCHING DEMANDS CAROUSEL (HOUSE OWNER)
// ==========================================

class _MatchingDemandsCarousel extends StatelessWidget {
  final List<MatchingDemandItem> matchingDemands;
  final String languageCode;
  final bool isDark;

  const _MatchingDemandsCarousel({
    required this.matchingDemands,
    required this.languageCode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: matchingDemands.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = matchingDemands[index];
          final d = item.demand;

          return Container(
            width: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2826) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowDemandDetailsScreen(demand: d),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🎯 ${item.matchPercentage.toLocalizedDigits(languageCode)}%',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${d.area.getLocalizedName(languageCode)} • ৳ ${(d.budgetRange ?? "15000").toLocalizedDigits(languageCode)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.themeColor, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      d.roomOrSeat,
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          languageCode == 'bn' ? 'ডিমান্ড দেখুন >' : 'View Demand >',
                          style: const TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
