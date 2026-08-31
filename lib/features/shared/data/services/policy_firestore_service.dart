import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/policy_model.dart';

class PolicyFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _policiesCollection => _firestore.collection('app_policies');
  CollectionReference get _faqsCollection => _firestore.collection('faqs');

  // ===========================================================================
  // 1. STREAM & GET POLICY WITH HIGH-QUALITY BILINGUAL DEFAULTS
  // ===========================================================================

  Stream<AppPolicyModel> streamPolicy(String policyType) {
    return _policiesCollection.doc(policyType).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final model = AppPolicyModel.fromMap(data, doc.id);
          if (model.sections.isNotEmpty) {
            return model;
          }
        } catch (e) {
          debugPrint('Error parsing policy $policyType: $e');
        }
      }
      return _getDefaultPolicy(policyType);
    });
  }

  Future<AppPolicyModel> getPolicy(String policyType) async {
    try {
      final doc = await _policiesCollection.doc(policyType).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final model = AppPolicyModel.fromMap(data, doc.id);
        if (model.sections.isNotEmpty) {
          return model;
        }
      }
    } catch (e) {
      debugPrint('Error getting policy $policyType: $e');
    }
    return _getDefaultPolicy(policyType);
  }

  Future<void> savePolicy(AppPolicyModel policy) async {
    await _policiesCollection.doc(policy.id).set(policy.toMap(), SetOptions(merge: true));
  }

  Future<void> savePolicySection(String policyType, PolicySectionModel section) async {
    final current = await getPolicy(policyType);
    final List<PolicySectionModel> updatedSections = List.from(current.sections);

    final existingIndex = updatedSections.indexWhere((s) => s.id == section.id);
    if (existingIndex >= 0) {
      updatedSections[existingIndex] = section;
    } else {
      updatedSections.add(section);
    }
    updatedSections.sort((a, b) => a.order.compareTo(b.order));

    final updatedPolicy = current.copyWith(
      lastUpdated: DateTime.now(),
      sections: updatedSections,
    );
    await savePolicy(updatedPolicy);
  }

  Future<void> deletePolicySection(String policyType, String sectionId) async {
    final current = await getPolicy(policyType);
    final List<PolicySectionModel> updatedSections = current.sections.where((s) => s.id != sectionId).toList();
    final updatedPolicy = current.copyWith(
      lastUpdated: DateTime.now(),
      sections: updatedSections,
    );
    await savePolicy(updatedPolicy);
  }

  Future<void> resetPolicyToDefault(String policyType) async {
    final defaultPolicy = _getDefaultPolicy(policyType);
    await savePolicy(defaultPolicy);
  }

  // ===========================================================================
  // 2. FAQS STREAM & CRUD WITH BILINGUAL DEFAULTS
  // ===========================================================================

  Stream<List<FaqModel>> streamFaqs({String? category}) {
    return _faqsCollection.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getDefaultFaqs(category: category);
      }
      final List<FaqModel> list = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final item = FaqModel.fromMap(data, doc.id);
          if (category == null || category == 'all' || item.category == category) {
            list.add(item);
          }
        } catch (e) {
          debugPrint('Error parsing FAQ ${doc.id}: $e');
        }
      }
      list.sort((a, b) => a.order.compareTo(b.order));
      return list.isNotEmpty ? list : _getDefaultFaqs(category: category);
    });
  }

  Future<void> saveFaq(FaqModel faq) async {
    if (faq.id.isEmpty) {
      final docRef = _faqsCollection.doc();
      final newFaq = faq.copyWith(id: docRef.id);
      await docRef.set(newFaq.toMap());
    } else {
      await _faqsCollection.doc(faq.id).set(faq.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteFaq(String faqId) async {
    await _faqsCollection.doc(faqId).delete();
  }

  Future<void> seedDefaultFaqs() async {
    final defaults = _getDefaultFaqs();
    for (final faq in defaults) {
      await _faqsCollection.doc(faq.id).set(faq.toMap(), SetOptions(merge: true));
    }
  }

  // ===========================================================================
  // 3. PRE-POPULATED HIGH-QUALITY BILINGUAL DATASETS FOR BASHABONDHU
  // ===========================================================================

  AppPolicyModel _getDefaultPolicy(String type) {
    switch (type) {
      case 'privacy_policy':
        return _defaultPrivacyPolicy();
      case 'support_policy':
        return _defaultSupportPolicy();
      case 'terms_conditions':
        return _defaultTermsConditions();
      case 'refund_policy':
        return _defaultRefundPolicy();
      default:
        return _defaultPrivacyPolicy();
    }
  }

  AppPolicyModel _defaultPrivacyPolicy() {
    return AppPolicyModel(
      id: 'privacy_policy',
      type: 'privacy_policy',
      titleEn: 'Privacy Policy',
      titleBn: 'গোপনীয়তা নীতি',
      subtitleEn: 'How BashaBondhu collects, protects, and respects your rental and personal data.',
      subtitleBn: 'বাসাবন্ধু কীভাবে আপনার ব্যক্তিগত তথ্য ও ভাড়া সংক্রান্ত উপাত্ত সংগ্রহ ও সুরক্ষিত রাখে।',
      lastUpdated: DateTime(2026, 8, 1),
      sections: [
        const PolicySectionModel(
          id: 'pp_1',
          headingEn: '1. Who We Are',
          headingBn: '১. আমাদের পরিচয় ও লক্ষ্য',
          contentEn:
              'Welcome to BashaBondhu, your premier and intelligent rental marketplace in Bangladesh. We respect your privacy and are committed to safeguarding your personal data, rental listings, and communications.',
          contentBn:
              'বাংলাদেশে বাসা খোঁজা ও ভাড়ার প্রক্রিয়াকে সহজ ও বিশ্বস্ত করতে বাসাবন্ধু (BashaBondhu) আপনার নির্ভরযোগ্য ডিজিটাল সঙ্গী। আমরা ব্যবহারকারীদের গোপনীয়তার সর্বোচ্চ সুরক্ষা নিশ্চিত করতে প্রতিশ্রুতিবদ্ধ।',
          order: 1,
          iconName: 'info_outline',
        ),
        const PolicySectionModel(
          id: 'pp_2',
          headingEn: '2. Personal Data We Collect & Why',
          headingBn: '২. আমরা কী কী তথ্য সংগ্রহ করি ও কেন',
          contentEn:
              '• Account Information: Full name, mobile number, email, profile photo, and NID verification for authenticated rental safety.\n• Rental Demands & Listings: Property location, floor, room specs, rent budget, and amenities to match renters with house owners.\n• Communications & Chat: Secure in-app messages and AI Assistant conversational logs for tailored recommendations.',
          contentBn:
              '• অ্যাকাউন্ট তথ্য: নাম, মোবাইল নম্বর, ইমেইল, ছবি এবং এনআইডি ভেরিফিকেশন—নিরাপদ ভাড়া লেনদেন নিশ্চিত করার জন্য।\n• ভাড়ার চাহিদা ও লিস্টিং: এলাকা, ফ্লোর, রুমের বিবরণ, ভাড়ার বাজেট এবং অন্যান্য সুবিধা—যাতে মালিক ও ভাড়াটিয়ার সঠিক মেলবন্ধন তৈরি হয়।\n• চ্যাট ও এআই সহকারী: অ্যাপের মধ্যে নিরাপদ বার্তা ও এআই সহকারীর সাথে চ্যাট হিস্ট্রি—দ্রুত সমাধান ও প্রাসঙ্গিক সুপারিশ প্রদানের লক্ষ্যে।',
          order: 2,
          iconName: 'person_outline',
        ),
        const PolicySectionModel(
          id: 'pp_3',
          headingEn: '3. Cookies & Local Preferences',
          headingBn: '৩. কুকিজ ও লোকাল স্টোরেজ',
          contentEn:
              'We use secure local storage and caching tokens to remember your login session, theme (Dark/Light), preferred language (Bangla/English), and saved search filters for a seamless experience.',
          contentBn:
              'আপনার লগইন সেশন, ডার্ক/লাইট থিম মোড, বাংলা/ইংরেজি ভাষা পছন্দ এবং সেভ করা সার্চ ফিল্টার মনে রাখার জন্য আমরা সুরক্ষিত লোকাল স্টোরেজ ব্যবহার করি।',
          order: 3,
          iconName: 'cookie_outlined',
        ),
        const PolicySectionModel(
          id: 'pp_4',
          headingEn: '4. Third-Party Services & Payment Gateways',
          headingBn: '৪. থার্ড পার্টি সার্ভিস ও পেমেন্ট সিকিউরিটি',
          contentEn:
              'For digital subscription activations, we integrate trusted payment partners (such as bKash, Nagad, SSLCOMMERZ). BashaBondhu never stores your confidential PINs or OTPs on our servers.',
          contentBn:
              'সাবস্ক্রিপশন ও প্রিমিয়াম সেবার পেমেন্টের জন্য আমরা সরকার অনুমোদিত গেটওয়ে (যেমন: বিকাশ, নগদ) ব্যবহার করি। বাসাবন্ধু কখনোই আপনার গোপন পিন বা ওটিপি সংরক্ষণ করে না।',
          order: 4,
          iconName: 'payment_outlined',
        ),
        const PolicySectionModel(
          id: 'pp_5',
          headingEn: '5. Data Retention & Account Deletion Rights',
          headingBn: '৫. তথ্য সংরক্ষণের মেয়াদ ও অ্যাকাউন্ট মোছার অধিকার',
          contentEn:
              'You hold complete control over your data. You may update your profile or permanently delete your account anytime via Account Settings. Upon account deletion, active listings and personal records are permanently erased.',
          contentBn:
              'আপনার তথ্যের উপর আপনার পূর্ণ নিয়ন্ত্রণ রয়েছে। আপনি যেকোনো সময় প্রোফাইল আপডেট বা অ্যাকাউন্ট সেটিংস থেকে সরাসরি অ্যাকাউন্ট ডিলিট করতে পারবেন। অ্যাকাউন্ট ডিলিট করলে সকল সক্রিয় বিজ্ঞাপন ও ব্যক্তিগত তথ্য মুছে ফেলা হবে।',
          order: 5,
          iconName: 'delete_outline',
        ),
        const PolicySectionModel(
          id: 'pp_6',
          headingEn: '6. Contact Privacy Team',
          headingBn: '৬. গোপনীয়তা বিষয়ক যোগাযোগ',
          contentEn:
              'If you have any questions regarding your data privacy, contact our Data Protection Officer at: privacy@bashabondhu.com or call our hotline: 09612-BASHABONDHU.',
          contentBn:
              'আপনার তথ্য ও গোপনীয়তা সম্পর্কিত যেকোনো প্রশ্ন বা মতামতের জন্য আমাদের সাথে যোগাযোগ করুন: privacy@bashabondhu.com অথবা হটলাইন: ০৯৬১২-বাসাবন্ধু।',
          order: 6,
          iconName: 'mail_outline',
        ),
      ],
    );
  }

  AppPolicyModel _defaultSupportPolicy() {
    return AppPolicyModel(
      id: 'support_policy',
      type: 'support_policy',
      titleEn: 'Support Policy',
      titleBn: 'সাপোর্ট পলিসি',
      subtitleEn: 'Our dedicated commitment to exceptional customer service and rapid issue resolution.',
      subtitleBn: 'গ্রাহক সেবা প্রদান, হেল্পলাইন ও দ্রুত সমস্যা সমাধানের জন্য বাসাবন্ধুর নীতিমালা।',
      lastUpdated: DateTime(2026, 8, 1),
      sections: [
        const PolicySectionModel(
          id: 'sp_1',
          headingEn: '1. Our Support Commitment',
          headingBn: '১. আমাদের সাপোর্ট প্রতিশ্রুতি',
          contentEn:
              'At BashaBondhu, our customer happiness team is dedicated to providing transparent, empathetic, and speedy technical assistance to both tenants and house owners.',
          contentBn:
              'বাসাবন্ধুতে আমরা প্রতিটি ভাড়াটিয়া ও বাড়িওয়ালার প্রশ্নের স্বচ্ছ, দ্রুত এবং আন্তরিক সমাধান দিতে সর্বদা সচেষ্ট। যেকোনো প্রয়োজনে আমাদের ডেডিকেটেড সাপোর্ট টিম পাশে রয়েছে।',
          order: 1,
          iconName: 'support_agent_outlined',
        ),
        const PolicySectionModel(
          id: 'sp_2',
          headingEn: '2. Support Channels & Contact Info',
          headingBn: '২. সাপোর্ট চ্যানেল ও যোগাযোগের মাধ্যম',
          contentEn:
              '• Official Email: support@bashabondhu.com\n• In-App AI Assistant: 24/7 instant guidance\n• WhatsApp Support Helpline: +880 1700-000000\n• Dedicated Ticket Desk: Accessible inside the Account Hub.',
          contentBn:
              '• অফিসিয়াল ইমেইল: support@bashabondhu.com\n• অ্যাপের এআই সহকারী: ২৪/৭ তাৎক্ষণিক গাইডলাইন\n• হোয়াটসঅ্যাপ সাপোর্ট হেল্পলাইন: +৮৮০ ১৭০০-০০০০০০\n• অ্যাকাউন্ট সাপোর্ট ডেস্ক: অ্যাকাউন্ট পেজ থেকে সরাসরি সাপোর্ট টিকিট ওপেন করুন।',
          order: 2,
          iconName: 'contact_phone_outlined',
        ),
        const PolicySectionModel(
          id: 'sp_3',
          headingEn: '3. Operating Hours & Response SLA',
          headingBn: '৩. সাপোর্ট সময়সূচী ও রেসপন্স টাইম',
          contentEn:
              '• Saturday to Thursday: 9:00 AM – 9:00 PM (BST)\n• Friday: 2:00 PM – 8:00 PM (BST)\n• Email/Ticket Response Time: Within 2 to 6 business hours\n• Emergency Hotline: Always active for verified subscription accounts.',
          contentBn:
              '• শনিবার থেকে বৃহস্পতিবার: সকাল ৯:০০ টা – রাত ৯:০০ টা\n• শুক্রবার: দুপুর ২:০০ টা – রাত ৮:০০ টা\n• ইমেইল ও টিকিট রেসপন্স টাইম: ২ থেকে ৬ কর্মঘণ্টার মধ্যে\n• জরুরি সাপোর্ট: সাবস্ক্রিপশন ব্যবহারকারীদের জন্য অগ্রাধিকার ভিত্তিতে দ্রুত সমাধান।',
          order: 3,
          iconName: 'schedule_outlined',
        ),
        const PolicySectionModel(
          id: 'sp_4',
          headingEn: '4. Support Scope & Limitations',
          headingBn: '৪. সাপোর্টের পরিধি ও সীমাবদ্ধতা',
          contentEn:
              'We provide full support for app features, login, listing approvals, subscription verification, and tenant match issues. We do not provide physical property inspections or handle physical rent cash collections.',
          contentBn:
              'আমরা অ্যাপ ব্যবহার, ওটিপি লগইন, বিজ্ঞাপন অনুমোদন, সাবস্ক্রিপশন এক্টিভেশন এবং ভাড়ার তথ্য খোঁজার যাবতীয় সহায়তা প্রদান করি। তবে সরাসরি ভাড়ার নগদ টাকা লেনদেন বা বাড়ি পরিদর্শনে আমাদের সম্পৃক্ততা নেই।',
          order: 4,
          iconName: 'rule_outlined',
        ),
      ],
    );
  }

  AppPolicyModel _defaultTermsConditions() {
    return AppPolicyModel(
      id: 'terms_conditions',
      type: 'terms_conditions',
      titleEn: 'Terms and Conditions',
      titleBn: 'ব্যবহারের শর্তাবলী',
      subtitleEn: 'Rules, user responsibilities, and legal agreements governing the use of BashaBondhu.',
      subtitleBn: 'বাসাবন্ধু প্ল্যাটফর্ম ব্যবহারের সাধারণ নিয়ম, আইনি বাধ্যবাধকতা ও আচরণবিধি।',
      lastUpdated: DateTime(2026, 8, 1),
      sections: [
        const PolicySectionModel(
          id: 'tc_1',
          headingEn: '1. User Responsibilities & Authenticity',
          headingBn: '১. ব্যবহারকারীর দায়িত্ব ও তথ্যের নির্ভুলতা',
          contentEn:
              'Users must provide truthful, accurate personal details and authentic property specifications. Misrepresenting property conditions, rent amounts, or contact credentials is strictly prohibited and subject to account suspension.',
          contentBn:
              'ব্যবহারকারীকে অবশ্যই নির্ভুল ব্যক্তিগত তথ্য ও সত্য প্রপার্টি বিবরণ প্রদান করতে হবে। ভুয়া বিজ্ঞাপন, ভুল ভাড়ার পরিমাণ বা বিভ্রান্তিকর যোগাযোগ তথ্য দিলে অ্যাকাউন্ট অবিলম্বে স্থগিত করা হবে।',
          order: 1,
          iconName: 'gavel_outlined',
        ),
        const PolicySectionModel(
          id: 'tc_2',
          headingEn: '2. Property Listings & Advertisements',
          headingBn: '২. বাসাভাড়া বিজ্ঞাপন ও লিস্টিং নীতিমালা',
          contentEn:
              'By publishing a To-Let listing, house owners confirm legal ownership or authorized agency rights. Listings must adhere to Bangladesh real estate fair housing standards and must not discriminate unlawfully.',
          contentBn:
              'বাসাভাড়ার বিজ্ঞাপন প্রকাশের মাধ্যমে বাড়িওয়ালা বা প্রতিনিধি নিশ্চিত করেন যে উক্ত প্রপার্টি লিস্টিং করার বৈধ অধিকার তার রয়েছে। বিজ্ঞাপনে অশালীন ছবি বা বিভ্রান্তিকর কনটেন্ট দেওয়া সম্পূর্ণ নিষিদ্ধ।',
          order: 2,
          iconName: 'home_work_outlined',
        ),
        const PolicySectionModel(
          id: 'tc_3',
          headingEn: '3. Fees, Payments & Subscriptions',
          headingBn: '৩. ফি, পেমেন্ট ও সাবস্ক্রিপশন প্ল্যান',
          contentEn:
              'Basic browsing and demand posting are free. Advanced contact unlocks and boosted listings operate on upfront subscription packages. All digital transactions are governed by our Refund Policy.',
          contentBn:
              'সাধারণ বাসা খোঁজা ও ডিমান্ড পোস্ট সম্পূর্ণ ফ্রি। প্রিমিয়াম সাবস্ক্রিপশন প্যাকেজে আনলিমিটেড কন্টাক্ট নম্বর আনলক ও বুস্টিং সুবিধা রয়েছে। সকল পেমেন্ট আমাদের রিফান্ড পলিসির আওতাভুক্ত।',
          order: 3,
          iconName: 'account_balance_wallet_outlined',
        ),
        const PolicySectionModel(
          id: 'tc_4',
          headingEn: '4. Governing Law & Jurisdiction',
          headingBn: '৪. প্রযোজ্য আইন ও বিচারিক অধিক্ষেত্র',
          contentEn:
              'These terms are formulated in accordance with the laws of the People’s Republic of Bangladesh. Any dispute arising from platform usage is subject to the exclusive jurisdiction of the courts of Dhaka, Bangladesh.',
          contentBn:
              'এই শর্তাবলী গণপ্রজাতন্ত্রী বাংলাদেশের প্রযোজ্য আইন অনুযায়ী পরিচালিত। প্ল্যাটফর্ম ব্যবহারের ক্ষেত্রে যেকোনো বিরোধ নিষ্পত্তির জন্য ঢাকা, বাংলাদেশ আদালতের অধিক্ষেত্র প্রযোজ্য হবে।',
          order: 4,
          iconName: 'account_balance_outlined',
        ),
      ],
    );
  }

  AppPolicyModel _defaultRefundPolicy() {
    return AppPolicyModel(
      id: 'refund_policy',
      type: 'refund_policy',
      titleEn: 'Refund Policy',
      titleBn: 'রিফান্ড পলিসি',
      subtitleEn: 'Clear, transparent rules regarding payment refunds, service cancellations, and dispute settlements.',
      subtitleBn: 'সাবস্ক্রিপশন ফি, লেনদেন বাতিল ও রিফান্ড সংক্রান্ত স্পষ্ট ও স্বচ্ছ নীতিমালা।',
      lastUpdated: DateTime(2026, 8, 1),
      sections: [
        const PolicySectionModel(
          id: 'rf_1',
          headingEn: '1. Subscription Service Cancellation',
          headingBn: '১. সাবস্ক্রিপশন বাতিল ও রিফান্ড যোগ্যতা',
          contentEn:
              'If you purchase a digital subscription and experience a verified technical failure that prevents contact unlocking or post boosting within 24 hours of purchase, you are eligible for a full refund or service credit.',
          contentBn:
              'সাবস্ক্রিপশন ক্রয়ের পর যদি কোনো কারিগরি ত্রুটির কারণে ২৪ ঘণ্টার মধ্যে প্যাকেজের সুবিধা (যেমন: নম্বর আনলক বা বুস্টিং) পাওয়া না যায়, তবে সম্পূর্ণ অর্থ রিফান্ড বা সমমূল্যের সার্ভিস ক্রেডিট প্রদান করা হবে।',
          order: 1,
          iconName: 'replay_outlined',
        ),
        const PolicySectionModel(
          id: 'rf_2',
          headingEn: '2. Refund Processing Timeline',
          headingBn: '২. রিফান্ড প্রসেসিং সময়সীমা',
          contentEn:
              'Approved refunds are processed back to your original payment method (bKash/Nagad wallet or bank card) within 5 to 10 business days after verification.',
          contentBn:
              'রিফান্ড অনুমোদনের পর ৫ থেকে ১০ কর্মদিবসের মধ্যে আপনার মূল পেমেন্ট মাধ্যমে (বিকাশ/নগদ অ্যাকাউন্ট বা ব্যাংক কার্ড) টাকা ফেরত পাঠানো হবে।',
          order: 2,
          iconName: 'timer_outlined',
        ),
        const PolicySectionModel(
          id: 'rf_3',
          headingEn: '3. Non-Refundable Situations',
          headingBn: '৩. যেসব ক্ষেত্রে রিফান্ড প্রযোজ্য নয়',
          contentEn:
              '• Subscriptions where package quota or contact unlocks have already been utilized.\n• Accounts banned for policy violations or fraudulent listings.\n• Direct private cash transactions conducted between landlord and tenant outside BashaBondhu.',
          contentBn:
              '• প্যাকেজের সুবিধা বা কন্টাক্ট নম্বর ইতিমধ্যে ব্যবহার করে ফেললে।\n• প্রতারণামূলক তথ্য বা নীতিমালা লঙ্ঘনের কারণে অ্যাকাউন্ট বন্ধ হলে।\n• বাসাবন্ধু প্ল্যাটফর্মের বাইরে সরাসরি বাড়িওয়ালা ও ভাড়াটিয়ার মধ্যে হওয়া ব্যক্তিগত নগদ লেনদেনের ক্ষেত্রে।',
          order: 3,
          iconName: 'highlight_off_outlined',
        ),
        const PolicySectionModel(
          id: 'rf_4',
          headingEn: '4. How to Request a Refund',
          headingBn: '৪. রিফান্ডের আবেদন করার নিয়ম',
          contentEn:
              'To file a refund request, email billing@bashabondhu.com with your registered phone number, transaction TrxID, and a brief description of the issue. Our finance team will review and update you promptly.',
          contentBn:
              'রিফান্ডের জন্য আপনার নিবন্ধিত ফোন নম্বর, পেমেন্ট ট্রানজেকশন আইডি (TrxID) এবং কারণ উল্লেখ করে billing@bashabondhu.com এ ইমেইল করুন অথবা অ্যাপের সাপোর্ট ডেস্কে যোগাযোগ করুন।',
          order: 4,
          iconName: 'mark_email_read_outlined',
        ),
      ],
    );
  }

  List<FaqModel> _getDefaultFaqs({String? category}) {
    final all = [
      const FaqModel(
        id: 'faq_1',
        category: 'general',
        questionEn: 'What is BashaBondhu?',
        questionBn: 'বাসাবন্ধু (BashaBondhu) কী?',
        answerEn:
            'BashaBondhu is an AI-powered rental management and property discovery platform in Bangladesh. It empowers tenants to find family flats, bachelor rooms, sublets, and hostels, while enabling house owners to publish ads and manage rental records effortlessly.',
        answerBn:
            'বাসাবন্ধু হলো বাংলাদেশের একটি আধুনিক ও এআই-পাওয়ার্ড বাসাভাড়া ও প্রপার্টি প্ল্যাটফর্ম। এর মাধ্যমে ভাড়াটিয়ারা সহজে পরিবারিক ফ্ল্যাট, ব্যাচেলর রুম, সাবলেট ও হোস্টেল খুঁজতে পারেন এবং বাড়িওয়ালারা সরাসরি বিজ্ঞাপন দিয়ে দ্রুত ভাড়াটিয়া খুঁজে পান।',
        order: 1,
      ),
      const FaqModel(
        id: 'faq_2',
        category: 'general',
        questionEn: 'Who can use BashaBondhu?',
        questionBn: 'বাসাবন্ধু কাদের জন্য তৈরি?',
        answerEn:
            'Anyone looking for rental accommodations (families, students, job holders), property owners listing flats, and building managers managing multi-unit tenant records across Bangladesh.',
        answerBn:
            'যারা বাংলাদেশে বাসা, ফ্ল্যাট, সিট বা সাবলেট ভাড়া খুঁজছেন; যারা নিজের বাড়ি বা রুম ভাড়া দিতে চান; এবং যাদের একাধিক ভাড়াটিয়া পরিচালনা করতে আধুনিক টেন্যান্ট ম্যানেজমেন্ট দরকার—সবার জন্য বাসাবন্ধু।',
        order: 2,
      ),
      const FaqModel(
        id: 'faq_3',
        category: 'finding_home',
        questionEn: 'How do I search for house rent on BashaBondhu?',
        questionBn: 'বাসাবন্ধুতে পছন্দের বাসা কীভাবে খুঁজব?',
        answerEn:
            'Open the "Find a Home" tab, select your preferred division, district, thana/area, budget range, and room count. You can also use the interactive BashaBondhu AI Assistant for step-by-step conversational search.',
        answerBn:
            'অ্যাপের "Find Home" অপশনে গিয়ে আপনার পছন্দের বিভাগ, জেলা, থানা/এলাকা, বাজেট এবং রুম সিলেক্ট করে ফিল্টার করুন। এছাড়া আমাদের এআই সহকারীর সাথে চ্যাট করেও মুহূর্তেই মনের মতো বাসা খুঁজে পাবেন।',
        order: 3,
      ),
      const FaqModel(
        id: 'faq_4',
        category: 'finding_home',
        questionEn: 'Is there any middleman / media fee to contact house owners?',
        questionBn: 'বাড়িওয়ালার সাথে যোগাযোগে কোনো মিডিয়া বা দালাল ফি দিতে হয় কি?',
        answerEn:
            'No! BashaBondhu connects you directly with verified house owners without any middleman or commission fees.',
        answerBn:
            'না! বাসাবন্ধুতে কোনো প্রকার দালাল বা মধ্যস্বত্বভোগী ছাড়া সরাসরি আসল বাড়িওয়ালার সাথে যোগাযোগ করা যায়।',
        order: 4,
      ),
      const FaqModel(
        id: 'faq_5',
        category: 'posting',
        questionEn: 'How do I post a rental advertisement as a House Owner?',
        questionBn: 'বাড়িওয়ালা হিসেবে কীভাবে বাসাভাড়ার বিজ্ঞাপন দেব?',
        answerEn:
            'Log into your House Owner account, tap "Post Now" (or ask the AI Assistant), fill in the property details, upload photos, and publish your ad instantly for free.',
        answerBn:
            'বাড়িওয়ালা অ্যাকাউন্টে লগইন করে "Post Now" বাটনে চাপ দিন (অথবা এআই সহকারীর সাহায্য নিন), বাসার বিবরণ ও ছবি যুক্ত করে সম্পূর্ণ ফ্রিতে আপনার বিজ্ঞাপন লাইভ করুন।',
        order: 5,
      ),
      const FaqModel(
        id: 'faq_6',
        category: 'posting',
        questionEn: 'Can I edit or deactivate my property post?',
        questionBn: 'পোস্ট করা বিজ্ঞাপন কি এডিট বা ডিঅ্যাক্টিভেট করা যাবে?',
        answerEn:
            'Yes! Go to "My Post" in your account to update rent amounts, photos, or toggle availability off when your flat is rented out.',
        answerBn:
            'হ্যাঁ! আপনার অ্যাকাউন্টের "My Post" অপশন থেকে যেকোনো সময় ভাড়ার তথ্য ও ছবি এডিট করতে পারবেন অথবা বাসা ভাড়া হয়ে গেলে বিজ্ঞাপন বন্ধ করে রাখতে পারবেন।',
        order: 6,
      ),
      const FaqModel(
        id: 'faq_7',
        category: 'management',
        questionEn: 'What is Tenant Demand posting?',
        questionBn: 'ভাড়াটিয়াদের ডিমান্ড পোস্ট (Tenant Demand) কীভাবে কাজ করে?',
        answerEn:
            'Tenants can post their exact rental requirements (area, budget, bedrooms, move-in month). Landlords can view matching demands and contact tenants proactively.',
        answerBn:
            'ভাড়াটিয়ারা তাদের নির্দিষ্ট এলাকা, বাজেট, বেডরুম ও পছন্দের মাসের চাহিদা পোস্ট করতে পারেন। বাড়িওয়ালারা এই চাহিদা দেখে সরাসরি উপযুক্ত ভাড়াটিয়াদের সাথে যোগাযোগ করতে পারেন।',
        order: 7,
      ),
      const FaqModel(
        id: 'faq_8',
        category: 'safety',
        questionEn: 'How does BashaBondhu ensure safety against fraudulent listings?',
        questionBn: 'ভুয়া বা প্রতারণামূলক বিজ্ঞাপন ঠেকাতে বাসাবন্ধুর কী নিরাপত্তা ব্যবস্থা রয়েছে?',
        answerEn:
            'We enforce NID verification badges, phone OTP validations, location audits, and community reporting. We strongly advise visiting properties in person before making advance payments.',
        answerBn:
            'আমরা এনআইডি ভেরিফিকেশন, ওটিপি মোবাইল ভ্যালিডেশন এবং সার্বক্ষণিক মনিটরিং নিশ্চিত করি। যেকোনো অগ্রিম লেনদেনের পূর্বে সশরীরে বাসা পরিদর্শন করার জন্য আমরা সবসময় পরামর্শ দিয়ে থাকি।',
        order: 8,
      ),
    ];

    if (category == null || category == 'all') {
      return all;
    }
    return all.where((f) => f.category == category).toList();
  }
}
