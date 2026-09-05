import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../home/data/models/property_model.dart';
import '../../../house_owner/presentation/screens/edit_rent_post_screen.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../../tenant/presentation/screens/edit_demand_screen.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/services/notification_firestore_service.dart';

class UserNotificationsModal extends StatelessWidget {
  const UserNotificationsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const UserNotificationsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.user;

    final modalBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final cardBg = isDark ? const Color(0xFF162B27) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final notificationService = NotificationFirestoreService();
    final userId = user?.uid ?? '';
    final userEmail = user?.email ?? '';

    return Dialog(
      backgroundColor: modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<List<AppNotificationModel>>(
          stream: notificationService.streamUserNotifications(userId, userEmail: userEmail),
          builder: (context, snapshot) {
            final notifications = snapshot.data ?? [];
            final unreadCount = notifications.where((n) => !n.isRead).length;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.themeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: AppColors.themeColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBn ? 'নোটিফিকেশন ও বার্তা' : 'Notifications & Messages',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                              ),
                            ),
                            if (unreadCount > 0)
                              Text(
                                isBn ? '$unreadCount টি অপঠিত নোটিফিকেশন' : '$unreadCount unread notifications',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (unreadCount > 0)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            onPressed: () => notificationService.markAllUserNotificationsAsRead(userId, userEmail: userEmail),
                            icon: const Icon(Icons.done_all_rounded, size: 15, color: AppColors.themeColor),
                            label: Text(
                              isBn ? 'সব পড়া হয়েছে' : 'Mark all read',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.themeColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: subtitleColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),

                // Notification List
                Expanded(
                  child: notifications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.notifications_off_outlined, size: 40, color: subtitleColor),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  isBn ? 'আপনার কোনো নোটিফিকেশন নেই' : 'No notifications yet',
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: titleColor),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isBn
                                      ? 'বিজ্ঞাপন অনুমোদন, প্রত্যাখ্যান বা পোস্ট সংক্রান্ত বার্তা এখানে দেখা যাবে।'
                                      : 'Post approvals, rejections and important alerts will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: subtitleColor),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = notifications[index];
                            return _buildNotificationCard(
                              context: context,
                              notification: notif,
                              isBn: isBn,
                              isDark: isDark,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              titleColor: titleColor,
                              subtitleColor: subtitleColor,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required AppNotificationModel notification,
    required bool isBn,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final isRejected = notification.type == 'post_rejected';
    final isApproved = notification.type == 'post_approved';

    Color themeColor;
    IconData iconData;
    if (isRejected) {
      themeColor = const Color(0xFFEF4444);
      iconData = Icons.cancel_rounded;
    } else if (isApproved) {
      themeColor = const Color(0xFF10B981);
      iconData = Icons.check_circle_rounded;
    } else {
      themeColor = AppColors.themeColor;
      iconData = Icons.notifications_rounded;
    }

    final title = isBn
        ? (notification.titleBn.isNotEmpty ? notification.titleBn : notification.title)
        : notification.title;
    final message = isBn
        ? (notification.messageBn.isNotEmpty ? notification.messageBn : notification.message)
        : notification.message;

    final rejectionReason = notification.data['rejectionReason'] as String? ?? '';
    final timeStr = _formatTimeAgo(notification.createdAt, isBn);

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          NotificationFirestoreService().markAsRead(notification.id);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? cardBg
              : (isRejected
                  ? (isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2))
                  : (isDark ? const Color(0xFF132B25) : const Color(0xFFF0FDF4))),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? borderColor
                : themeColor.withValues(alpha: 0.5),
            width: notification.isRead ? 1 : 1.3,
          ),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: themeColor.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: Icon + Title + Time + Delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData, color: themeColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isRejected ? themeColor : titleColor,
                              ),
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12,
                          color: titleColor.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: subtitleColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: isBn ? 'মুছে ফেলুন' : 'Delete',
                  onPressed: () => NotificationFirestoreService().deleteNotification(notification.id),
                ),
              ],
            ),

            // If Rejected: Reason Card & Direct Edit Action Button
            if (isRejected && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF381818) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 15, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${isBn ? 'প্রত্যাখ্যানের কারণ: ' : 'Reason: '}$rejectionReason",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Direct Edit & Correct Button for Rejected Posts
            if (isRejected && notification.targetId.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(
                    isBn ? 'সংশোধন ও আপডেট করুন' : 'Edit & Correct Post',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    Navigator.pop(context); // Close notification modal
                    _navigateToEditPost(context, notification);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditPost(BuildContext context, AppNotificationModel notification) async {
    final messenger = ScaffoldMessenger.of(context);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    try {
      if (notification.targetType == 'property') {
        final doc = await FirebaseFirestore.instance.collection('properties').doc(notification.targetId).get();
        if (doc.exists && doc.data() != null && context.mounted) {
          final property = PropertyModel.fromMap(doc.data()!, doc.id);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditRentPostScreen(property: property)),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(isBn ? 'পোস্টটি পাওয়া যায়নি বা মুছে ফেলা হয়েছে।' : 'Post not found or deleted.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else if (notification.targetType == 'demand') {
        final doc = await FirebaseFirestore.instance.collection('tenant_demands').doc(notification.targetId).get();
        if (doc.exists && doc.data() != null && context.mounted) {
          final demand = TenantDemandModel.fromMap(doc.data()!, doc.id);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EditDemandScreen(demand: demand)),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(isBn ? 'চাহিদা পোস্টটি পাওয়া যায়নি বা মুছে ফেলা হয়েছে।' : 'Demand post not found or deleted.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  String _formatTimeAgo(DateTime dt, bool isBn) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return isBn ? 'এখনই' : 'just now';
    } else if (diff.inMinutes < 60) {
      return isBn ? '${diff.inMinutes} মিনিট আগে' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return isBn ? '${diff.inHours} ঘণ্টা আগে' : '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return isBn ? '${diff.inDays} দিন আগে' : '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
