import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/policy_model.dart';

class PolicyFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _policiesCol =>
      _firestore.collection('app_policies');

  CollectionReference<Map<String, dynamic>> get _faqsCol =>
      _firestore.collection('faqs');

  String getPolicyDocId(String policyType, String targetAudience) {
    if (policyType.startsWith('tenant_') || policyType.startsWith('house_owner_')) {
      return policyType;
    }
    return '${targetAudience}_$policyType';
  }

  // -------------------------------------------------------------
  // 1. POLICIES (Tenant & House Owner)
  // -------------------------------------------------------------

  Stream<AppPolicyModel> streamPolicy(String policyType, {String targetAudience = 'tenant'}) {
    final docId = getPolicyDocId(policyType, targetAudience);
    return _policiesCol.doc(docId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppPolicyModel.fromMap(doc.data()!, doc.id);
      }
      return _getDefaultPolicy(policyType, targetAudience);
    });
  }

  Future<AppPolicyModel> getPolicy(String policyType, {String targetAudience = 'tenant'}) async {
    final docId = getPolicyDocId(policyType, targetAudience);
    final doc = await _policiesCol.doc(docId).get();
    if (doc.exists && doc.data() != null) {
      return AppPolicyModel.fromMap(doc.data()!, doc.id);
    }
    return _getDefaultPolicy(policyType, targetAudience);
  }

  Future<void> savePolicy(AppPolicyModel policy) async {
    await _policiesCol.doc(policy.id).set(policy.toMap(), SetOptions(merge: true));
  }

  Future<void> savePolicySection(
    String policyType,
    PolicySectionModel section, {
    String targetAudience = 'tenant',
  }) async {
    final docId = getPolicyDocId(policyType, targetAudience);
    final current = await getPolicy(policyType, targetAudience: targetAudience);
    final sections = List<PolicySectionModel>.from(current.sections);

    final idx = sections.indexWhere((s) => s.id == section.id);
    if (idx >= 0) {
      sections[idx] = section;
    } else {
      sections.add(section);
    }

    final updated = current.copyWith(
      id: docId,
      targetAudience: targetAudience,
      sections: sections,
      lastUpdated: DateTime.now(),
    );
    await savePolicy(updated);
  }

  Future<void> deletePolicySection(
    String policyType,
    String sectionId, {
    String targetAudience = 'tenant',
  }) async {
    final docId = getPolicyDocId(policyType, targetAudience);
    final current = await getPolicy(policyType, targetAudience: targetAudience);
    final sections = current.sections.where((s) => s.id != sectionId).toList();

    final updated = current.copyWith(
      id: docId,
      targetAudience: targetAudience,
      sections: sections,
      lastUpdated: DateTime.now(),
    );
    await savePolicy(updated);
  }

  Future<void> resetPolicyToDefault(String policyType, {String targetAudience = 'tenant'}) async {
    final defaultPolicy = _getDefaultPolicy(policyType, targetAudience);
    await savePolicy(defaultPolicy);
  }

  // -------------------------------------------------------------
  // 2. FAQS (Tenant, House Owner, All)
  // -------------------------------------------------------------

  Stream<List<FaqModel>> streamFaqs({String category = 'all', String targetAudience = 'all'}) {
    return _faqsCol.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _filterFaqs(_getDefaultFaqs(), category, targetAudience);
      }
      final list = snapshot.docs.map((doc) => FaqModel.fromMap(doc.data(), doc.id)).toList();
      return _filterFaqs(list, category, targetAudience);
    });
  }

  List<FaqModel> _filterFaqs(List<FaqModel> list, String category, String targetAudience) {
    var filtered = list;
    if (category != 'all') {
      filtered = filtered.where((f) => f.category == category).toList();
    }
    if (targetAudience != 'all') {
      filtered = filtered.where((f) => f.targetAudience == 'all' || f.targetAudience == targetAudience).toList();
    }
    filtered.sort((a, b) => a.order.compareTo(b.order));
    return filtered;
  }

  Future<void> saveFaq(FaqModel faq) async {
    final docRef = faq.id.isEmpty ? _faqsCol.doc() : _faqsCol.doc(faq.id);
    final toSave = faq.copyWith(id: docRef.id);
    await docRef.set(toSave.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteFaq(String faqId) async {
    await _faqsCol.doc(faqId).delete();
  }

  // -------------------------------------------------------------
  // 3. RICH DEFAULT DATASETS (Bilingual & Role-Tailored)
  // -------------------------------------------------------------

  AppPolicyModel _getDefaultPolicy(String rawType, String targetAudience) {
    final type = rawType.replaceFirst('tenant_', '').replaceFirst('house_owner_', '');
    final docId = '${targetAudience}_$type';

    if (targetAudience == 'house_owner') {
      switch (type) {
        case 'privacy_policy':
          return _getHouseOwnerDefaultPrivacyPolicy(docId);
        case 'support_policy':
          return _getHouseOwnerDefaultSupportPolicy(docId);
        case 'terms_conditions':
          return _getHouseOwnerDefaultTermsConditions(docId);
        case 'refund_policy':
          return _getHouseOwnerDefaultRefundPolicy(docId);
        default:
          return _getHouseOwnerDefaultPrivacyPolicy(docId);
      }
    } else {
      // Default to Tenant
      switch (type) {
        case 'privacy_policy':
          return _getTenantDefaultPrivacyPolicy(docId);
        case 'support_policy':
          return _getTenantDefaultSupportPolicy(docId);
        case 'terms_conditions':
          return _getTenantDefaultTermsConditions(docId);
        case 'refund_policy':
          return _getTenantDefaultRefundPolicy(docId);
        default:
          return _getTenantDefaultPrivacyPolicy(docId);
      }
    }
  }

  // ==========================================
  // A. TENANT DEFAULT POLICIES (ভাড়াটিয়া)
  // ==========================================

  AppPolicyModel _getTenantDefaultPrivacyPolicy(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'privacy_policy',
      targetAudience: 'tenant',
      titleEn: 'Tenant Privacy Policy',
      titleBn: 'ভাড়াটিয়া গোপনীয়তা নীতি',
      subtitleEn: 'How BashaBondhu protects renter personal data, search history, and rental demand information.',
      subtitleBn: 'বাসাবন্ধুতে ভাড়াটিয়াদের ব্যক্তিগত তথ্য, খোঁজার ইতিহাস ও ভাড়ার চাহিদা সুরক্ষার নিয়মাবলী।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 't_sec_1',
          order: 1,
          iconName: 'privacy_tip_outlined',
          headingEn: '1. Personal Information Collected from Renters',
          headingBn: '১. ভাড়াটিয়াদের সংগৃহীত ব্যক্তিগত তথ্য',
          contentEn:
              'When tenants register or use BashaBondhu, we collect essential information including full name, verified phone number, email address, profile photo, preferred rental location, budget range, and specific requirements provided in "Tenant Demand" posts.',
          contentBn:
              'বাসাবন্ধুতে রেজিস্ট্রেশন বা ব্যবহারের সময় আমরা ভাড়াটিয়াদের নাম, ভেরিফাইড মোবাইল নম্বর, ইমেইল, প্রোফাইল ছবি, পছন্দের এলাকা, ভাড়ার বাজেট এবং "ভাড়ার চাহিদা" পোস্টে দেওয়া তথ্য নিরাপদভাবে সংরক্ষণ করি।',
        ),
        const PolicySectionModel(
          id: 't_sec_2',
          order: 2,
          iconName: 'security_rounded',
          headingEn: '2. Communication & Contact Privacy with Landlords',
          headingBn: '২. বাড়িওয়ালাদের সাথে যোগাযোগ ও তথ্যের গোপনীয়তা',
          contentEn:
              'Your phone number and direct contact details are only disclosed to verified house owners when you initiate an inquiry, book a visit, or publish a public rental demand. We never sell your personal contact list to third-party telemarketers.',
          contentBn:
              'আপনার মোবাইল নম্বর ও যোগাযোগের তথ্য কেবল তখনই ভেরিফাইড বাড়িওয়ালাকে প্রদান করা হয় যখন আপনি সরাসরি বাসা দেখার অনুরোধ বা ভাড়ার চাহিদা পোস্ট করেন। আমরা কখনোই তৃতীয় কোনো বিপণন প্রতিষ্ঠানের কাছে তথ্য বিক্রি করি না।',
        ),
        const PolicySectionModel(
          id: 't_sec_3',
          order: 3,
          iconName: 'lock_outline_rounded',
          headingEn: '3. Data Security & Storage in Bangladesh',
          headingBn: '৩. ডাটা নিরাপত্তা ও ক্লাউড স্টোরেজ',
          contentEn:
              'All search preferences, wishlist bookmarks, and demand histories are encrypted using industry-standard SSL/TLS protocols and Google Cloud infrastructure, preventing unauthorized data breaches.',
          contentBn:
              'ভাড়াটিয়াদের পছন্দতালিকা, উইশলিস্ট ও চাহিদার সমস্ত তথ্য আধুনিক SSL/TLS এনক্রিপশন ও গুগল ক্লাউড সার্ভারে নিরাপদে সংরক্ষিত থাকে।',
        ),
        const PolicySectionModel(
          id: 't_sec_4',
          order: 4,
          iconName: 'delete_forever_outlined',
          headingEn: '4. Tenant Account Deletion & Right to Forget',
          headingBn: '৪. অ্যাকাউন্ট মুছে ফেলা ও তথ্যের নিয়ন্ত্রণ',
          contentEn:
              'Tenants hold the right to edit their rental demands at any time or request complete account deletion via Profile Settings or by emailing privacy@bashabondhu.com. Upon request, personal identification records are erased within 30 days.',
          contentBn:
              'ভাড়াটিয়ারা যেকোনো সময় প্রোফাইল থেকে তাদের ভাড়ার চাহিদা ডিলিট করতে পারেন অথবা সম্পূর্ণ অ্যাকাউন্ট মুছে ফেলার অনুরোধ করতে পারেন। অনুরোধের ৩০ দিনের মধ্যে সমস্ত ব্যক্তিগত রেকর্ড সিস্টেম থেকে স্থায়ীভাবে মুছে ফেলা হয়।',
        ),
      ],
    );
  }

  AppPolicyModel _getTenantDefaultSupportPolicy(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'support_policy',
      targetAudience: 'tenant',
      titleEn: 'Tenant Support Policy',
      titleBn: 'ভাড়াটিয়া সাপোর্ট পলিসি',
      subtitleEn: 'Dedicated customer assistance and issue resolution standards for property seekers.',
      subtitleBn: 'বাসা সন্ধানকারী ভাড়াটিয়াদের জন্য কাস্টমার সেবা, হেল্পলাইন ও বিরোধ নিষ্পত্তি নীতিমালা।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 't_sup_1',
          order: 1,
          iconName: 'support_agent_rounded',
          headingEn: '1. Renter Support Channels & Hotline Hours',
          headingBn: '১. ভাড়াটিয়া সহায়তা চ্যানেল ও হেল্পলাইন সময়',
          contentEn:
              'Our dedicated tenant assistance desk operates Saturday through Thursday from 9:00 AM to 9:00 PM BST.\n• Customer Hotline: +880 1700-000000\n• Direct Email: tenant-support@bashabondhu.com\n• In-App BashaBondhu AI Assistant (24/7 Availability)',
          contentBn:
              'ভাড়াটিয়াদের জন্য আমাদের হেল্পডেস্ক শনিবার থেকে বৃহস্পতিবার সকাল ৯:০০ টা থেকে রাত ৯:০০ টা পর্যন্ত সক্রিয় থাকে।\n• গ্রাহক সেবা হেল্পলাইন: +৮৮০ ১৭০০-০০০০০০\n• ইমেইল সাপোর্ট: tenant-support@bashabondhu.com\n• ইন-অ্যাপ বাসাবন্ধু এআই অ্যাসিস্ট্যান্ট (২৪/৭ দিন-রাত সচল)',
        ),
        const PolicySectionModel(
          id: 't_sup_2',
          order: 2,
          iconName: 'schedule_rounded',
          headingEn: '2. Response Times & Dispute Assistance',
          headingBn: '২. রেসপন্স টাইম ও বাড়িওয়ালার সাথে বিরোধ সমাধান',
          contentEn:
              'We guarantee first response within 2 business hours for critical issues such as fake property reportings or harassment. For general inquiries, resolution is provided within 24 business hours.',
          contentBn:
              'ভুয়া বিজ্ঞাপন বা অনাকাঙ্ক্ষিত আচরণের রিপোর্টের ক্ষেত্রে আমরা ২ কর্মঘণ্টার মধ্যে রেসপন্স নিশ্চিত করি। সাধারণ যেকোনো প্রশ্নের উত্তর ২৪ কর্মঘণ্টার মধ্যে সমাধান করা হয়।',
        ),
        const PolicySectionModel(
          id: 't_sup_3',
          order: 3,
          iconName: 'report_problem_outlined',
          headingEn: '3. Reporting Misleading Listings',
          headingBn: '৩. ভুল বা বিভ্রান্তিকর বিজ্ঞাপনের অভিযোগ',
          contentEn:
              'If a tenant finds that a home rental ad differs drastically from reality (e.g. higher rent demanded, fake images), they can report the listing immediately via the "Report Problem" button for prompt investigation.',
          contentBn:
              'যদি কোনো বাড়িওয়ালা বিজ্ঞাপনের চেয়ে অতিরিক্ত ভাড়া দাবি করেন অথবা ভুল ছবি ব্যবহার করেন, তবে ভাড়াটিয়ারা তাৎক্ষণিকভাবে অ্যাপের "রিপোর্ট" অপশন ব্যবহার করে ব্যবস্থা নেওয়ার আবেদন করতে পারেন।',
        ),
      ],
    );
  }

  AppPolicyModel _getTenantDefaultTermsConditions(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'terms_conditions',
      targetAudience: 'tenant',
      titleEn: 'Tenant Terms & Conditions',
      titleBn: 'ভাড়াটিয়া ব্যবহারের শর্তাবলী',
      subtitleEn: 'Rules, conduct standards, and agreements governing renters on the BashaBondhu platform.',
      subtitleBn: 'বাসাবন্ধু প্ল্যাটফর্মে বাসা সন্ধানকারী ভাড়াটিয়াদের করণীয়, নিয়মাবলী ও আইনি নীতিমালা।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 't_tc_1',
          order: 1,
          iconName: 'gavel_rounded',
          headingEn: '1. Authentic Profile & Honest Demands',
          headingBn: '১. সঠিক প্রোফাইল তথ্য ও ভাড়ার চাহিদা প্রদান',
          contentEn:
              'Tenants must provide genuine contact numbers and honest details when creating demands or communicating with landlords. Submitting deceptive requirements or spamming property owners is strictly prohibited.',
          contentBn:
              'ভাড়াটিয়াদের অবশ্যই নিজস্ব সঠিক ফোন নম্বর ও তথ্যাদি ব্যবহার করতে হবে। মিথ্যা ভাড়ার চাহিদা পোস্ট করা বা বাড়িওয়ালাদের অযথা বিরক্ত করা সম্পূর্ণ নিষিদ্ধ।',
        ),
        const PolicySectionModel(
          id: 't_tc_2',
          order: 2,
          iconName: 'home_work_outlined',
          headingEn: '2. Physical Home Inspection & Booking Diligence',
          headingBn: '২. সরাসরি বাসা পরিদর্শন ও ভাড়া চুক্তি',
          contentEn:
              'Tenants are strongly encouraged to physically inspect the property, check water/gas/electricity facilities, and review the landlord\'s tenancy agreement before making any advance financial transactions.',
          contentBn:
              'ভাড়াটিয়াদের যে-কোনো অগ্রিম আর্থিক লেনদেনের পূর্বে সরাসরি বাসা পরিদর্শন, বিদ্যুৎ/গ্যাস/পানি সুবিধা যাচাই এবং বাড়িওয়ালার সাথে লিখিত চুক্তি নিশ্চিত করার পরামর্শ দেওয়া হচ্ছে।',
        ),
        const PolicySectionModel(
          id: 't_tc_3',
          order: 3,
          iconName: 'verified_user_outlined',
          headingEn: '3. Platform Scope & Limitation of Liability',
          headingBn: '৩. প্ল্যাটফর্মের ভূমিকা ও দায়বদ্ধতার সীমাবদ্ধতা',
          contentEn:
              'BashaBondhu connects tenants and property owners. We do not act as direct landlords or tenant guarantors. Any personal tenancy disputes, security deposit returns, or property damages must be settled between tenant and landlord in accordance with the Laws of Bangladesh.',
          contentBn:
              'বাসাবন্ধু একটি ডিজিটাল কানেক্টিং প্ল্যাটফর্ম। বাড়িওয়ালা ও ভাড়াটিয়ার মধ্যকার চুক্তিভঙ্গ, জামানতের টাকা ফেরত বা বাসার অভ্যন্তরীণ ক্ষতির জন্য বাসাবন্ধু আর্থিক দায় বহন করে না; যা বাংলাদেশের প্রচলিত আইন অনুযায়ী উভয় পক্ষ মীমাংসা করবেন।',
        ),
      ],
    );
  }

  AppPolicyModel _getTenantDefaultRefundPolicy(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'refund_policy',
      targetAudience: 'tenant',
      titleEn: 'Tenant Refund Policy',
      titleBn: 'ভাড়াটিয়া রিফান্ড পলিসি',
      subtitleEn: 'Refund eligibility, subscription cancellation, and dispute settlement for tenants.',
      subtitleBn: 'ভাড়াটিয়াদের সাবস্ক্রিপশন ফি রিফান্ড, বাতিলকরণ ও অর্থ ফেরতের নিয়মাবলী।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 't_rf_1',
          order: 1,
          iconName: 'replay_rounded',
          headingEn: '1. Tenant Subscription & Service Fee Refunds',
          headingBn: '১. ভাড়াটিয়া সাবস্ক্রিপশন ও প্রিমিয়াম ফি রিফান্ড',
          contentEn:
              'If a tenant accidentally purchases a duplicate subscription package or experiences a technical billing failure, they are eligible for a 100% refund within 48 hours of payment.',
          contentBn:
              'যদি কোনো ভাড়াটিয়া ভুলবশত ডুপ্লিকেট সাবস্ক্রিপশন ক্রয় করেন অথবা কারিগরি সমস্যার কারণে অতিরিক্ত টাকা কেটে নেওয়া হয়, তবে ৪৮ ঘণ্টার মধ্যে আবেদন করলে ১০০% টাকা রিফান্ড করা হবে।',
        ),
        const PolicySectionModel(
          id: 't_rf_2',
          order: 2,
          iconName: 'account_balance_wallet_outlined',
          headingEn: '2. Refund Processing Time (5-10 Working Days)',
          headingBn: '২. রিফান্ড প্রসেসিং সময় (৫-১০ কর্মদিবস)',
          contentEn:
              'Approved refunds are credited directly to the original payment channel (bKash, Nagad, Rocket, or Bank Card) within 5 to 10 working days.',
          contentBn:
              'অনুমোদিত রিফান্ডের অর্থ যে পেমেন্ট মাধ্যম (বিকাশ, নগদ, রকেট বা ব্যাংক কার্ড) দিয়ে পরিশোধ করা হয়েছিল, আগামী ৫ থেকে ১০ কর্মদিবসের মধ্যে সরাসরি সেখানে ফেরত দেওয়া হবে।',
        ),
        const PolicySectionModel(
          id: 't_rf_3',
          order: 3,
          iconName: 'block_rounded',
          headingEn: '3. Rental Security Deposits (Non-Platform Handled)',
          headingBn: '৩. বাসার অগ্রিম জামানত সংক্রান্ত অর্থ',
          contentEn:
              'Please note that advance house deposits paid directly to house owners are strictly governed by the rental agreement between renter and landlord. BashaBondhu does not directly hold or refund home rental advance deposits.',
          contentBn:
              'বাড়িওয়ালাকে সরাসরি প্রদানকৃত বাসার জামানত বা অগ্রিম ভাড়া বাসাবন্ধুর অ্যাকাউন্টে জমা হয় না, তাই জামানত ফেরতের বিষয়টি বাড়িওয়ালার সাথে স্বাক্ষরিত চুক্তি অনুযায়ী প্রযোজ্য হবে।',
        ),
      ],
    );
  }

  // ==========================================
  // B. HOUSE OWNER DEFAULT POLICIES (বাড়িওয়ালা)
  // ==========================================

  AppPolicyModel _getHouseOwnerDefaultPrivacyPolicy(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'privacy_policy',
      targetAudience: 'house_owner',
      titleEn: 'House Owner Privacy Policy',
      titleBn: 'বাড়িওয়ালা গোপনীয়তা নীতি',
      subtitleEn: 'How BashaBondhu safeguards landlord identities, property ownership documents, and listing data.',
      subtitleBn: 'বাসাবন্ধুতে বাড়িওয়ালাদের পরিচয়, হোল্ডিং ও মালিকানা সংক্রান্ত তথ্য এবং বিজ্ঞাপনের সুরক্ষা নীতি।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 'h_sec_1',
          order: 1,
          iconName: 'privacy_tip_outlined',
          headingEn: '1. Information Collected from Property Owners',
          headingBn: '১. বাড়িওয়ালাদের সংগৃহীত তথ্যাবলী',
          contentEn:
              'When property owners publish listings, we collect owner name, contact number, NID/Passport verification data, exact building address, photos, rental price, holding specifications, and utility availability details.',
          contentBn:
              'বিজ্ঞাপন পোস্ট করার সময় আমরা বাড়িওয়ালার নাম, যোগাযোগের ফোন নম্বর, জাতীয় পরিচয়পত্র ভেরিফিকেশন ডাটা, বাড়ির সঠিক ঠিকানা, ছবি, ভাড়ার পরিমাণ ও ইউটিলিটি তথ্যাদি সংগ্রহ করি।',
        ),
        const PolicySectionModel(
          id: 'h_sec_2',
          order: 2,
          iconName: 'domain_verification_rounded',
          headingEn: '2. Confidentiality of Sensitive Property Records',
          headingBn: '২. মালিকানা ও গোপনীয় দলিলের সুরক্ষা',
          contentEn:
              'Property verification documents submitted for "Verified Landlord" badges are kept strictly confidential and stored in encrypted enterprise storage. Only authorized audit officers can access these records.',
          contentBn:
              'ভেরিফায়েড ব্যাজের জন্য বাড়িওয়ালা কর্তৃক জমাকৃত মালিকানা ও ট্যাক্স সংক্রান্ত দলিলাদি অত্যন্ত সুরক্ষিত সার্ভারে এনক্রিপ্ট অবস্থায় সংরক্ষিত থাকে এবং কোনো বহিরাগত ব্যক্তির সাথে শেয়ার করা হয় না।',
        ),
        const PolicySectionModel(
          id: 'h_sec_3',
          order: 3,
          iconName: 'visibility_outlined',
          headingEn: '3. Public Listing Visibility & Contact Display',
          headingBn: '৩. বিজ্ঞাপনের দৃশ্যমানতা ও ফোন নম্বর প্রদর্শন',
          contentEn:
              'Property owners have full control to display or mask their direct phone numbers and choose whether interested tenants must contact via in-app request or direct call.',
          contentBn:
              'বাড়িওয়ালারা তাদের সুবিধানুযায়ী সরাসরি ফোন নম্বর প্রদর্শনের স্বাধীনতা উপভোগ করেন অথবা ইন-অ্যাপ বার্তার মাধ্যমে ভাড়াটিয়ার তথ্য যাচাই করে যোগাযোগ করতে পারেন।',
        ),
      ],
    );
  }

  AppPolicyModel _getHouseOwnerDefaultSupportPolicy(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'support_policy',
      targetAudience: 'house_owner',
      titleEn: 'House Owner Support Policy',
      titleBn: 'বাড়িওয়ালা সাপোর্ট পলিসি',
      subtitleEn: 'Dedicated priority support, listing approvals, and technical assistance for landlords.',
      subtitleBn: 'বাড়িওয়ালাদের জন্য প্রায়োরিটি লিস্টিং অ্যাপ্রুভাল, বিজ্ঞাপন বুস্ট সহায়তা ও হেল্পলাইন গাইডলাইন।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 'h_sup_1',
          order: 1,
          iconName: 'support_agent_rounded',
          headingEn: '1. Landlord Priority Helpline & Contacts',
          headingBn: '১. বাড়িওয়ালা প্রায়োরিটি হেল্পলাইন ও চ্যানেল',
          contentEn:
              'Property owners receive priority listing assistance 6 days a week (Sat-Thu, 9 AM - 9 PM BST).\n• Landlord Hotline: +880 1800-000000\n• Dedicated Email: owner-support@bashabondhu.com\n• Listing Audit Escalations: audit@bashabondhu.com',
          contentBn:
              'বাড়িওয়ালাদের জন্য আমাদের বিশেষায়িত হেল্পডেস্ক সপ্তাহে ৬ দিন (শনি-বৃহস্পতি, সকাল ৯:০০ - রাত ৯:০০) চালু থাকে।\n• বাড়িওয়ালা হেল্পলাইন: +৮৮০ ১৮০০-০০০০০০\n• ইমেইল: owner-support@bashabondhu.com\n• অডিট ও ভেরিফিকেশন: audit@bashabondhu.com',
        ),
        const PolicySectionModel(
          id: 'h_sup_2',
          order: 2,
          iconName: 'speed_rounded',
          headingEn: '2. Fast-Track Listing Approval SLA',
          headingBn: '২. দ্রুত বিজ্ঞাপন অনুমোদন ও ভেরিফিকেশন',
          contentEn:
              'New property listings are verified and approved within 1 to 4 business hours. Landlord subscription activations and featured boosts are processed instantly.',
          contentBn:
              'নতুন বাসা ভাড়ার বিজ্ঞাপন ১ থেকে ৪ কর্মঘণ্টার মধ্যে যাচাই করে লাইভ করা হয়। প্রিমিয়াম সাবস্ক্রিপশন ও ফিচার্ড বুস্টিং পেমেন্টের সাথে সাথে কার্যকর হয়।',
        ),
        const PolicySectionModel(
          id: 'h_sup_3',
          order: 3,
          iconName: 'handshake_outlined',
          headingEn: '3. Problematic Tenant Reporting & Assistance',
          headingBn: '৩. সমস্যাযুক্ত ভাড়াটিয়া রিপোর্ট ও সহায়তা',
          contentEn:
              'If a tenant submits fake demands or violates property decorum, landlords can report the profile for immediate review and platform restriction.',
          contentBn:
              'যদি কোনো ভাড়াটিয়া ভুয়া ভাড়ার তথ্য দিয়ে বাড়িওয়ালাকে প্রতারিত করার চেষ্টা করেন, বাড়িওয়ালারা সরাসরি রিপোর্ট করতে পারেন এবং প্রয়োজনীয় ব্যবস্থা নেওয়া হবে।',
        ),
      ],
    );
  }

  AppPolicyModel _getHouseOwnerDefaultTermsConditions(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'terms_conditions',
      targetAudience: 'house_owner',
      titleEn: 'House Owner Terms & Conditions',
      titleBn: 'বাড়িওয়ালা ব্যবহারের শর্তাবলী',
      subtitleEn: 'Listing standards, legal commitments, and rules for property owners on BashaBondhu.',
      subtitleBn: 'বাসাবন্ধুতে বাসা ভাড়ার বিজ্ঞাপন প্রকাশ, বাড়িওয়ালার দায়িত্ব ও আইনি নীতিমালা।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 'h_tc_1',
          order: 1,
          iconName: 'gavel_rounded',
          headingEn: '1. Genuine Listings & Real Photographs',
          headingBn: '১. সঠিক বিজ্ঞাপন ও প্রকৃত ছবি ব্যবহার',
          contentEn:
              'Property owners must provide authentic photos, accurate monthly rental amounts, advance deposit requirements, and real floor specifications. Uploading fabricated images or duplicate spam listings is forbidden.',
          contentBn:
              'বাড়িওয়ালাকে অবশ্যই বাসার প্রকৃত ছবি, সঠিক মাসিক ভাড়া, জামানতের পরিমাণ ও ফ্ল্যাটের স্পেসিফিকেশন উল্লেখ করতে হবে। ইন্টারনেট থেকে সংগৃহীত নকল ছবি বা একাধিক ডুপ্লিকেট বিজ্ঞাপন দেওয়া নিষিদ্ধ।',
        ),
        const PolicySectionModel(
          id: 'h_tc_2',
          order: 2,
          iconName: 'check_circle_outline_rounded',
          headingEn: '2. Immediate Status Updates upon Renting Out',
          headingBn: '২. বাসা ভাড়া হলে স্ট্যাটাস পরিবর্তন',
          contentEn:
              'When a property is successfully rented out, the owner is required to update the status to "Rented Out" (ভাড়া হয়ে গেছে) promptly to avoid unnecessary tenant inquiries.',
          contentBn:
              'বাসা ভাড়া হয়ে যাওয়ার সাথে সাথে বাড়িওয়ালাকে অ্যাপের মাধ্যমে বিজ্ঞাপনটি "Rented Out" (ভাড়া হয়ে গেছে) স্ট্যাটাসে পরিবর্তন করতে হবে যাতে ভাড়াটিয়ারা বিভ্রান্ত না হন।',
        ),
        const PolicySectionModel(
          id: 'h_tc_3',
          order: 3,
          iconName: 'shield_outlined',
          headingEn: '3. Compliance with Rental Laws of Bangladesh',
          headingBn: '৩. বাংলাদেশের বাড়িভাড়া নিয়ন্ত্রণ আইন মেনে চলা',
          contentEn:
              'Landlords agree to abide by the Premises Rent Control Act of Bangladesh. BashaBondhu serves as an advertising platform and does not partake in tenancy contracts or legal eviction processes.',
          contentBn:
              'বাড়িওয়ালারা বাংলাদেশের প্রচলিত বাড়িভাড়া নিয়ন্ত্রণ আইন ও নীতিমালা মেনে চলার অঙ্গীকার করেন। বাসাভাড়ার চুক্তিপত্র ও উচ্ছেদ সংক্রান্ত বিষয়ে বাসাবন্ধু কোনো সরাসরি পক্ষ নয়।',
        ),
      ],
    );
  }

  AppPolicyModel _getHouseOwnerDefaultRefundPolicy(String docId) {
    return AppPolicyModel(
      id: docId,
      type: 'refund_policy',
      targetAudience: 'house_owner',
      titleEn: 'House Owner Refund Policy',
      titleBn: 'বাড়িওয়ালা রিফান্ড পলিসি',
      subtitleEn: 'Subscription packages, featured ad boosts, and refund eligibility for landlords.',
      subtitleBn: 'বাড়িওয়ালাদের লিস্টিং প্যাকেজ, প্রিমিয়াম বুস্টিং ও রিফান্ড সংক্রান্ত নিয়মাবলী।',
      lastUpdated: DateTime(2026, 8, 31),
      sections: [
        const PolicySectionModel(
          id: 'h_rf_1',
          order: 1,
          iconName: 'replay_rounded',
          headingEn: '1. Landlord Subscription Packages Refund',
          headingBn: '১. বাড়িওয়ালা লিস্টিং প্যাকেজ রিফান্ড',
          contentEn:
              'If a landlord purchases a subscription pack but cannot publish listings due to platform system technical bugs, a 100% refund is issued upon request within 7 days.',
          contentBn:
              'যদি কোনো বাড়িওয়ালা সাবস্ক্রিপশন প্যাকেজ কিনে কারিগরি সমস্যার কারণে বিজ্ঞাপন পোস্ট করতে না পারেন, তবে ৭ দিনের মধ্যে আবেদন করলে সম্পূর্ণ টাকা রিফান্ড করা হবে।',
        ),
        const PolicySectionModel(
          id: 'h_rf_2',
          order: 2,
          iconName: 'campaign_outlined',
          headingEn: '2. Featured Ad Boost Non-Refundable Period',
          headingBn: '২. ফিচার্ড বিজ্ঞাপন বুস্টিং পলিসি',
          contentEn:
              'Once a "Featured" or "Urgent" promotion badge has been activated and displayed publicly to users for more than 24 hours, the promotional boost fee is non-refundable.',
          contentBn:
              'যদি কোনো বিজ্ঞাপন "ফিচার্ড" বা "জরুরি" বুস্ট হিসেবে সক্রিয় হয়ে ২৪ ঘণ্টার বেশি সময় প্রদর্শিত হয়, তবে উক্ত বুস্টিং চার্জ রিফান্ডযোগ্য হবে না।',
        ),
        const PolicySectionModel(
          id: 'h_rf_3',
          order: 3,
          iconName: 'credit_card_rounded',
          headingEn: '3. Settlement Method',
          headingBn: '৩. অর্থ পরিশোধের মাধ্যম',
          contentEn:
              'All approved landlord refunds are disbursed within 5-10 business days directly to the original MFS (bKash/Nagad) or Bank Account.',
          contentBn:
              'অনুমোদিত সকল রিফান্ড আগামী ৫ থেকে ১০ কর্মদিবসের মধ্যে সরাসরি মূল পেমেন্ট মাধ্যমে (বিকাশ/নগদ/ব্যাংক) ফেরত পাঠানো হবে।',
        ),
      ],
    );
  }

  // ==========================================
  // C. DEFAULT FAQS WITH TARGET AUDIENCE
  // ==========================================

  List<FaqModel> _getDefaultFaqs() {
    return [
      // 1. General (All)
      const FaqModel(
        id: 'faq_1',
        category: 'general',
        targetAudience: 'all',
        order: 1,
        questionEn: 'What is BashaBondhu and how does it work?',
        questionBn: 'বাসাবন্ধু কী এবং এটি কীভাবে কাজ করে?',
        answerEn:
            'BashaBondhu is Bangladesh\'s leading smart home rental management platform connecting tenants with verified house owners seamlessly without middlemen.',
        answerBn:
            'বাসাবন্ধু একটি আধুনিক ডিজিটাল বাড়িভাড়া প্ল্যাটফর্ম, যা কোনো ধরনের মধ্যস্থতাকারী (দালাল) ছাড়াই সরাসরি ভাড়াটিয়া ও বাড়িওয়ালার মধ্যে সংযোগ স্থাপন করে।',
      ),

      // 2. Finding Home (Tenant)
      const FaqModel(
        id: 'faq_2',
        category: 'finding_home',
        targetAudience: 'tenant',
        order: 2,
        questionEn: 'How can I search and filter rental homes?',
        questionBn: 'আমি কীভাবে বাসা খুঁজতে এবং ফিল্টার করতে পারি?',
        answerEn:
            'Go to the "Find a Home" tab and use location, rent price range, house type (Family, Bachelor, Sublet), and bed/bath filters or tap on the Interactive Map.',
        answerBn:
            '"বাসা খুঁজুন" ট্যাবে গিয়ে আপনার এলাকা, ভাড়ার বাজেট, ক্যাটাগরি (ফ্যামিলি, ব্যাচেলর, সাবলেট) সিলেক্ট করুন অথবা ইন্টারঅ্যাক্টিভ ম্যাপ থেকে সরাসরি বাসা বাছাই করুন।',
      ),

      // 3. Demand (Tenant)
      const FaqModel(
        id: 'faq_3',
        category: 'finding_home',
        targetAudience: 'tenant',
        order: 3,
        questionEn: 'What is "Tenant Demand" and how do I post one?',
        questionBn: '"ভাড়ার চাহিদা (Demand)" কী এবং কীভাবে পোস্ট করব?',
        answerEn:
            'If you cannot find a suitable house, tap "Demand" to post your desired area, budget, and family size. Landlords who have matching properties will contact you directly!',
        answerBn:
            'পছন্দসই বাসা না পেলে "Demand" অপশনে গিয়ে আপনার এলাকা ও বাজেট উল্লেখ করে চাহিদা পোস্ট করুন। বাড়িওয়ালারা আপনার পোস্ট দেখে সরাসরি আপনার সাথে যোগাযোগ করবেন।',
      ),

      // 4. Posting (House Owner)
      const FaqModel(
        id: 'faq_4',
        category: 'posting',
        targetAudience: 'house_owner',
        order: 4,
        questionEn: 'How do I publish a property listing as a House Owner?',
        questionBn: 'বাড়িওয়ালা হিসেবে আমি কীভাবে বাসা ভাড়ার বিজ্ঞাপন দেব?',
        answerEn:
            'Tap the "+" or "Post Ad" button on your House Owner dashboard. Enter property address, upload clear photos, set rent price and amenities, then tap Publish.',
        answerBn:
            'বাড়িওয়ালা ড্যাশবোর্ডে গিয়ে "+" বাটনে ট্যাপ করুন। এরপর বাসার ঠিকানা, পরিষ্কার ছবি, ভাড়ার পরিমাণ ও সুবিধাসমূহ সিলেক্ট করে সাবমিট করুন।',
      ),

      // 5. Viewing Demands (House Owner)
      const FaqModel(
        id: 'faq_5',
        category: 'posting',
        targetAudience: 'house_owner',
        order: 5,
        questionEn: 'How can I see what tenants are currently looking for?',
        questionBn: 'ভাড়াটিয়াদের চাহিদাগুলো বাড়িওয়ালা কীভাবে দেখতে পারবেন?',
        answerEn:
            'From your House Owner Account, open "All Tenant Demands". You can browse verified renter requests and directly call interested tenants.',
        answerBn:
            'বাড়িওয়ালা অ্যাকাউন্ট থেকে "All Tenant Demands" অপশনে গেলে বিভিন্ন এলাকার ভাড়াটিয়াদের সক্রিয় চাহিদা দেখতে পাবেন এবং সরাসরি কল করতে পারবেন।',
      ),

      // 6. Subscriptions (House Owner)
      const FaqModel(
        id: 'faq_6',
        category: 'management',
        targetAudience: 'house_owner',
        order: 6,
        questionEn: 'What are the benefits of House Owner Subscription Plans?',
        questionBn: 'বাড়িওয়ালা সাবস্ক্রিপশন প্ল্যানের সুবিধা কী কী?',
        answerEn:
            'Subscription plans allow house owners to post multiple listings, get "Featured" top placement badges, and receive priority tenant leads.',
        answerBn:
            'সাবস্ক্রিপশন প্ল্যানে একাধিক বিজ্ঞাপন প্রকাশ, বিজ্ঞাপনে "Featured" ব্যাজ এবং দ্রুত ভাড়াটিয়া পাওয়ার প্রায়োরিটি সুবিধা পাওয়া যায়।',
      ),

      // 7. Safety (All)
      const FaqModel(
        id: 'faq_7',
        category: 'safety',
        targetAudience: 'all',
        order: 7,
        questionEn: 'How does BashaBondhu verify property listings and users?',
        questionBn: 'বাসাবন্ধু কীভাবে বিজ্ঞাপন ও ব্যবহারকারীদের যাচাই করে?',
        answerEn:
            'We verify users via mobile OTP and conduct manual audits on high-value listings to prevent fake or misleading advertisements.',
        answerBn:
            'আমরা মোবাইল ওটিপি (OTP) ভেরিফিকেশন এবং বিজ্ঞাপনের ম্যানুয়াল অডিটের মাধ্যমে ভুয়া ও প্রতারণামূলক বিজ্ঞাপন প্রতিরোধ করি।',
      ),
    ];
  }
}
