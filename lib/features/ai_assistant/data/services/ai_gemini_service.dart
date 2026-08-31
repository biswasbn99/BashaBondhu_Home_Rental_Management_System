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
    Map<String, dynamic>? currentDraftState,
    List<Map<String, String>> previousHistory = const [],
  }) async {
    final isBn = languageCode == 'bn';
    final isOwner = userRole.toLowerCase().contains('owner');
    final isAdmin = userRole.toLowerCase().contains('admin');

    final systemInstruction = '''
You are "বাসাবন্ধু এআই (BashaBondhu AI)", the intelligent, ultra-fast, and friendly rental assistant for Bangladesh's leading home rental platform "বাসাবন্ধু (BashaBondhu)".
User Name: $userName
User Role: $userRole (${isAdmin ? "Platform Admin (অ্যাডমিন)" : isOwner ? "House Owner (বাড়িওয়ালা)" : "Tenant (ভাড়াটিয়া)"})
Language Mode: ${isBn ? "Bengali (বাংলা)" : "English"}

CORE ABILITIES:
1. Language Understanding:
   - Understand Bengali, English, and Banglish (e.g. "mirpur 10 a 2 bed flat 15k", "basha khujte chai", "demand post korbo", "subscription package dekhaw").
   - Respond in the language preferred by the user (Bengali if user writes in Bengali/Banglish, English if in English).

2. Tenant Features:
   - Find Home: Natural language search, short keyword search, budget ranges, areas across Bangladesh (Dhaka, Faridpur, Chittagong, Sylhet, etc.).
   - Post Demand: Conversational step-by-step assistance.
   - Subscription & Profile: Instant navigation guidance.

3. House Owner Features:
   - View Demands & Match: Finding active tenant demands with match percentage.
   - To-Let Ad Writer: Structured, attractive captions with emojis (🏠, 📍, 🛏️, 🏢, ⚡, 💰).
   - Fair Rent Price Estimator: Realistic rent ranges for Bangladeshi neighborhoods.

OUTPUT FORMAT:
Respond with a JSON object in this schema:
```json
{
  "reply": "Your friendly, helpful Bengali/English response text here (use markdown, emojis, bullet points)",
  "intent": "search_properties" | "find_home_wizard" | "post_demand_wizard" | "view_demands_wizard" | "subscription_history" | "subscription_packages" | "my_profile" | "admin_stats" | "pricing_advice" | "generate_ad" | "general",
  "search_criteria": {
    "area": "area/thana name or null",
    "district": "district name or null",
    "division": "division name or null",
    "min_price": number or null,
    "max_price": number or null,
    "rooms": "BedRoom - 2" or number or null,
    "house_type": "flat" | "sublet" | "bachelor" | "room" | "unit" or null,
    "tenant_type": "family" | "bachelor" or null
  },
  "interactive_chips": ["Chip 1", "Chip 2", "Chip 3"],
  "quick_follow_ups": ["Prompt 1", "Prompt 2", "Prompt 3"]
}
```
Always be polite, concise, and helpful.
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

    // Fast rule-based fallback
    return _generateRuleBasedFallback(userPrompt, userRole, isBn);
  }

  /// Rule-based fallback engine
  AIResponseData _generateRuleBasedFallback(String prompt, String userRole, bool isBn) {
    final lower = prompt.toLowerCase();
    final isOwner = userRole.toLowerCase().contains('owner');
    final isAdmin = userRole.toLowerCase().contains('admin');

    // 1. Subscription History
    if (lower.contains('subscription history') || lower.contains('সাবস্ক্রিপশন হিস্ট্রি') || lower.contains('হিস্ট্রি') || lower.contains('রিসিট') || lower.contains('receipt')) {
      return AIResponseData(
        replyText: isBn
            ? '📄 আপনার **সাবস্ক্রিপশন হিস্ট্রি ও পেমেন্ট রিসিট** দেখতে নিচে বাটনে চাপ দিন:'
            : '📄 Click below to view your **Subscription History and Payment Receipts**:',
        intent: 'subscription_history',
        quickFollowUps: isBn ? ['সাবস্ক্রিপশন প্যাকেজ দেখুন', 'আমার প্রোফাইল'] : ['View Subscription Packages', 'My Profile'],
      );
    }

    // 2. Subscription Packages
    if (lower.contains('subscription package') || lower.contains('প্যাকেজ') || lower.contains('package') || lower.contains('সাবস্ক্রিপশন') || lower.contains('subscribe')) {
      return AIResponseData(
        replyText: isBn
            ? '⭐ আপনার জন্য উপলব্ধ **সাবস্ক্রিপশন প্যাকেজসমূহ** দেখতে এবং সুবিধা আপগ্রেড করতে নিচে বাটনে চাপ দিন:'
            : '⭐ Click below to explore available **Subscription Packages** and upgrade your benefits:',
        intent: 'subscription_packages',
        quickFollowUps: isBn ? ['সাবস্ক্রিপশন হিস্ট্রি', 'বাসা খুঁজুন'] : ['Subscription History', 'Find a Home'],
      );
    }

    // 3. My Profile
    if (lower.contains('profile') || lower.contains('প্রোফাইল') || lower.contains('আমার তথ্য') || lower.contains('account')) {
      return AIResponseData(
        replyText: isBn
            ? '👤 আপনার **প্রোফাইল তথ্য ও সেটিংস** দেখতে নিচে বাটনে চাপ দিন:'
            : '👤 Click below to view and edit your **Profile & Account Information**:',
        intent: 'my_profile',
        quickFollowUps: isBn ? ['সাবস্ক্রিপশন প্যাকেজ', 'ডিমান্ড পোস্ট'] : ['Subscription Packages', 'Post Demand'],
      );
    }

    // 4. Admin Stats
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

    // 5. Property Search Intent
    if (lower.contains('বাসা') || lower.contains('ফ্ল্যাট') || lower.contains('রুম') || lower.contains('ভাড়া') || lower.contains('house') || lower.contains('flat') || lower.contains('rent') || lower.contains('find')) {
      String? area;
      if (lower.contains('উত্তরা') || lower.contains('uttara')) area = 'uttara';
      if (lower.contains('মিরপুর') || lower.contains('mirpur')) area = 'mirpur';
      if (lower.contains('ধানমন্ডি') || lower.contains('dhanmondi')) area = 'dhanmondi';
      if (lower.contains('গুলশান') || lower.contains('gulshan')) area = 'gulshan';
      if (lower.contains('ফরিদপুর') || lower.contains('faridpur')) area = 'faridpur';

      final priceMatch = RegExp(r'(\d{4,6})').firstMatch(lower);
      int? maxPrice;
      if (priceMatch != null) {
        maxPrice = int.tryParse(priceMatch.group(1)!);
      }

      return AIResponseData(
        replyText: isBn
            ? (area != null
                ? 'আমি **$area** এলাকায় আপনার জন্য সেরা বাসাগুলো খুঁজে বের করেছি। নিচে কার্ডে ক্লিক করে বিস্তারিত দেখুন:'
                : 'আপনার চাহিদামতো উপলব্ধ বাসাগুলোর তালিকা নিচে দেওয়া হলো:')
            : (area != null
                ? 'Found matching rental homes in **$area**. See listings below:'
                : 'Here are the matching properties based on your request:'),
        intent: 'search_properties',
        searchFilters: {
          'area': ?area,
          'max_price': ?maxPrice,
        },
        interactiveChips: isBn
            ? ['🔍 এখনই সার্চ করব', 'মিরপুর', 'উত্তরা', 'ধানমন্ডি', '১৫০০০ টাকার মধ্যে']
            : ['🔍 Search Now', 'Mirpur', 'Uttara', 'Dhanmondi', 'Under ৳15000'],
        quickFollowUps: isBn
            ? ['উত্তরায় ২ বেডরুমের বাসা', 'মিরপুরে ব্যাচেলর রুম', 'ধানমন্ডিতে ফ্যামিলি ফ্ল্যাট']
            : ['2 Bed in Uttara', 'Bachelor Room in Mirpur', 'Family Flat in Dhanmondi'],
      );
    }

    // 6. Default Greetings & Guided Options
    return AIResponseData(
      replyText: isBn
          ? (isAdmin
              ? '👋 স্বাগতম অ্যাডমিন! আমি বাসাবন্ধু এআই সহকারী। প্ল্যাটফর্মের পরিসংখ্যান, প্রপার্টি পোস্ট বা সাবস্ক্রিপশন রিপোর্ট জানতে নিচে অপশন সিলেক্ট করুন বা প্রশ্ন লিখুন।'
              : isOwner
                  ? '👋 স্বাগতম! আমি বাসাবন্ধু এআই সহকারী। আকর্ষণীয় বিজ্ঞাপন তৈরি করতে, ফ্ল্যাটের ভাড়া নির্ধারণে বা আগ্রহী ভাড়াটিয়া খুঁজতে নিচে অপশন বেছে নিন।'
                  : '👋 স্বাগতম! আমি বাসাবন্ধু এআই সহকারী। আপনি কোনো ফর্ম পূরণ না করে কেবল মুখে বলে বা লিখে বাসা খুঁজতে, ডিমান্ড পোস্ট করতে ও সাবস্ক্রিপশন চেক করতে পারেন।')
          : (isAdmin
              ? '👋 Welcome Admin! I am your BashaBondhu AI Assistant. Ask about platform analytics, user stats, or property reports.'
              : isOwner
                  ? '👋 Welcome! I am your BashaBondhu AI Assistant. I can help you write To-Let ads, evaluate fair rent, and match prospective tenants.'
                  : '👋 Welcome! I am your BashaBondhu AI Assistant. Tell me what kind of home you are looking for, or post a demand conversationally.'),
      intent: 'general',
      interactiveChips: isBn
          ? (isAdmin
              ? ['📊 লাইভ পরিসংখ্যান', '💰 সাবস্ক্রিপশন হিসাব', '📍 জনপ্রিয় এলাকা']
              : isOwner
                  ? ['👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '✍️ বিজ্ঞাপনের বিবরণ লিখুন', '💰 ভাড়ার সঠিক মূল্য গাইড', '💳 সাবস্ক্রিপশন প্যাকেজ']
                  : ['🔍 বাসা খুঁজুন (Find a Home)', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '👤 আমার প্রোফাইল'])
          : (isAdmin
              ? ['📊 Live Analytics', '💰 Subscription Revenue', '📍 Top Areas']
              : isOwner
                  ? ['👥 Find Tenant Demands', '✍️ Write To-Let Ad', '💰 Rental Price Guide', '💳 Subscription Packages']
                  : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History', '👤 My Profile']),
      quickFollowUps: isBn
          ? (isOwner
              ? ['বিজ্ঞাপনের বিবরণ তৈরি করুন', 'মিরপুরে ৩ বেডের সঠিক ভাড়া কত?', 'ভাড়াটিয়াদের ডিমান্ড দেখাও']
              : ['১৫০০০ টাকার মধ্যে বাসা দেখাও', 'মিরপুরে ফ্যামিলি ফ্ল্যাট', 'ব্যাচেলর সিট দরকার'])
          : (isOwner
              ? ['Write To-Let Description', 'Estimate Fair Rent in Mirpur', 'Show Tenant Demands']
              : ['Find flats under ৳15000', '2-Bed in Uttara', 'Bachelor Rooms']),
    );
  }
}
