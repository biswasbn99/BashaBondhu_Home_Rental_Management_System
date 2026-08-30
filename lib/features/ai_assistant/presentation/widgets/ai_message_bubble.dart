import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../features/auth/data/providers/user_provider.dart';
import '../../../../features/home/data/models/property_model.dart';
import '../../../../features/home/presentation/screens/property_details_screen.dart';
import '../../../../features/shared/presentation/widgets/app_network_image.dart';
import '../../../../features/tenant/presentation/screens/show_demand_details_screen.dart';
import '../../data/models/ai_message_model.dart';
import '../providers/ai_assistant_provider.dart';

class AIMessageBubble extends StatelessWidget {
  const AIMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    required this.languageCode,
  });

  final AIMessageModel message;
  final bool isDark;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == AIMessageSender.user;
    final isBn = languageCode == 'bn';
    final aiProvider = context.watch<AIAssistantProvider>();
    final isSpeaking = aiProvider.currentlySpeakingMsgId == message.id;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.themeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.themeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.themeColor.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, size: 16, color: AppColors.themeColor),
            ),
          ],
        ),
      );
    }

    // AI Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Robot Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A896), AppColors.themeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2827) : const Color(0xFFF4FAF9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: AppColors.themeColor.withValues(alpha: isDark ? 0.3 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: message.isGenerating
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.themeColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isBn ? 'বাসাবন্ধু এআই খুঁজছে ও তৈরি করছে...' : 'BashaBondhu AI is analyzing...',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              message.text,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: isDark ? Colors.grey[200] : const Color(0xFF1A202C),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Footer Actions: Speaker (TTS) + Copy
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // TTS Speaker Button
                                InkWell(
                                  onTap: () {
                                    aiProvider.toggleTts(message, languageCode);
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                                          size: 14,
                                          color: isSpeaking ? AppColors.themeColor : Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isSpeaking ? (isBn ? 'থামান' : 'Stop') : (isBn ? 'শুনুন' : 'Listen'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSpeaking ? AppColors.themeColor : Colors.grey[500],
                                            fontWeight: isSpeaking ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Copy Button
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: message.text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isBn ? '📋 কপি করা হয়েছে' : '📋 Copied to clipboard'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy_rounded, size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          isBn ? 'কপি' : 'Copy',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                // 1. Matching Property Cards Carousel
                if (message.properties != null && message.properties!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      isBn ? '🏠 প্রাপ্ত ম্যাচিং বাসাগুলো:' : '🏠 Found Properties:',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.properties!.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final p = message.properties![index];
                        return _MiniPropertyCard(property: p, isDark: isDark, languageCode: languageCode);
                      },
                    ),
                  ),
                ],

                // 2. Matching Tenant Demands with Match Percentage
                if (message.matchingDemands != null && message.matchingDemands!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      isBn ? '👥 সম্ভাব্য আগ্রহী ভাড়াটিয়াদের তালিকা:' : '👥 Potential Matching Tenants:',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 145,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.matchingDemands!.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = message.matchingDemands![index];
                        return _MatchingDemandCard(item: item, isDark: isDark, languageCode: languageCode);
                      },
                    ),
                  ),
                ],

                // 3. Conversational Tenant Demand Draft Confirmation Card
                if (message.demandDraft != null) ...[
                  const SizedBox(height: 10),
                  _DemandDraftCard(
                    draft: message.demandDraft!,
                    isDark: isDark,
                    languageCode: languageCode,
                  ),
                ],

                // 4. Admin Live Stats Grid
                if (message.adminStats != null) ...[
                  const SizedBox(height: 10),
                  _AdminStatsCard(
                    stats: message.adminStats!,
                    isDark: isDark,
                    languageCode: languageCode,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPropertyCard extends StatelessWidget {
  const _MiniPropertyCard({
    required this.property,
    required this.isDark,
    required this.languageCode,
  });

  final PropertyModel property;
  final bool isDark;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.themeColor.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            PropertyDetailsScreen.name,
            arguments: property,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 88,
              width: double.infinity,
              child: AppImageWidget(
                imageSource: property.images.isNotEmpty ? property.images.first : null,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '৳ ${property.amount.toLocalizedDigits(languageCode)}',
                    style: const TextStyle(
                      color: AppColors.themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    '${property.area.getLocalizedName(languageCode)} • ${property.roomOrSeat.getLocalizedRoomOrSeat(context.localizations)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        languageCode == 'bn' ? 'বিস্তারিত দেখুন >' : 'View Details >',
                        style: const TextStyle(
                          color: AppColors.themeColor,
                          fontSize: 11,
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
    );
  }
}

class _MatchingDemandCard extends StatelessWidget {
  const _MatchingDemandCard({
    required this.item,
    required this.isDark,
    required this.languageCode,
  });

  final MatchingDemandItem item;
  final bool isDark;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final d = item.demand;
    return Container(
      width: 195,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: isDark ? 0.4 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            ShowDemandDetailsScreen.name,
            arguments: d,
          );
        },
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎯 ${item.matchPercentage}%',
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
    );
  }
}

class _DemandDraftCard extends StatelessWidget {
  const _DemandDraftCard({
    required this.draft,
    required this.isDark,
    required this.languageCode,
  });

  final DemandDraftModel draft;
  final bool isDark;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final isBn = languageCode == 'bn';
    final user = context.read<UserProvider>().user;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192D28) : const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.themeColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: AppColors.themeColor, size: 18),
              const SizedBox(width: 6),
              Text(
                isBn ? '📋 ডিমান্ড খসড়া ও প্রকাশনা' : '📋 Demand Draft & Publish',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.themeColor),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildDraftRow(isBn ? 'এলাকা:' : 'Area:', draft.area ?? 'মিরপুর'),
          _buildDraftRow(isBn ? 'বাজেট:' : 'Budget:', '৳ ${draft.budgetRange ?? "১৫,০০০"}'),
          _buildDraftRow(isBn ? 'রুম:' : 'Rooms:', draft.roomOrSeat ?? '২ বেডরুম'),
          _buildDraftRow(isBn ? 'ধরণ:' : 'Type:', draft.tenantType ?? 'Family'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                isBn ? '✅ হ্যাঁ, ডিমান্ড পোস্ট করুন' : '✅ Publish Demand Now',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              onPressed: user != null
                  ? () async {
                      final success = await context.read<AIAssistantProvider>().confirmAndPublishDemand(
                            draft: draft,
                            user: user,
                            languageCode: languageCode,
                          );
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBn ? '✨ ডিমান্ড সফলভাবে পোস্ট হয়েছে!' : '✨ Demand published!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11.5))),
        ],
      ),
    );
  }
}

class _AdminStatsCard extends StatelessWidget {
  const _AdminStatsCard({
    required this.stats,
    required this.isDark,
    required this.languageCode,
  });

  final AdminStatsModel stats;
  final bool isDark;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final isBn = languageCode == 'bn';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.blue, size: 18),
              const SizedBox(width: 6),
              Text(
                isBn ? '📊 লাইভ সিস্টেম অ্যানালিটিক্স' : '📊 Live System Analytics',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricTile(isBn ? 'মোট প্রপার্টি' : 'Total Props', '${stats.totalProperties}', Colors.teal)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile(isBn ? 'মোট ইউজার' : 'Total Users', '${stats.totalUsers}', Colors.purple)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMetricTile(isBn ? 'মোট ডিমান্ড' : 'Demands', '${stats.totalDemands}', Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile(isBn ? 'সাবস্ক্রিপশন' : 'Revenue', '৳${stats.totalRevenue.toInt()}', Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
