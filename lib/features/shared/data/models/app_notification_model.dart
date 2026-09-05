import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String recipientType; // 'admin' or 'user'
  final String recipientId; // uid or 'admin'
  final String recipientEmail;
  final String title;
  final String titleBn;
  final String message;
  final String messageBn;
  final String type; // 'post_created', 'post_updated', 'post_deleted', 'post_approved', 'post_rejected', 'appeal_submitted', 'verification_submitted'
  final String targetType; // 'property', 'demand', 'user'
  final String targetId;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.recipientType,
    required this.recipientId,
    this.recipientEmail = '',
    required this.title,
    required this.titleBn,
    required this.message,
    required this.messageBn,
    required this.type,
    this.targetType = 'property',
    this.targetId = '',
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientType': recipientType,
      'recipientId': recipientId,
      'recipientEmail': recipientEmail,
      'title': title,
      'titleBn': titleBn,
      'message': message,
      'messageBn': messageBn,
      'type': type,
      'targetType': targetType,
      'targetId': targetId,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotificationModel(
      id: id,
      recipientType: map['recipientType'] as String? ?? 'user',
      recipientId: map['recipientId'] as String? ?? '',
      recipientEmail: map['recipientEmail'] as String? ?? '',
      title: map['title'] as String? ?? '',
      titleBn: map['titleBn'] as String? ?? '',
      message: map['message'] as String? ?? '',
      messageBn: map['messageBn'] as String? ?? '',
      type: map['type'] as String? ?? 'post_created',
      targetType: map['targetType'] as String? ?? 'property',
      targetId: map['targetId'] as String? ?? '',
      data: map['data'] is Map ? Map<String, dynamic>.from(map['data'] as Map) : {},
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parseDate(map['createdAt']),
    );
  }

  AppNotificationModel copyWith({
    String? id,
    String? recipientType,
    String? recipientId,
    String? recipientEmail,
    String? title,
    String? titleBn,
    String? message,
    String? messageBn,
    String? type,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      recipientType: recipientType ?? this.recipientType,
      recipientId: recipientId ?? this.recipientId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      title: title ?? this.title,
      titleBn: titleBn ?? this.titleBn,
      message: message ?? this.message,
      messageBn: messageBn ?? this.messageBn,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

