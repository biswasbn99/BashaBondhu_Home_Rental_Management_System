import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../data/models/app_notification_model.dart';
import '../../data/services/notification_firestore_service.dart';
import 'user_notifications_modal.dart';

class UserNotificationBellButton extends StatelessWidget {
  const UserNotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final UserModel? user = userProvider.user;
    final bool isGuest = userProvider.isGuest || user == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isGuest) {
      return const SizedBox.shrink();
    }

    final userId = user.uid;
    final userEmail = user.email;

    return StreamBuilder<List<AppNotificationModel>>(
      stream: NotificationFirestoreService().streamUserNotifications(userId, userEmail: userEmail),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: unreadCount > 0 ? Colors.amber.shade700 : (isDark ? Colors.grey[300] : Colors.grey[700]),
                size: 22,
              ),
              tooltip: Localizations.localeOf(context).languageCode == 'bn'
                  ? 'নোটিফিকেশন ($unreadCount)'
                  : 'Notifications ($unreadCount)',
              onPressed: () => UserNotificationsModal.show(context),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F201D) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
