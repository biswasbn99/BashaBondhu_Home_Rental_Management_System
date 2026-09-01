import 'package:cloud_firestore/cloud_firestore.dart';

/// Single section within a policy (e.g. "Who We Are", "Payment and Fees")
class PolicySectionModel {
  final String id;
  final String headingEn;
  final String headingBn;
  final String contentEn;
  final String contentBn;
  final int order;
  final String? iconName;

  const PolicySectionModel({
    required this.id,
    required this.headingEn,
    required this.headingBn,
    required this.contentEn,
    required this.contentBn,
    required this.order,
    this.iconName,
  });

  String getHeading(String languageCode) =>
      languageCode == 'bn' && headingBn.isNotEmpty ? headingBn : headingEn;

  String getContent(String languageCode) =>
      languageCode == 'bn' && contentBn.isNotEmpty ? contentBn : contentEn;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'headingEn': headingEn,
      'headingBn': headingBn,
      'contentEn': contentEn,
      'contentBn': contentBn,
      'order': order,
      'iconName': iconName,
    };
  }

  factory PolicySectionModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return PolicySectionModel(
      id: docId ?? map['id']?.toString() ?? '',
      headingEn: map['headingEn']?.toString() ?? '',
      headingBn: map['headingBn']?.toString() ?? '',
      contentEn: map['contentEn']?.toString() ?? '',
      contentBn: map['contentBn']?.toString() ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      iconName: map['iconName']?.toString(),
    );
  }

  PolicySectionModel copyWith({
    String? id,
    String? headingEn,
    String? headingBn,
    String? contentEn,
    String? contentBn,
    int? order,
    String? iconName,
  }) {
    return PolicySectionModel(
      id: id ?? this.id,
      headingEn: headingEn ?? this.headingEn,
      headingBn: headingBn ?? this.headingBn,
      contentEn: contentEn ?? this.contentEn,
      contentBn: contentBn ?? this.contentBn,
      order: order ?? this.order,
      iconName: iconName ?? this.iconName,
    );
  }
}

/// Full legal policy document (Privacy Policy, Support Policy, Terms & Conditions, Refund Policy)
class AppPolicyModel {
  final String id; // e.g. 'tenant_privacy_policy', 'house_owner_privacy_policy'
  final String type; // 'privacy_policy', 'support_policy', 'terms_conditions', 'refund_policy'
  final String targetAudience; // 'tenant', 'house_owner', 'all'
  final String titleEn;
  final String titleBn;
  final String subtitleEn;
  final String subtitleBn;
  final DateTime lastUpdated;
  final List<PolicySectionModel> sections;

  const AppPolicyModel({
    required this.id,
    required this.type,
    this.targetAudience = 'tenant',
    required this.titleEn,
    required this.titleBn,
    required this.subtitleEn,
    required this.subtitleBn,
    required this.lastUpdated,
    required this.sections,
  });

  String getTitle(String languageCode) =>
      languageCode == 'bn' && titleBn.isNotEmpty ? titleBn : titleEn;

  String getSubtitle(String languageCode) =>
      languageCode == 'bn' && subtitleBn.isNotEmpty ? subtitleBn : subtitleEn;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'targetAudience': targetAudience,
      'titleEn': titleEn,
      'titleBn': titleBn,
      'subtitleEn': subtitleEn,
      'subtitleBn': subtitleBn,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'sections': sections.map((s) => s.toMap()).toList(),
    };
  }

  factory AppPolicyModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
      return DateTime.now();
    }

    final rawSections = map['sections'];
    final List<PolicySectionModel> sectionList = [];
    if (rawSections is List) {
      for (int i = 0; i < rawSections.length; i++) {
        final item = rawSections[i];
        if (item is Map<String, dynamic>) {
          sectionList.add(PolicySectionModel.fromMap(item));
        } else if (item is Map) {
          sectionList.add(PolicySectionModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    sectionList.sort((a, b) => a.order.compareTo(b.order));

    return AppPolicyModel(
      id: docId,
      type: map['type']?.toString() ?? docId,
      targetAudience: map['targetAudience']?.toString() ?? (docId.startsWith('house_owner_') ? 'house_owner' : 'tenant'),
      titleEn: map['titleEn']?.toString() ?? '',
      titleBn: map['titleBn']?.toString() ?? '',
      subtitleEn: map['subtitleEn']?.toString() ?? '',
      subtitleBn: map['subtitleBn']?.toString() ?? '',
      lastUpdated: parseDate(map['lastUpdated']),
      sections: sectionList,
    );
  }

  AppPolicyModel copyWith({
    String? id,
    String? type,
    String? targetAudience,
    String? titleEn,
    String? titleBn,
    String? subtitleEn,
    String? subtitleBn,
    DateTime? lastUpdated,
    List<PolicySectionModel>? sections,
  }) {
    return AppPolicyModel(
      id: id ?? this.id,
      type: type ?? this.type,
      targetAudience: targetAudience ?? this.targetAudience,
      titleEn: titleEn ?? this.titleEn,
      titleBn: titleBn ?? this.titleBn,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      subtitleBn: subtitleBn ?? this.subtitleBn,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sections: sections ?? this.sections,
    );
  }
}

/// Frequently Asked Question model
class FaqModel {
  final String id;
  final String category; // 'general', 'finding_home', 'posting', 'management', 'safety'
  final String targetAudience; // 'tenant', 'house_owner', 'all'
  final String questionEn;
  final String questionBn;
  final String answerEn;
  final String answerBn;
  final int order;

  const FaqModel({
    required this.id,
    required this.category,
    this.targetAudience = 'all',
    required this.questionEn,
    required this.questionBn,
    required this.answerEn,
    required this.answerBn,
    required this.order,
  });

  String getQuestion(String languageCode) =>
      languageCode == 'bn' && questionBn.isNotEmpty ? questionBn : questionEn;

  String getAnswer(String languageCode) =>
      languageCode == 'bn' && answerBn.isNotEmpty ? answerBn : answerEn;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'targetAudience': targetAudience,
      'questionEn': questionEn,
      'questionBn': questionBn,
      'answerEn': answerEn,
      'answerBn': answerBn,
      'order': order,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory FaqModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return FaqModel(
      id: docId ?? map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? 'general',
      targetAudience: map['targetAudience']?.toString() ?? 'all',
      questionEn: map['questionEn']?.toString() ?? map['question']?.toString() ?? '',
      questionBn: map['questionBn']?.toString() ?? map['question_bn']?.toString() ?? map['questionBangla']?.toString() ?? map['question_bengali']?.toString() ?? '',
      answerEn: map['answerEn']?.toString() ?? map['answer']?.toString() ?? '',
      answerBn: map['answerBn']?.toString() ?? map['answer_bn']?.toString() ?? map['answerBangla']?.toString() ?? map['answer_bengali']?.toString() ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  FaqModel copyWith({
    String? id,
    String? category,
    String? targetAudience,
    String? questionEn,
    String? questionBn,
    String? answerEn,
    String? answerBn,
    int? order,
  }) {
    return FaqModel(
      id: id ?? this.id,
      category: category ?? this.category,
      targetAudience: targetAudience ?? this.targetAudience,
      questionEn: questionEn ?? this.questionEn,
      questionBn: questionBn ?? this.questionBn,
      answerEn: answerEn ?? this.answerEn,
      answerBn: answerBn ?? this.answerBn,
      order: order ?? this.order,
    );
  }
}
