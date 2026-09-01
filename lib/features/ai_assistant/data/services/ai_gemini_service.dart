import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIResponseData {
  final String replyText;
  final String? intent; // 'search_properties', 'find_home_wizard', 'post_demand_wizard', 'view_demands_wizard', 'subscription_history', 'subscription_packages', 'my_profile', 'admin_stats', 'pricing_advice', 'generate_ad', 'general'
  final Map<String, dynamic>? searchFilters;
  final Map<String, dynamic>? draftData;
  final List<String>? interactiveChips;
  final List<String>? quickFollowUps;

  AIResponseData({
    required this.replyText,
    this.intent,
    this.searchFilters,
    this.draftData,
    this.interactiveChips,
    this.quickFollowUps,
  });
}

class AIGeminiService {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyC4-KmB5eD8LU3e37Cyns02p7G_fblUm3E',
  );

  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Generate contextual AI response for Tenant, House Owner, or Admin
  Future<AIResponseData> getAssistantResponse({
    required String userPrompt,
    required String userRole, // 'Tenant', 'House Owner', 'Admin'
    required String userName,
    required String languageCode,
    String? liveDatabaseContext,
    Map<String, dynamic>? currentDraftState,
    List<Map<String, String>> previousHistory = const [],
  }) async {
    final isBn = languageCode == 'bn';
    final isOwner = userRole.toLowerCase().contains('owner');
    final isAdmin = userRole.toLowerCase().contains('admin');

    final systemInstruction = '''
You are "বাসাবন্ধু এআই (BashaBondhu AI)", the official, domain-expert, and highly intelligent AI Assistant for "বাসাবন্ধু (BashaBondhu)", Bangladesh's leading digital home rental and property management platform.

YOUR IDENTITY & ROLE:
- You work EXCLUSIVELY as the intelligent agent for the BashaBondhu App.
- Current User: $userName
- Role: $userRole (${isAdmin ? "Platform Admin (অ্যাডমিন)" : isOwner ? "House Owner (বাড়িওয়ালা)" : "Tenant (ভাড়াটিয়া)"})
- Preferred Language: ${isBn ? "Bengali (বাংলা)" : "English"}

CORE DOMAIN KNOWLEDGE OF BASHABONDHU APP:
1. Platform Services:
   - For Tenants: Finding homes, filtering by division, district, area, and sub-area, price range, bedrooms, bachelor/family, lifts, parking, wishlist, contacting house owners, and posting 17-step conversational Tenant Demands.
   - For House Owners: Posting free To-Let ads, toggling "Rented Out" (যা পোস্টকে ভাড়াটিয়াদের হোম স্ক্রিন থেকে হাইড/আনহাইড করে), browsing active Tenant Demands, exploring neighborhood market rent price benchmarks, and managing subscription packages.
   - For Admin: Real-time analytics, user overview, subscription revenue, platform monitoring, and secure Firebase authentication.
2. App Features & Navigation:
   - Bilingual support: Instant Bengali / English toggle in all AppBars.
   - Password Recovery: Free Firebase Authentication password reset via Gmail.
   - Tenant Demand Toggle: "Mark as Fulfilled / বাসা পেয়ে গেছি" toggle button hides/shows the demand from House Owners' demand screen.
   - House Owner Post Toggle: "Rented Out / ভাড়া হয়ে গেছে" toggle button hides/shows the post from Tenant & Guest home screens.

CRITICAL SECURITY & PRIVACY POLICY:
- 🚫 NEVER disclose any user's private password, email address, raw phone number, or payment transaction IDs under any circumstances.
- Only provide public rental specifications, area pricing insights, general platform advice, and public demand criteria.

LANGUAGE & CONVERSATIONAL STYLE:
- Fluent in Bengali (বাংলা), English, and Banglish (e.g. "basha khujte chai", "mirpur 10 e 2 bed flat er bhara koto", "house owner subscription keno dorkar").
- If the user writes in Bengali or Banglish, respond in warm, natural, polished Bengali.
- If the user writes in English, respond in professional, friendly English.
- Always use clear Markdown formatting: bold text, bullet points, and helpful emojis (🏠, 📍, 💰, 🛏️, ⚡, 💳, 📄, 👥).

${liveDatabaseContext != null && liveDatabaseContext.isNotEmpty ? "LIVE PLATFORM PUBLIC INSIGHTS (ANONYMIZED):\n$liveDatabaseContext\n" : ""}

OUTPUT FORMAT SCHEMA:
Respond with a JSON object:
```json
{
  "reply": "Your intelligent, polite, Markdown-formatted reply with emojis and bullet points",
  "intent": "search_properties" | "find_home_wizard" | "post_demand_wizard" | "view_demands_wizard" | "subscription_history" | "subscription_packages" | "my_profile" | "admin_stats" | "pricing_advice" | "general",
  "search_criteria": {
    "area": "area name or null",
    "district": "district name or null",
    "division": "division name or null",
    "min_price": number or null,
    "max_price": number or null,
    "rooms": "BedRoom - 2" or null,
    "house_type": "flat" | "sublet" | "bachelor" | "room" | "unit" or null,
    "tenant_type": "family" | "bachelor" or null
  },
  "interactive_chips": ["Chip 1", "Chip 2", "Chip 3"],
  "quick_follow_ups": ["Prompt 1", "Prompt 2", "Prompt 3"]
}
```
''';

    try {
      final url = Uri.parse('$_geminiEndpoint?key=$_geminiApiKey');
      final contents = [
        {
          "role": "user",
          "parts": [
            {"text": "System Instruction:\n$systemInstruction\n\nUser Question: $userPrompt"}
          ]
        }
      ];

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": contents,
              "generationConfig": {
                "temperature": 0.35,
                "topK": 32,
                "topP": 0.9,
                "maxOutputTokens": 1024,
                "responseMimeType": "application/json",
              }
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0];
        final textPart = candidate?['content']?['parts']?[0]?['text'];

        if (textPart != null && textPart.isNotEmpty) {
          final parsed = jsonDecode(textPart);
          return AIResponseData(
            replyText: parsed['reply'] ?? textPart,
            intent: parsed['intent'],
            searchFilters: parsed['search_criteria'],
            interactiveChips: (parsed['interactive_chips'] as List?)
                ?.map((e) => e.toString())
                .toList(),
            quickFollowUps: (parsed['quick_follow_ups'] as List?)
                ?.map((e) => e.toString())
                .toList(),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Gemini API error in AIGeminiService: $e');
    }

    // High-Intelligence Built-in Cognitive Engine for BashaBondhu App
    return _generateIntelligentBashaBondhuResponse(userPrompt, userRole, isBn);
  }

  /// High-Intelligence Built-in Cognitive Engine for BashaBondhu App
  AIResponseData _generateIntelligentBashaBondhuResponse(String prompt, String userRole, bool isBn) {
    final lower = prompt.toLowerCase();
    final isOwner = userRole.toLowerCase().contains('owner');
    final isAdmin = userRole.toLowerCase().contains('admin');

    // ==========================================
    // 1. APP OVERVIEW (অ্যাপ ওভারভিউ / পরিচিতি)
    // ==========================================
    if (lower.contains('overview') ||
        lower.contains('about app') ||
        lower.contains('about bashabondhu') ||
        lower.contains('how this app works') ||
        lower.contains('অ্যাপ সম্পর্কে') ||
        lower.contains('অ্যাপের পরিচিতি') ||
        lower.contains('অ্যাপ পরিচিতি') ||
        lower.contains('ওভারভিউ') ||
        lower.contains('বাসাবন্ধু কী') ||
        lower.contains('বাসাবন্ধু কি') ||
        lower.contains('what is bashabondhu')) {
      final overviewText = isBn
          ? '''🌟 **বাসাবন্ধু (BashaBondhu) প্ল্যাটফর্ম পরিচিতি:**

"বাসাবন্ধু" হলো বাংলাদেশের অন্যতম আধুনিক ও বিশ্বস্ত ডিজিটাল হোম রেন্টাল ও প্রপার্টি ম্যানেজমেন্ট প্ল্যাটফর্ম, যা বাড়িওয়ালা ও ভাড়াটিয়াদের মাঝে কোনো প্রকার মধ্যস্বত্বভোগী বা দালাল ছাড়া সরাসরি সংযোগ স্থাপন করে।

✨ **প্ল্যাটফর্মের মূল সুবিধাসমূহ:**
1. 🏠 **ভাড়াটিয়াদের জন্য:**
   • বিভাগ, জেলা, এলাকা এবং সাব-এরিয়া অনুযায়ী নির্ভুল ফিল্টারিং।
   • গুগল ম্যাপস ইন্টিগ্রেশন এবং পছন্দের বাসার উইশলিস্ট সংরক্ষণ।
   • মুখে বলে বা চ্যাটে কথা বলে **১৭-ধাপের ভয়েস/চ্যাট ডিমান্ড পোস্ট** সুবিধা।
   • বাসা পেয়ে গেলে **'বাসা পেয়ে গেছি'** বোতাম দিয়ে পোস্ট হাইড করার সুবিধা।

2. 🏢 **বাড়িওয়ালাদের জন্য:**
   • সম্পূর্ণ বিনামূল্যে টু-লেট বিজ্ঞাপন পোস্ট করার সুবিধা।
   • **'ভাড়া হয়ে গেছে (Rented Out)'** বোতাম দিয়ে তাৎক্ষণিকভাবে পোস্ট হাইড/আনহাইড করার ব্যবস্থা।
   • এলাকার সক্রিয় ভাড়াটিয়াদের লাইভ চাহিদা (Tenant Demands) ব্রাউজ করার সুযোগ।
   • এলাকাভিত্তিক বাস্তব বাড়ি ভাড়ার রেঞ্জ অ্যানালাইসিস।

3. 🌐 **বিশেষ ফিচারসমূহ:**
   • **সম্পূর্ণ দ্বিভাষিক ইন্টারফেস:** প্রতিটি স্ক্রিনের অ্যাপবারে এক ক্লিকে বাংলা ও ইংরেজি পরিবর্তন।
   • **ফ্রি জিমেইল পাসওয়ার্ড রিকভারি:** সিকিউর ফায়ারবেস অথেন্টিকেশন দিয়ে পাসওয়ার্ড পুনরুদ্ধার।
   • **এআই সহকারী (BashaBondhu AI):** যে কোনো রেন্টাল প্রশ্নের দ্রুত ও নির্ভুল সমাধান।'''
          : '''🌟 **BashaBondhu App Overview:**

"BashaBondhu" is Bangladesh's premier digital home rental and property management ecosystem connecting house owners and tenants directly without any middlemen or brokers.

✨ **Core Platform Features:**
1. 🏠 **For Tenants:**
   • Comprehensive search with Division, District, Area, and Sub-Area filters.
   • Google Maps view, bookmarking homes to Wishlist, and direct landlord contact.
   • Conversational **17-step voice/chat Tenant Demand wizard**.
   • **"Mark as Fulfilled"** toggle to hide demand posts once a home is secured.

2. 🏢 **For House Owners:**
   • Post To-Let advertisements 100% free with rich photos and amenity details.
   • **"Rented Out"** toggle button to hide/show listings from tenant home screens.
   • Browse live **Tenant Demands** in real-time.
   • Check dynamic area rental price ranges based on market database records.

3. 🌐 **Special Highlights:**
   • **Instant Bilingual Switch:** Switch between Bengali and English on any screen.
   • **Free Gmail Password Recovery:** Fast and secure password reset via Firebase Auth.
   • **Dedicated AI Assistant:** 24/7 intelligent assistance for all rental needs.''';

      return AIResponseData(
        replyText: overviewText,
        intent: 'general',
        interactiveChips: isBn
            ? (isOwner
                ? ['👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি']
                : ['🔍 বাসা খুঁজুন', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি'])
            : (isOwner
                ? ['👥 Find Tenant Demand', '💡 Suggest Price Range', '💳 Subscription Packages', '📄 Subscription History']
                : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History']),
        quickFollowUps: isBn ? ['সাধারণ জিজ্ঞাসা (FAQ)', 'গোপনীয়তা নীতি', 'ব্যবহারের শর্তাবলী'] : ['Frequently Asked Questions (FAQ)', 'Privacy Policy', 'Terms & Conditions'],
      );
    }

    // ==========================================
    // 2. FAQ (সাধারণ জিজ্ঞাসা ও প্রশ্নোত্তর)
    // ==========================================
    if (lower.contains('faq') ||
        lower.contains('faqs') ||
        lower.contains('frequently asked questions') ||
        lower.contains('সাধারণ জিজ্ঞাসা') ||
        lower.contains('প্রশ্নোত্তর') ||
        lower.contains('প্রশ্নাবলী') ||
        lower.contains('এফএকিউ')) {
      final faqText = isBn
          ? '''❓ **বাসাবন্ধু সাধারণ জিজ্ঞাসা ও সমাধান (FAQs):**

**প্রশ্ন ১: আমি কীভাবে বিনামূল্যে বাসা ভাড়ার বিজ্ঞাপন (To-Let) দেব?**
👉 **উত্তর:** বাড়িওয়ালা অ্যাকাউন্টে লগইন করে নিচে **"Post Free"** বা **"+"** বাটনে চাপ দিন। আপনার বাসার সঠিক এলাকা (বিভাগ, জেলা, এলাকা, সাব-এরিয়া), রুমের বিবরণ (বেডরুম, বাথরুম, বারান্দা, ফ্লোর), মাসিক ভাড়া ও পরিষ্কার ছবি যুক্ত করে সাবমিট করলেই বিজ্ঞাপন তাৎক্ষণিক লাইভ হয়ে যাবে।

**প্রশ্ন ২: 'ভাড়া হয়ে গেছে (Rented Out)' বোতামের কাজ কী এবং কীভাবে ব্যবহার করব?**
👉 **উত্তর:** আপনার বাসা ভাড়া হয়ে যাওয়ার সাথে সাথে **My Post** স্ক্রিনে গিয়ে **"ভাড়া হয়ে গেছে (Rented Out)"** সুইচটি চালু করে দিন। এতে আপনার বিজ্ঞাপনটি সাধারণ অনুসন্ধান থেকে সম্পূর্ণ অদৃশ্য ও সংরক্ষিত থাকবে। পরবর্তীতে আবার বাসা খালি হলে এক ক্লিকেই পুনরায় লাইভ করতে পারবেন।

**প্রশ্ন ৩: ভাড়াটিয়াদের সক্রিয় চাহিদা (Tenant Demands) কীভাবে খুঁজে পাব?**
👉 **উত্তর:** ড্যাশবোর্ডের **"Demand"** স্ক্রিনে যান অথবা এই এআই সহকারীর মাধ্যমে আপনার এলাকার সক্রিয় ভাড়াটিয়াদের চাহিদাপত্র ও বাজেট ফিল্টার (যেমন: ৳৬,০০০-১০,০০০, ৳১১,০০০-১৫,০০০) দেখে সরাসরি আগ্রহী ভাড়াটিয়ার সাথে যোগাযোগ করতে পারেন।

**প্রশ্ন ৪: ভাড়াটিয়াদের 'বাসা পেয়ে গেছি (Mark as Fulfilled)' বোতামের কাজ কী?**
👉 **উত্তর:** ভাড়াটিয়া পছন্দের বাসা পেয়ে গেলে তার **My Demand** স্ক্রিন থেকে এই বোতামটি চালু করে দেন। ফলে বাড়িওয়ালারা আর সেই পুরনো চাহিদাটি দেখতে পান না এবং অপ্রয়োজনীয় যোগাযোগ বন্ধ হয়।

**প্রশ্ন ৫: এআই প্রস্তাবিত ভাড়ার রেঞ্জ (Suggest Price Range) কীভাবে সাহায্য করে?**
👉 **উত্তর:** বাসাবন্ধু এআই ডাটাবেজ অ্যানালাইসিস করে এলাকা, রুম এবং বিশেষ সুবিধা (লিফট, পার্কিং, জেনারেটর ব্যাকআপ, তিতাস গ্যাস) বিবেচনা করে অন্য বাড়িওয়ালাদের গোপনীয়তা অক্ষুণ্ণ রেখে আপনার বাসার জন্য ন্যায্য ও যৌক্তিক ভাড়ার পরামর্শ প্রদান করে।

**প্রশ্ন ৬: বাড়িওয়ালা সাবস্ক্রিপশন প্যাকেজের সুবিধা কী এবং রসিদ কোথায় পাওয়া যাবে?**
👉 **উত্তর:** সাবস্ক্রিপশন প্ল্যানের মাধ্যমে একাধিক বিজ্ঞাপন প্রকাশ, বিজ্ঞাপনে 'Featured' বা 'Verified' ব্যাজ এবং দ্রুত ভাড়াটিয়া পাওয়ার সুবিধা পাওয়া যায়। সকল সফল পেমেন্টের ডিজিটাল রসিদ **Subscription History**-তে সংরক্ষিত থাকে।

**প্রশ্ন ৭: পাসওয়ার্ড ভুলে গেলে কীভাবে জিমেইলে রিকভার করব?**
👉 **উত্তর:** সাইন ইন স্ক্রিনের নিচে **"Forgot Password?"**-এ চাপ দিয়ে আপনার নিবন্ধিত জিমেইলটি লিখুন। সাথে সাথে ফায়ারবেস থেকে আপনার ইমেইলে একটি নিরাপদ পাসওয়ার্ড রিসেট লিংক সম্পূর্ণ বিনামূল্যে পাঠানো হবে।

**প্রশ্ন ৮: বাসাবন্ধু কীভাবে প্রপার্টি বিজ্ঞাপন ও ব্যবহারকারীদের নিরাপত্তা নিশ্চিত করে?**
👉 **উত্তর:** আমরা মোবাইল ওটিপি (OTP) ও এনআইডি ভেরিফিকেশনের মাধ্যমে প্রকৃত ব্যবহারকারী নিশ্চিত করি এবং ভুয়া বা বিভ্রান্তিকর বিজ্ঞাপন প্রতিরোধে নিয়মিত অডিট পরিচালনা করি।'''
          : '''❓ **BashaBondhu Frequently Asked Questions (FAQs):**

**Q1: How do I post a free To-Let advertisement as a House Owner?**
👉 **Answer:** Sign in as a House Owner and tap the **"Post Free"** or **"+"** button on your dashboard. Enter your property location (Division, District, Area, Sub-Area), room configurations (bedrooms, bathrooms, balconies, floor level), monthly rent, deposit, and upload clear photos to publish immediately.

**Q2: What is the "Rented Out" toggle button and how do I use it?**
👉 **Answer:** Once your property is rented, go to the **My Post** screen and turn ON the **"Rented Out"** toggle. This immediately hides your listing from tenant search feeds while keeping your data safe. When the house becomes vacant again, you can reactivate it with a single tap.

**Q3: How can House Owners find and match active Tenant Demands?**
👉 **Answer:** Open the **"Demand"** tab from your dashboard or ask this AI Assistant. You can browse active renter requests in your area, filter by budget ranges (e.g. ৳6k-10k, ৳11k-15k), and directly call interested tenants.

**Q4: What is the "Mark as Fulfilled" toggle for tenants?**
👉 **Answer:** When a tenant secures a rental home, enabling this toggle on their **My Demand** screen marks the demand as fulfilled and removes it from house owners' demand feeds.

**Q5: How does the AI Suggested Rent Price Range help landlords?**
👉 **Answer:** The AI analyzes live platform market data across areas, rooms, and premium amenities (Lift, Parking, Generator backup, Gas) to recommend fair, competitive rental prices while strictly protecting every landlord's listing privacy.

**Q6: What are the benefits of House Owner Subscription Packages and where is the receipt?**
👉 **Answer:** Subscription packages allow owners to publish multiple listings, get "Featured" top placement badges, and unlock direct tenant contact numbers. All digital transaction receipts are archived in **Subscription History**.

**Q7: How do I recover my password if forgotten?**
👉 **Answer:** On the Sign In screen, click **"Forgot Password?"**. Enter your registered Gmail address and Firebase will instantly send a secure password reset link to your email free of cost.

**Q8: How does BashaBondhu ensure listing authenticity & security?**
👉 **Answer:** We verify users via mobile OTP and NID verification, and conduct manual audits on listings to prevent fake or misleading advertisements.''';

      return AIResponseData(
        replyText: faqText,
        intent: 'general',
        interactiveChips: isBn
            ? (isOwner
                ? ['📖 কীভাবে অ্যাপ ব্যবহার করবেন', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '⚡ প্রধান ৪টি অপশন']
                : ['🔍 বাসা খুঁজুন', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি'])
            : (isOwner
                ? ['📖 How to Use', '👥 Find Tenant Demand', '💡 Suggest Price Range', '⚡ Main 4 Options']
                : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History']),
        quickFollowUps: isBn ? ['কীভাবে অ্যাপ ব্যবহার করবেন', 'প্রাইভেসি পলিসি', 'শর্তাবলী'] : ['How to Use', 'Privacy Policy', 'Terms & Conditions'],
      );
    }

    // ==========================================
    // 2.5 HOW TO USE THIS APP (ব্যবহার নির্দেশিকা)
    // ==========================================
    if (lower.contains('how to use') ||
        lower.contains('how to use this app') ||
        lower.contains('কীভাবে অ্যাপ ব্যবহার করবেন') ||
        lower.contains('কীভাবে অ্যাপ ব্যবহার করব') ||
        lower.contains('ব্যবহার নির্দেশিকা') ||
        lower.contains('ব্যবহার পদ্ধতি') ||
        lower.contains('user guide') ||
        lower.contains('app guide')) {
      final guideText = isBn
          ? '''📖 **বাড়িওয়ালাদের জন্য বাসাবন্ধু অ্যাপ ব্যবহারের সহজ নির্দেশিকা (Step-by-Step Guide):**

১️⃣ **অ্যাকাউন্ট ও প্রোফাইল সেটআপ (Account Setup):**
   • বাড়িওয়ালা (House Owner) হিসেবে সাইন ইন করে আপনার প্রোফাইল সম্পূর্ণ করুন।
   • অ্যাকাউন্টে আপনার নাম ও মোবাইল নম্বর নিশ্চিত রাখুন যাতে ভাড়াটিয়ারা সহজে যোগাযোগ করতে পারে।

২️⃣ **বিনামূল্যে টু-লেট বিজ্ঞাপন পোস্ট (Post Free To-Let Ad):**
   • ড্যাশবোর্ডের নিচে **"Post Free"** অথবা **"+"** বাটনে চাপ দিন।
   • আপনার বাসার বিভাগ, জেলা, এলাকা, সাব-এরিয়া, বেডরুম, বাথরুম, ভাড়া এবং পরিষ্কার ছবি আপলোড করে মুহূর্তেই লাইভ করুন।

৩️⃣ **বিজ্ঞাপন নিয়ন্ত্রণ ও "ভাড়া হয়ে গেছে" বোতাম (Listing Control & "Rented Out"):**
   • বাসা ভাড়া হয়ে যাওয়ার সাথে সাথে **My Post** স্ক্রিন থেকে **"ভাড়া হয়ে গেছে (Rented Out)"** সুইচটি অন করে দিন।
   • এতে আপনার বিজ্ঞাপনটি সাধারণ অনুসন্ধান থেকে সুরক্ষিত ও হাইড থাকবে। বাসা খালি হলে পুনরায় এক ক্লিকেই আবার লাইভ করতে পারবেন।

৪️⃣ **ভাড়াটিয়াদের লাইভ চাহিদা ও ডিমান্ড ব্রাউজিং (Browse Tenant Demands):**
   • **"Demand"** স্ক্রিন অথবা এই এআই সহকারীর মাধ্যমে এলাকার সক্রিয় ভাড়াটিয়াদের পোস্ট ও বাজেট চেক করুন।
   • আপনার বাসার সাথে মিলে গেলে সরাসরি তাদের সাথে যোগাযোগ করে দ্রুত বাসা ভাড়া দিন।

৫️⃣ **এআই ভাড়ার পূর্বাভাস ও মার্কেট গাইড (AI Suggest Price Range):**
   • আপনার এলাকার নাম লিখে এআই-কে জিজ্ঞেস করুন ন্যায্য ভাড়ার রেঞ্জ জানতে।
   • লিফট, পার্কিং ও জেনারেটর সুবিধার জন্য কত ভাড়া বাড়ানো যৌক্তিক তা যাচাই করুন।

৬️⃣ **সাবস্ক্রিপশন প্যাকেজ ও ফিচার্ড বুস্টিং (Subscription Packages):**
   • একাধিক প্রপার্টি লিস্টিং ও প্রিমিয়াম ভেরিফাইড ব্যাজের জন্য সুবিধাজনক সাবস্ক্রিপশন প্যাকেজ বেছে নিন।
   • ডিজিটাল পেমেন্ট রসিদ ও লেনদেনের ইতিহাস সংরক্ষণ থাকে **Subscription History**-তে।

৭️⃣ **দ্বিভাষিক সুবিধা ও পাসওয়ার্ড রিকভারি (Bilingual & Password Reset):**
   • উপরে ট্রান্সলেট আইকন চেপে যেকোনো সময় বাংলা ও ইংরেজিতে সুইচ করুন।
   • পাসওয়ার্ড ভুলে গেলে সাইন ইন স্ক্রিনের "Forgot Password?" দিয়ে ফ্রিতে জিমেইলের মাধ্যমে রিসেট করুন।
──────────────────
💡 *অ্যাপ ব্যবহারের যেকোনো বিষয়ে আরও বিস্তারিত জানতে নিচের বাটনে ক্লিক করুন।*'''
          : '''📖 **Step-by-Step Guide: How to Use BashaBondhu as a House Owner:**

1️⃣ **Account Setup & Profile:**
   • Sign in with your House Owner credentials and keep your contact details updated.

2️⃣ **Post Free To-Let Advertisements:**
   • Tap the **"Post Free"** or **"+"** button at the bottom of your dashboard.
   • Provide Division, District, Area, Sub-Area, rent, room configurations, and photos to publish instantly.

3️⃣ **Listing Control & "Rented Out" Toggle:**
   • When your home gets rented, turn on the **"Rented Out"** toggle on the **My Post** screen.
   • This keeps your listing hidden from public search until the apartment is available again.

4️⃣ **Browse & Match Tenant Demands:**
   • Open the **"Demand"** screen or ask this AI Assistant to view live tenant requirements and budgets in your neighborhood.
   • Connect directly with prospective renters to minimize vacancy time.

5️⃣ **AI Market Rental Predictions & Fair Guidance:**
   • Ask the AI for fair rent estimates based on area, rooms, lifts, generators, and parking.

6️⃣ **Subscription Packages & Verified Boosts:**
   • Upgrade to premium packages to list multiple properties and gain verified trust badges.
   • View digital receipts anytime in **Subscription History**.

7️⃣ **Bilingual Switch & Password Recovery:**
   • Toggle English/Bengali from any screen AppBar.
   • Reset forgotten passwords seamlessly via free Firebase Gmail links.
──────────────────
💡 *Tap any quick option below to explore further.*''';

      return AIResponseData(
        replyText: guideText,
        intent: 'general',
        interactiveChips: isBn
            ? ['❓ সাধারণ জিজ্ঞাসা (FAQ)', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '⚡ প্রধান ৪টি অপশন']
            : ['❓ FAQ', '👥 Find Tenant Demand', '💡 Suggest Price Range', '⚡ Main 4 Options'],
        quickFollowUps: isBn ? ['সাধারণ জিজ্ঞাসা (FAQ)', 'সাবস্ক্রিপশন প্যাকেজ', '⚡ প্রধান ৪টি অপশন'] : ['FAQ', 'Subscription Packages', '⚡ Main 4 Options'],
      );
    }

    // ==========================================
    // 3. PRIVACY POLICY (প্রাইভেসি পলিসি)
    // ==========================================
    if (lower.contains('privacy') ||
        lower.contains('privacy policy') ||
        lower.contains('গোপনীয়তা') ||
        lower.contains('প্রাইভেসি পলিসি') ||
        lower.contains('প্রাইভেসি নীতি') ||
        lower.contains('ডাটা পলিসি')) {
      final privacyText = isBn
          ? '''🛡️ **বাসাবন্ধু গোপনীয়তা ও ডাটা সুরক্ষা নীতিমালা (Privacy Policy):**

বাসাবন্ধু ব্যবহারকারীদের ব্যক্তিগত তথ্যের সর্বোচ্চ গোপনীয়তা ও নিরাপত্তায় অঙ্গীকারবদ্ধ।

🔐 **আমাদের মূল গোপনীয়তা রক্ষাকবচ:**
1. **ব্যক্তিগত তথ্যের সুরক্ষা:** আপনার পাসওয়ার্ড, ব্যক্তিগত ইমেইল এবং পেমেন্ট কার্ড বা ব্যাংকিং টোকেন ফায়ারবেস ক্লাউডে সম্পূর্ণ এনক্রিপ্টেড থাকে এবং কখনোই অন্য কোনো ব্যবহারকারী বা তৃতীয় পক্ষের কাছে প্রকাশ করা হয় না।
2. **যোগাযোগ তথ্যের গোপনীয়তা:** ভাড়াটিয়া বা বাড়িওয়ালার যোগাযোগের নম্বর শুধুমাত্র প্ল্যাটফর্মের নির্ধারিত নিয়মে এবং সংশ্লিষ্ট পক্ষদ্বয়ের সম্মতিক্রমে যোগাযোগের জন্য ব্যবহৃত হয়।
3. **কোনো ডাটা বিক্রয় নয়:** বাসাবন্ধু ব্যবহারকারীদের কোনো ডাটা বিজ্ঞাপন বা অন্য কোনো বাণিজ্যিক উদ্দেশ্যে বিক্রি বা হস্তান্তর করে না।
4. **সম্পূর্ণ ব্যবহারকারী নিয়ন্ত্রণ:** আপনি যেকোনো সময় আপনার পোস্ট, ডিমান্ড, অথবা ব্যক্তিগত প্রোফাইল আপডেট বা ডিলিট করতে পারেন।'''
          : '''🛡️ **BashaBondhu Privacy Policy:**

BashaBondhu is strictly committed to protecting the privacy, confidentiality, and security of our users.

🔐 **Our Core Privacy Standards:**
1. **Data Encryption & Protection:** Passwords, private emails, and payment transaction credentials are fully encrypted with Google Firebase Cloud Security and are NEVER disclosed to any third party.
2. **Contact Privacy:** Direct phone numbers and sensitive contacts are shielded and only unlocked through verified, authorized platform interactions.
3. **No Data Selling:** We strictly do not sell, rent, or lease user personal data to third-party advertisers.
4. **User Full Control:** You have full authority to view, modify, toggle visibility, or delete your posts and profile data at any time.''';

      return AIResponseData(
        replyText: privacyText,
        intent: 'general',
        interactiveChips: isBn
            ? (isOwner
                ? ['👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💰 বিভিন্ন এলাকার ভাড়ার রেঞ্জ', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি']
                : ['🔍 বাসা খুঁজুন', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি'])
            : (isOwner
                ? ['👥 Find Tenant Demand', '💰 Area Rent Price Range', '💳 Subscription Packages', '📄 Subscription History']
                : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History']),
        quickFollowUps: isBn ? ['ব্যবহারের শর্তাবলী', 'সাধারণ জিজ্ঞাসা (FAQ)', 'অ্যাপ ওভারভিউ'] : ['Terms & Conditions', 'FAQ', 'App Overview'],
      );
    }

    // ==========================================
    // 4. TERMS & CONDITIONS (ব্যবহারিক শর্তাবলী)
    // ==========================================
    if (lower.contains('terms') ||
        lower.contains('conditions') ||
        lower.contains('terms and conditions') ||
        lower.contains('শর্তাবলী') ||
        lower.contains('ব্যবহারের শর্তাবলী') ||
        lower.contains('টার্মস অ্যান্ড কন্ডিশনস')) {
      final termsText = isBn
          ? '''📜 **বাসাবন্ধু প্ল্যাটফর্ম ব্যবহারের নিয়ম ও শর্তাবলী (Terms & Conditions):**

বাসাবন্ধু অ্যাপ ব্যবহারের সময় সকল ব্যবহারকারীকে নিচের নিয়মাবলী মেনে চলতে হবে:

1. **বিজ্ঞাপনের সত্যতা:** বাড়িওয়ালাদের অবশ্যই বাস্তব ছবি, সঠিক লোকেশন, সঠিক ফ্লোর এবং প্রকৃত মাসিক ভাড়া উল্লেখ করতে হবে। কোনো ভুয়া বা বিভ্রান্তিকর বিজ্ঞাপন পোস্ট করা সম্পূর্ণ নিষিদ্ধ।
2. **ভাড়াটিয়াদের আচরণবিধি:** ভাড়াটিয়াদের অবশ্যই সঠিক চাহিদার তথ্য দিতে হবে এবং বাড়িওয়ালার সাথে শালীন ও দায়িত্বশীল আচরণ বজায় রাখতে হবে।
3. **প্ল্যাটফর্মের স্বচ্ছতা:** বাসা ভাড়া সম্পন্ন হলে অবিলম্বে 'Rented Out' বা 'বাসা পেয়ে গেছি' বোতাম দিয়ে বিজ্ঞাপন আপডেট করা বাধ্যতামূলক।
4. **সাবস্ক্রিপশন নীতিমালা:** ডিজিটাল সাবস্ক্রিপশন প্ল্যান গ্রহণের সাথে সাথে এর নির্ধারিত সুবিধাসমূহ সক্রিয় হয়।
5. **নিরাপত্তা লঙ্ঘন:** জালিয়াতি, প্রতারণা বা অন্য ব্যবহারকারীকে হয়রানির চেষ্টা করা হলে সংশ্লিষ্ট অ্যাকাউন্টটি তাৎক্ষণিকভাবে স্থায়ীভাবে বাতিল করা হবে।'''
          : '''📜 **BashaBondhu Terms & Conditions:**

All users must adhere to the following community standards and platform terms:

1. **Authenticity of Listings:** House owners must provide genuine property photos, accurate addresses, and true rental pricing. Fraudulent or misleading listings are strictly prohibited.
2. **Tenant Responsibilities:** Tenants must submit genuine demand criteria and communicate respectfully with landlords.
3. **Listing Accuracy:** Users are required to toggle "Rented Out" or "Mark as Fulfilled" immediately once a rental agreement is finalized.
4. **Subscription Policy:** Digital subscription benefits activate instantly upon successful transaction.
5. **Zero Tolerance for Misconduct:** Any fraudulent, harassing, or malicious activity will result in immediate and permanent account termination.''';

      return AIResponseData(
        replyText: termsText,
        intent: 'general',
        interactiveChips: isBn
            ? (isOwner
                ? ['👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💰 বিভিন্ন এলাকার ভাড়ার রেঞ্জ', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি']
                : ['🔍 বাসা খুঁজুন', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি'])
            : (isOwner
                ? ['👥 Find Tenant Demand', '💰 Area Rent Price Range', '💳 Subscription Packages', '📄 Subscription History']
                : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History']),
        quickFollowUps: isBn ? ['গোপনীয়তা নীতি', 'সাধারণ জিজ্ঞাসা (FAQ)', 'অ্যাপ ওভারভিউ'] : ['Privacy Policy', 'FAQ', 'App Overview'],
      );
    }

    // ==========================================
    // 5. SUPPORT & REFUND POLICIES
    // ==========================================
    if (lower.contains('refund') || lower.contains('রিফান্ড') || lower.contains('টাকা ফেরত')) {
      final refundText = isBn
          ? '💳 **বাসাবন্ধু রিফান্ড পলিসি (Refund Policy):**\n\nসাবস্ক্রিপশন সংক্রান্ত কোনো ট্রানজেকশনে টেকনিক্যাল ত্রুটি হলে অথবা প্যাকেজের সুবিধা প্রদান ব্যাহত হলে ২৪ ঘণ্টার মধ্যে আমাদের সাপোর্ট হেল্পডেস্কে যোগাযোগ করলে তদন্তসাপেক্ষে দ্রুত সমাধান ও রিফান্ড প্রক্রিয়া সম্পন্ন করা হয়।'
          : '💳 **BashaBondhu Refund Policy:**\n\nIf any technical issue occurs during a subscription payment or benefit activation, our 24/7 support team will promptly investigate and process eligible refunds.';
      return AIResponseData(
        replyText: refundText,
        intent: 'general',
        interactiveChips: isBn ? ['💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '⚡ প্রধান ৪টি অপশন'] : ['💳 Subscription Packages', '📄 Subscription History', '⚡ Main 4 Options'],
      );
    }

    if (lower.contains('support') || lower.contains('help') || lower.contains('সাপোর্ট') || lower.contains('সহায়তা') || lower.contains('হেল্প')) {
      final supportText = isBn
          ? '🤝 **বাসাবন্ধু সাপোর্ট ও হেল্প সেন্টার (Support Policy):**\n\nআমাদের ডেডিকেটেড টিম ব্যবহারকারীদের সার্বক্ষণিক সহায়তা প্রদানে নিয়োজিত। যেকোনো প্রশ্ন বা সমস্যার জন্য ইন-অ্যাপ সাপোর্ট ও এআই সহকারীর সাহায্য নিতে পারেন।'
          : '🤝 **BashaBondhu Support & Helpdesk:**\n\nOur dedicated support team is available 24/7. Feel free to ask questions here or reach out through the Support Center.';
      return AIResponseData(
        replyText: supportText,
        intent: 'general',
        interactiveChips: isBn ? ['সাধারণ জিজ্ঞাসা (FAQ)', 'গোপনীয়তা নীতি', '⚡ প্রধান ৪টি অপশন'] : ['FAQ', 'Privacy Policy', '⚡ Main 4 Options'],
      );
    }

    // ==========================================
    // 6. SPECIFIC LOCATION RENT PRICE QUERY INTENT
    // ==========================================
    final locationMatch = _extractLocationKeyword(prompt);
    if (locationMatch != null &&
        (lower.contains('price') ||
            lower.contains('rance') ||
            lower.contains('range') ||
            lower.contains('rent') ||
            lower.contains('rate') ||
            lower.contains('ভাড়া') ||
            lower.contains('রেঞ্জ') ||
            lower.contains('দর') ||
            lower.contains('খরচ') ||
            lower.contains('কতো') ||
            lower.contains('কত') ||
            lower.contains('টাকা') ||
            lower.contains('list') ||
            lower.contains('guide') ||
            lower.contains('তালিকা') ||
            lower.contains('suggest') ||
            lower.contains('প্রস্তাবিত'))) {
      return AIResponseData(
        replyText: isBn
            ? '💡 **$locationMatch** এলাকার জন্য এআই প্রস্তাবিত ভাড়ার রেঞ্জ বিশ্লেষণ করা হচ্ছে...'
            : '💡 Analyzing AI suggested rent price ranges for **$locationMatch**...',
        intent: 'pricing_advice',
        searchFilters: {'area': locationMatch},
        interactiveChips: isBn
            ? ['🔍 সকল এলাকা', locationMatch, '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '⚡ প্রধান ৪টি অপশন']
            : ['🔍 All Areas', locationMatch, '👥 Find Tenant Demand', '⚡ Main 4 Options'],
      );
    }

    // ==========================================
    // 7. SUBSCRIPTION HISTORY
    // ==========================================
    if (lower.contains('subscription history') ||
        lower.contains('সাবস্ক্রিপশন হিস্ট্রি') ||
        lower.contains('হিস্ট্রি') ||
        lower.contains('রিসিট') ||
        lower.contains('receipt') ||
        lower.contains('transaction')) {
      return AIResponseData(
        replyText: isBn
            ? '📄 আপনার **সাবস্ক্রিপশন হিস্ট্রি ও পেমেন্ট রিসিট** দেখতে নিচে বাটনে চাপ দিন:'
            : '📄 Click below to view your **Subscription History & Payment Receipts**:',
        intent: 'subscription_history',
        interactiveChips: isBn
            ? ['💳 সাবস্ক্রিপশন প্যাকেজ', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '⚡ প্রধান ৪টি অপশন']
            : ['💳 Subscription Packages', '👥 Find Tenant Demand', '💡 Suggest Price Range', '⚡ Main 4 Options'],
        quickFollowUps: isBn ? ['সাবস্ক্রিপশন প্যাকেজ দেখুন', 'আমার প্রোফাইল'] : ['View Subscription Packages', 'My Profile'],
      );
    }

    // ==========================================
    // 8. SUBSCRIPTION PACKAGES
    // ==========================================
    if (lower.contains('subscription package') ||
        lower.contains('প্যাকেজ') ||
        lower.contains('package') ||
        lower.contains('সাবস্ক্রিপশন') ||
        lower.contains('subscribe')) {
      return AIResponseData(
        replyText: isBn
            ? '💳 আপনার জন্য উপলব্ধ **সাবস্ক্রিপশন প্যাকেজসমূহ** দেখতে এবং সুবিধা আপগ্রেড করতে নিচে বাটনে চাপ দিন:'
            : '💳 Click below to explore available **Subscription Packages** and upgrade your benefits:',
        intent: 'subscription_packages',
        interactiveChips: isBn
            ? ['📄 সাবস্ক্রিপশন হিস্ট্রি', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '⚡ প্রধান ৪টি অপশন']
            : ['📄 Subscription History', '👥 Find Tenant Demand', '💡 Suggest Price Range', '⚡ Main 4 Options'],
        quickFollowUps: isBn ? ['সাবস্ক্রিপশন হিস্ট্রি', 'বাসা খুঁজুন'] : ['Subscription History', 'Find a Home'],
      );
    }

    // ==========================================
    // 9. MY PROFILE
    // ==========================================
    if (lower.contains('profile') ||
        lower.contains('প্রোফাইল') ||
        lower.contains('আমার তথ্য') ||
        lower.contains('account')) {
      return AIResponseData(
        replyText: isBn
            ? '👤 আপনার **প্রোফাইল তথ্য ও সেটিংস** দেখতে নিচে বাটনে চাপ দিন:'
            : '👤 Click below to view and edit your **Profile & Account Information**:',
        intent: 'my_profile',
        interactiveChips: isBn
            ? ['💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '⚡ প্রধান ৪টি অপশন']
            : ['💳 Subscription Packages', '📄 Subscription History', '⚡ Main 4 Options'],
      );
    }

    // ==========================================
    // 10. ADMIN LIVE STATS
    // ==========================================
    if (isAdmin && (lower.contains('stat') || lower.contains('হিসাব') || lower.contains('ইউজার') || lower.contains('পোস্ট') || lower.contains('revenue'))) {
      return AIResponseData(
        replyText: isBn
            ? '📊 **বাসাবন্ধু প্ল্যাটফর্মের বর্তমান লাইভ পরিসংখ্যান:**'
            : '📊 **BashaBondhu Platform Live Statistics:**',
        intent: 'admin_stats',
        quickFollowUps: isBn
            ? ['মোট প্রপার্টি কতটি?', 'সাবস্ক্রিপশন ট্রানজেকশন দেখাও', 'জনপ্রিয় এলাকাগুলো কী কী?']
            : ['Total properties count', 'Show subscription transactions', 'Top popular areas'],
      );
    }

    // ==========================================
    // 11. PROPERTY SEARCH INTENT (TENANT)
    // ==========================================
    if (lower.contains('বাসা') ||
        lower.contains('ফ্ল্যাট') ||
        lower.contains('রুম') ||
        lower.contains('মেস') ||
        lower.contains('house') ||
        lower.contains('flat') ||
        lower.contains('rent') ||
        lower.contains('find')) {
      final matchedLoc = _extractLocationKeyword(prompt);
      final priceMatch = RegExp(r'(\d{4,6})').firstMatch(lower);
      int? maxPrice;
      if (priceMatch != null) {
        maxPrice = int.tryParse(priceMatch.group(1)!);
      }

      return AIResponseData(
        replyText: isBn
            ? (matchedLoc != null
                ? 'আমি **$matchedLoc** এলাকায় আপনার জন্য সেরা বাসাগুলো খুঁজে বের করেছি। নিচে কার্ডে ক্লিক করে বিস্তারিত দেখুন:'
                : 'আপনার চাহিদামতো উপলব্ধ বাসাগুলোর তালিকা নিচে দেওয়া হলো:')
            : (matchedLoc != null
                ? 'Found matching rental homes in **$matchedLoc**. See listings below:'
                : 'Here are the matching properties based on your request:'),
        intent: 'search_properties',
        searchFilters: {
          'area': matchedLoc,
          'max_price': maxPrice,
        },
        interactiveChips: isBn
            ? ['🔍 এখনই সার্চ করব', 'মিরপুর', 'উত্তরা', 'ধানমন্ডি', '১৫০০০ টাকার মধ্যে']
            : ['🔍 Search Now', 'Mirpur', 'Uttara', 'Dhanmondi', 'Under ৳15000'],
        quickFollowUps: isBn
            ? ['উত্তরায় ২ বেডরুমের বাসা', 'মিরপুরে ব্যাচেলর রুম', 'ধানমন্ডিতে ফ্যামিলি ফ্ল্যাট']
            : ['2 Bed in Uttara', 'Bachelor Room in Mirpur', 'Family Flat in Dhanmondi'],
      );
    }

    // ==========================================
    // 12. DEFAULT GREETINGS & GUIDED 4 CORE OPTIONS
    // ==========================================
    return AIResponseData(
      replyText: isBn
          ? (isAdmin
              ? '👋 স্বাগতম অ্যাডমিন! আমি বাসাবন্ধু এআই সহকারী। প্ল্যাটফর্মের পরিসংখ্যান, প্রপার্টি পোস্ট বা সাবস্ক্রিপশন রিপোর্ট জানতে নিচে অপশন সিলেক্ট করুন বা প্রশ্ন লিখুন।'
              : isOwner
                  ? '👋 স্বাগতম! আমি **বাসাবন্ধু এআই সহকারী**। বাড়িওয়ালাদের জন্য ৪টি প্রধান অপশন থেকে বেছে নিন অথবা যে কোনো প্রশ্ন লিখুন:\n\n১. 👥 **ভাড়াটিয়াদের ডিমান্ড খুঁজুন**\n২. 💡 **প্রস্তাবিত ভাড়ার রেঞ্জ (AI Market Suggestion)**\n৩. 💳 **সাবস্ক্রিপশন প্যাকেজ**\n৪. 📄 **সাবস্ক্রিপশন হিস্ট্রি**'
                  : '👋 স্বাগতম! আমি **বাসাবন্ধু এআই সহকারী**। আপনি কোনো ফর্ম পূরণ না করে কেবল মুখে বলে বা লিখে বাসা খুঁজতে, ডিমান্ড পোস্ট করতে ও সাবস্ক্রিপশন চেক করতে পারেন।')
          : (isAdmin
              ? '👋 Welcome Admin! I am your BashaBondhu AI Assistant. Ask about platform analytics, user stats, or property reports.'
              : isOwner
                  ? '👋 Welcome! I am your **BashaBondhu AI Assistant**. Choose from the 4 core options below or ask any question about the platform:\n\n1. 👥 **Find Tenant Demand**\n2. 💡 **Suggest Price Range (AI Market Prediction)**\n3. 💳 **Subscription Packages**\n4. 📄 **Subscription History**'
                  : '👋 Welcome! I am your **BashaBondhu AI Assistant**. Tell me what kind of home you are looking for, or post a demand conversationally.'),
      intent: 'general',
      interactiveChips: isBn
          ? (isAdmin
              ? ['📊 লাইভ পরিসংখ্যান', '💰 সাবস্ক্রিপশন হিসাব', '📍 জনপ্রিয় এলাকা']
              : isOwner
                  ? ['👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি']
                  : ['🔍 বাসা খুঁজুন (Find a Home)', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '👤 আমার প্রোফাইল'])
          : (isAdmin
              ? ['📊 Live Analytics', '💰 Subscription Revenue', '📍 Top Areas']
              : isOwner
                  ? ['👥 Find Tenant Demand', '💡 Suggest Price Range', '💳 Subscription Packages', '📄 Subscription History']
                  : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History', '👤 My Profile']),
      quickFollowUps: isBn
          ? (isOwner
              ? ['⚡ প্রধান ৪টি অপশন', 'গাজীপুরের প্রস্তাবিত ভাড়া', 'মিরপুরের প্রস্তাবিত ভাড়া', 'উত্তরার প্রস্তাবিত ভাড়া']
              : ['১৫০০০ টাকার মধ্যে বাসা দেখাও', 'মিরপুরে ফ্যামিলি ফ্ল্যাট', 'ব্যাচেলর সিট দরকার'])
          : (isOwner
              ? ['⚡ Main 4 Options', 'Gazipur Suggested Price', 'Mirpur Suggested Price', 'Uttara Suggested Price']
              : ['Find flats under ৳15000', '2-Bed in Uttara', 'Bachelor Rooms']),
    );
  }

  /// Helper to extract recognizable Bangladesh locations
  String? _extractLocationKeyword(String input) {
    final lower = input.toLowerCase();
    final Map<String, String> locationDictionary = {
      'gazipur': 'Gazipur',
      'গাজীপুর': 'গাজীপুর',
      'mirpur': 'Mirpur',
      'মিরপুর': 'মিরপুর',
      'uttara': 'Uttara',
      'উত্তরা': 'উত্তরা',
      'dhanmondi': 'Dhanmondi',
      'ধানমন্ডি': 'ধানমন্ডি',
      'gulshan': 'Gulshan',
      'গুলশান': 'গুলশান',
      'banani': 'Banani',
      'বনানী': 'বনানী',
      'mohammadpur': 'Mohammadpur',
      'মোহাম্মদপুর': 'মোহাম্মদপুর',
      'bashundhara': 'Bashundhara',
      'বসুন্ধরা': 'বসুন্ধরা',
      'badda': 'Badda',
      'বাড্ডা': 'বাড্ডা',
      'motijheel': 'Motijheel',
      'মতিঝিল': 'মতিঝিল',
      'faridpur': 'Faridpur',
      'ফরিদপুর': 'ফরিদপুর',
      'madaripur': 'Madaripur',
      'মাদারীপুর': 'মাদারীপুর',
      'chittagong': 'Chittagong',
      'chattogram': 'Chattogram',
      'চট্টগ্রাম': 'চট্টগ্রাম',
      'sylhet': 'Sylhet',
      'সিলেট': 'সিলেট',
      'khulna': 'Khulna',
      'খুলনা': 'খুলনা',
      'barishal': 'Barishal',
      'বরিশাল': 'বরিশাল',
      'rajshahi': 'Rajshahi',
      'রাজশাহী': 'রাজশাহী',
      'rangpur': 'Rangpur',
      'রংপুর': 'রংপুর',
      'mymensingh': 'Mymensingh',
      'ময়মনসিংহ': 'ময়মনসিংহ',
      'comilla': 'Comilla',
      'কুমিল্লা': 'কুমিল্লা',
      'savar': 'Savar',
      'সাভার': 'সাভার',
      'narayanganj': 'Narayanganj',
      'নারায়ণগঞ্জ': 'নারায়ণগঞ্জ',
    };

    for (final entry in locationDictionary.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }
}
