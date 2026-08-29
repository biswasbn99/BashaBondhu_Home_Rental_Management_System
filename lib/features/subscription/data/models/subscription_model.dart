import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionTargetRole {
  tenant,
  houseOwner,
}

class SubscriptionPlanModel {
  final String id;
  final String titleEn;
  final String titleBn;
  final String descriptionEn;
  final String descriptionBn;
  final double regularPrice;
  final double? offerPrice;
  final String offerBadgeTextEn;
  final String offerBadgeTextBn;
  final bool hasActiveOffer;
  final int durationDays;
  final int durationValue;
  final String durationUnit; // 'day', 'month', 'year'
  final String durationEn;
  final String durationBn;
  final SubscriptionTargetRole targetRole;
  final List<String> perksEn;
  final List<String> perksBn;
  final bool isPopular;
  final bool isUnlimited;
  final int displayOrder;

  const SubscriptionPlanModel({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.regularPrice,
    this.offerPrice,
    this.offerBadgeTextEn = '',
    this.offerBadgeTextBn = '',
    this.hasActiveOffer = false,
    required this.durationDays,
    this.durationValue = 0,
    this.durationUnit = 'day',
    this.durationEn = '',
    this.durationBn = '',
    required this.targetRole,
    required this.perksEn,
    required this.perksBn,
    this.isPopular = false,
    this.isUnlimited = false,
    this.displayOrder = 0,
  });

  double get effectivePrice => (hasActiveOffer && offerPrice != null) ? offerPrice! : regularPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleBn': titleBn,
      'descriptionEn': descriptionEn,
      'descriptionBn': descriptionBn,
      'regularPrice': regularPrice,
      'offerPrice': offerPrice,
      'offerBadgeTextEn': offerBadgeTextEn,
      'offerBadgeTextBn': offerBadgeTextBn,
      'hasActiveOffer': hasActiveOffer,
      'durationDays': durationDays,
      'durationValue': durationValue > 0 ? durationValue : durationDays,
      'durationUnit': durationUnit,
      'durationEn': durationEn.isNotEmpty ? durationEn : '$durationDays Days',
      'durationBn': durationBn.isNotEmpty ? durationBn : '$durationDays দিন',
      'targetRole': targetRole == SubscriptionTargetRole.tenant ? 'tenant' : 'houseOwner',
      'perksEn': perksEn,
      'perksBn': perksBn,
      'isPopular': isPopular,
      'isUnlimited': isUnlimited,
      'displayOrder': displayOrder,
    };
  }

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map, String docId) {
    final days = (map['durationDays'] as num?)?.toInt() ?? 30;
    final val = (map['durationValue'] as num?)?.toInt() ?? days;
    final unit = map['durationUnit'] as String? ?? 'day';
    return SubscriptionPlanModel(
      id: docId,
      titleEn: map['titleEn'] ?? '',
      titleBn: map['titleBn'] ?? '',
      descriptionEn: map['descriptionEn'] ?? '',
      descriptionBn: map['descriptionBn'] ?? '',
      regularPrice: (map['regularPrice'] as num?)?.toDouble() ?? 0.0,
      offerPrice: (map['offerPrice'] as num?)?.toDouble(),
      offerBadgeTextEn: map['offerBadgeTextEn'] ?? '',
      offerBadgeTextBn: map['offerBadgeTextBn'] ?? '',
      hasActiveOffer: map['hasActiveOffer'] ?? false,
      durationDays: days,
      durationValue: val,
      durationUnit: unit,
      durationEn: map['durationEn'] ?? '$days Days',
      durationBn: map['durationBn'] ?? '$days দিন',
      targetRole: map['targetRole'] == 'tenant'
          ? SubscriptionTargetRole.tenant
          : SubscriptionTargetRole.houseOwner,
      perksEn: List<String>.from(map['perksEn'] ?? []),
      perksBn: List<String>.from(map['perksBn'] ?? []),
      isPopular: map['isPopular'] ?? false,
      isUnlimited: map['isUnlimited'] ?? false,
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? titleEn,
    String? titleBn,
    String? descriptionEn,
    String? descriptionBn,
    double? regularPrice,
    double? offerPrice,
    String? offerBadgeTextEn,
    String? offerBadgeTextBn,
    bool? hasActiveOffer,
    int? durationDays,
    int? durationValue,
    String? durationUnit,
    String? durationEn,
    String? durationBn,
    SubscriptionTargetRole? targetRole,
    List<String>? perksEn,
    List<String>? perksBn,
    bool? isPopular,
    bool? isUnlimited,
    int? displayOrder,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleBn: titleBn ?? this.titleBn,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      regularPrice: regularPrice ?? this.regularPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      offerBadgeTextEn: offerBadgeTextEn ?? this.offerBadgeTextEn,
      offerBadgeTextBn: offerBadgeTextBn ?? this.offerBadgeTextBn,
      hasActiveOffer: hasActiveOffer ?? this.hasActiveOffer,
      durationDays: durationDays ?? this.durationDays,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      durationEn: durationEn ?? this.durationEn,
      durationBn: durationBn ?? this.durationBn,
      targetRole: targetRole ?? this.targetRole,
      perksEn: perksEn ?? this.perksEn,
      perksBn: perksBn ?? this.perksBn,
      isPopular: isPopular ?? this.isPopular,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

class SubscriptionTransactionModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userMobile;
  final String planId;
  final String planTitle;
  final double amountPaid;
  final String paymentMethod; // e.g. bKash
  final String transactionId; // bKash TrxID
  final String senderPhone;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final String status; // active, expired, refunded

  const SubscriptionTransactionModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userMobile,
    required this.planId,
    required this.planTitle,
    required this.amountPaid,
    this.paymentMethod = 'bKash',
    required this.transactionId,
    required this.senderPhone,
    required this.purchasedAt,
    required this.expiresAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userMobile': userMobile,
      'planId': planId,
      'planTitle': planTitle,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'senderPhone': senderPhone,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }

  factory SubscriptionTransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SubscriptionTransactionModel(
      id: docId,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userMobile: map['userMobile'] ?? '',
      planId: map['planId'] ?? '',
      planTitle: map['planTitle'] ?? '',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'bKash',
      transactionId: map['transactionId'] ?? '',
      senderPhone: map['senderPhone'] ?? '',
      purchasedAt: (map['purchasedAt'] is Timestamp)
          ? (map['purchasedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: (map['expiresAt'] is Timestamp)
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      status: map['status'] ?? 'active',
    );
  }
}

