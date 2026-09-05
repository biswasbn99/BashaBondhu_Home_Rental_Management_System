import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification_model.dart';

class NotificationFirestoreService {
  static final NotificationFirestoreService _instance = NotificationFirestoreService._internal();
  factory NotificationFirestoreService() => _instance;
  NotificationFirestoreService._internal();

  final CollectionReference _notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  /// Create and dispatch a new notification document
  Future<String> createNotification(AppNotificationModel notification) async {
    try {
      // If updating or recreating a post notification for admin, clean up previous notifications for the same post
      if (notification.recipientType == 'admin' &&
          notification.targetId.isNotEmpty &&
          (notification.type == 'post_updated' || notification.type == 'post_created' || notification.type == 'post_deleted')) {
        try {
          final oldDocs = await _notificationsCollection
              .where('recipientType', isEqualTo: 'admin')
              .where('targetId', isEqualTo: notification.targetId)
              .get();
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in oldDocs.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Error cleaning up previous post notifications: $e');
        }
      }

      final docRef = _notificationsCollection.doc();
      final item = notification.copyWith(id: docRef.id);
      await docRef.set(item.toMap());
      debugPrint('🔔 Notification dispatched: ${item.title} -> ${item.recipientType}:${item.recipientId}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      return '';
    }
  }

  /// Stream all notifications intended for Admin (sorted newest first, latest only per post)
  Stream<List<AppNotificationModel>> streamAdminNotifications({bool onlyUnread = false}) {
    return _notificationsCollection.snapshots().map((snapshot) {
      final List<AppNotificationModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final n = AppNotificationModel.fromMap(data, doc.id);
            if (n.recipientType == 'admin' && (!onlyUnread || !n.isRead)) {
              list.add(n);
            }
          } else if (data is Map) {
            final n = AppNotificationModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            if (n.recipientType == 'admin' && (!onlyUnread || !n.isRead)) {
              list.add(n);
            }
          }
        } catch (e) {
          debugPrint('Error parsing admin notification ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Dedup by targetId so only the latest notification per post is kept
      final Map<String, AppNotificationModel> latestByTarget = {};
      final List<AppNotificationModel> finalList = [];

      for (final notif in list) {
        if (notif.targetId.isNotEmpty) {
          final key = '${notif.targetType}_${notif.targetId}';
          if (!latestByTarget.containsKey(key)) {
            latestByTarget[key] = notif;
            finalList.add(notif);
          }
        } else {
          finalList.add(notif);
        }
      }

      return finalList;
    });
  }

  /// Stream notifications for a specific user (tenant or house owner)
  Stream<List<AppNotificationModel>> streamUserNotifications(String userId, {String? userEmail}) {
    final cleanId = userId.trim();
    final cleanEmail = (userEmail ?? '').trim().toLowerCase();

    return _notificationsCollection.snapshots().map((snapshot) {
      final List<AppNotificationModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final n = AppNotificationModel.fromMap(data, doc.id);
            final bool matchesId = cleanId.isNotEmpty && n.recipientId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && n.recipientEmail.trim().toLowerCase() == cleanEmail;
            if (n.recipientType == 'user' && (matchesId || matchesEmail)) {
              list.add(n);
            }
          } else if (data is Map) {
            final n = AppNotificationModel.fromMap(Map<String, dynamic>.from(data), doc.id);
            final bool matchesId = cleanId.isNotEmpty && n.recipientId == cleanId;
            final bool matchesEmail = cleanEmail.isNotEmpty && n.recipientEmail.trim().toLowerCase() == cleanEmail;
            if (n.recipientType == 'user' && (matchesId || matchesEmail)) {
              list.add(n);
            }
          }
        } catch (e) {
          debugPrint('Error parsing user notification ${doc.id}: $e');
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).set({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all admin notifications as read
  Future<void> markAllAdminNotificationsAsRead() async {
    try {
      final snap = await _notificationsCollection.where('recipientType', isEqualTo: 'admin').where('isRead', isEqualTo: false).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all admin notifications as read: $e');
    }
  }

  /// Mark all user notifications as read
  Future<void> markAllUserNotificationsAsRead(String userId, {String? userEmail}) async {
    try {
      final snap = await _notificationsCollection.where('recipientType', isEqualTo: 'user').where('recipientId', isEqualTo: userId).where('isRead', isEqualTo: false).get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking user notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications for admin
  Future<void> clearAllAdminNotifications() async {
    try {
      final snap = await _notificationsCollection.where('recipientType', isEqualTo: 'admin').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing admin notifications: $e');
    }
  }
}

