import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIResponseData {
  final String replyText;
  final String? intent; // 'search_properties', 'demand_wizard_step', 'property_wizard_step', 'match_tenants', 'admin_stats', 'pricing_advice', 'generate_ad', 'general'
  final Map<String, dynamic>? searchFilters;
  final Map<String, dynamic>? draftData;
  final bool isDraftReady;
  final List<String>? quickFollowUps;

  AIResponseData({
    required this.replyText,
    this.intent,
    this.searchFilters,
    this.draftData,
    this.isDraftReady = false,
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
You are "বাসাবন্ধু এআই (BashaBondhu AI)", the intelligent, ultra-fast, and friendly rental marketplace assistant for Bangladesh's leading home rental platform "বাসাবন্ধু (BashaBondhu)".
User Name: $userName
User Role: $userRole (${isAdmin ? "Platform Admin (অ্যাডমিন)" : isOwner ? "House Owner (বাড়িওয়ালা)" : "Tenant (ভাড়াটিয়া)"})
Language Mode: ${isBn ? "Bengali (বাংলা)" : "English"}

CORE SKILLS & RESPONSIBILITIES:
${isAdmin ? """
1. Admin Analytics & Management:
   - Provide summary insights, total property listings, active users, subscription revenue, and top areas.
   - If user asks about app stats, set intent to "admin_stats".
""" : isOwner ? """
1. House Owner Management & Tools:
   - Conversational Property Posting: Ask step-by-step questions (Area, House Type, Bedrooms, Floor, Rent, Amenities) to prepare a complete listing draft.
   - AI Ad Copywriter: Write structured, attractive To-Let captions with neat emojis (🏠, 📍, 🛏️, 🏢, ⚡, 💰).
   - Tenant Demand Matching: When owner mentions flat details or asks for tenants, set intent to "match_tenants" with criteria.
   - Market Rent Estimator: Provide realistic rent ranges for areas across Dhaka (Mirpur, Uttara, Dhanmondi, Banasree, etc.) and other divisions/districts.
""" : """
1. Tenant Property Search & Demands:
   - Natural Language Search: Understand short queries (e.g. "dhaka flat", "mirpur 10 2 bed", "15k basha"), Banglish, Bengali, or English. Extract area, price range, room count, and house type.
   - Conversational Demand Posting: If user wants to post a demand, ask missing questions one by one (Area -> Budget -> Bedroom count -> Tenant type). When all essential fields are collected, set is_draft_ready to true.
   - Area & Pricing Advice: Provide rental advice, utility bill estimates, and advance deposit norms in Bangladesh.
"""}

CURRENT ACTIVE DRAFT STATE:
${currentDraftState != null ? jsonEncode(currentDraftState) : "None"}

OUTPUT FORMAT:
Respond with a JSON object in this exact schema:
```json
{
  "reply": "Your friendly, helpful Bengali/English response text here (use markdown, emojis, bullet points)",
  "intent": "search_properties" | "demand_wizard_step" | "property_wizard_step" | "match_tenants" | "admin_stats" | "pricing_advice" | "generate_ad" | "general",
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
  "draft_data": {
    "area": "name",
    "budget": "amount",
    "rooms": "room count",
    "house_type": "type",
    "tenant_type": "type",
    "floor": "floor number",
    "amenities": ["Lift", "Parking", "Generator"]
  },
  "is_draft_ready": true | false,
  "quick_follow_ups": ["Follow up chip 1", "Follow up chip 2", "Follow up chip 3"]
}
```
Always be polite, concise, and helpful. If not searching, set search_criteria to null.
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
            draftData: parsed['draft_data'],
            isDraftReady: parsed['is_draft_ready'] == true,
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

    // 1. Admin Stats Intent
    if (isAdmin && (lower.contains('stat') || lower.contains('হিসাব') || lower.contains('ইউজার') || lower.contains('পোস্ট') || lower.contains('user') || lower.contains('revenue'))) {
      return AIResponseData(
        replyText: isBn
            ? '📊 **বাসাবন্ধু প্ল্যাটফর্মের বর্তমান লাইভ পরিসংখ্যান:**\nনিচে সিস্টেমের মোট ইউজার, প্রপার্টি ও সাবস্ক্রিপশন ডাটা উপস্থাপন করা হলো:'
            : '📊 **BashaBondhu Platform Live Statistics:**\nHere is the current system data including users, listings, and subscriptions:',
        intent: 'admin_stats',
        quickFollowUps: isBn
            ? ['মোট প্রপার্টি কতটি?', 'সাবস্ক্রিপশন ট্রানজেকশন দেখাও', 'জনপ্রিয় এলাকাগুলো কী কী?']
            : ['Total properties count', 'Show subscription transactions', 'Top popular areas'],
      );
    }

    // 2. Tenant Demand Wizard Intent
    if (!isOwner && (lower.contains('ডিমান্ড') || lower.contains('demand') || lower.contains('চাই') || lower.contains('প্রয়োজন') || lower.contains('need house'))) {
      if (lower.contains('মিরপুর') || lower.contains('উত্তরা') || lower.contains('ধানমন্ডি') || lower.contains('ঢাকা') || lower.contains('faridpur') || lower.contains('mirpur') || lower.contains('uttara')) {
        return AIResponseData(
          replyText: isBn
              ? 'চমৎকার! আপনার জন্য একটি **Tenant Demand** খসড়া তৈরি করা হয়েছে। নিচে বিস্তারিত দেখে কনফার্ম করুন:'
              : 'Great! A Tenant Demand draft has been prepared based on your preference. Please review below:',
          intent: 'demand_wizard_step',
          isDraftReady: true,
          draftData: {
            'area': lower.contains('মিরপুর') ? 'মিরপুর' : lower.contains('উত্তরা') ? 'উত্তরা' : 'ঢাকা',
            'budget': '12000 - 15000',
            'rooms': 'BedRoom - 2',
            'house_type': 'Flat',
            'tenant_type': 'Family',
          },
          quickFollowUps: isBn
              ? ['হ্যাঁ, ডিমান্ড পোস্ট করুন', 'বাজেট পরিবর্তন করতে চাই', 'এলাকা পরিবর্তন করব']
              : ['Yes, post demand', 'Change budget', 'Change area'],
        );
      } else {
        return AIResponseData(
          replyText: isBn
              ? 'আপনি কোন এলাকায় কত বাজেটের মধ্যে বাসা খুঁজছেন? যেমন: *"মিরপুর ১০ এ ১৫ হাজারের মধ্যে ২ বেডরুম"*।'
              : 'Which area and budget are you looking for? e.g. *"2-Bed in Mirpur 10 within ৳15k"*',
          intent: 'demand_wizard_step',
          quickFollowUps: isBn
              ? ['মিরপুরে ১৫০০০ এর মধ্যে', 'উত্তরায় ২০০০০ এর মধ্যে', 'ধানমন্ডিতে ব্যাচেলর সিট']
              : ['Mirpur under ৳15k', 'Uttara under ৳20k', 'Bachelor Seat in Dhanmondi'],
        );
      }
    }

    // 3. House Owner Tenant Matching Intent
    if (isOwner && (lower.contains('ভাড়াটিয়া') || lower.contains('tenant') || lower.contains('ম্যাচ') || lower.contains('match') || lower.contains('পাবো') || lower.contains('খালি'))) {
      return AIResponseData(
        replyText: isBn
            ? 'আপনার ফ্ল্যাটের চাহিদার সাথে মিল থাকা **সম্ভাব্য আগ্রহী ভাড়াটিয়াদের তালিকা** নিচে দেওয়া হলো:'
            : 'Here are the **matching potential tenant demands** corresponding to your property:',
        intent: 'match_tenants',
        searchFilters: {'area': 'mirpur'},
        quickFollowUps: isBn
            ? ['বিজ্ঞাপনের বিবরণ তৈরি করুন', 'ভাড়ার মূল্য যাচাই করুন', 'পোস্ট পাবলিশ করুন']
            : ['Generate To-Let ad', 'Check rental price guide', 'Publish listing'],
      );
    }

    // 4. Property Search Intent
    if (lower.contains('বাসা') || lower.contains('ফ্ল্যাট') || lower.contains('রুম') || lower.contains('ভাড়া') || lower.contains('house') || lower.contains('flat') || lower.contains('rent')) {
      String? area;
      if (lower.contains('উত্তরা') || lower.contains('uttara')) area = 'uttara';
      if (lower.contains('মিরপুর') || lower.contains('mirpur')) area = 'mirpur';
      if (lower.contains('ধানমন্ডি') || lower.contains('dhanmondi')) area = 'dhanmondi';
      if (lower.contains('গুলশান') || lower.contains('gulshan')) area = 'gulshan';
      if (lower.contains('ফরিদপুর') || lower.contains('faridpur')) area = 'faridpur';

      return AIResponseData(
        replyText: isBn
            ? (area != null
                ? 'আমি **$area** এলাকায় আপনার জন্য সেরা বাসাগুলো খুঁজে বের করেছি। নিচে কার্ডগুলোতে ক্লিক করে বিস্তারিত দেখুন:'
                : 'আপনার চাহিদামতো উপলব্ধ বাসাগুলোর তালিকা নিচে দেওয়া হলো:')
            : (area != null
                ? 'Found available rental homes in **$area**. See listings below:'
                : 'Here are the matching properties based on your request:'),
        intent: 'search_properties',
        searchFilters: {
          'area': ?area,
        },
        quickFollowUps: isBn
            ? ['উত্তরায় ২ বেডরুমের বাসা', 'মিরপুরে ব্যাচেলর রুম', 'ধানমন্ডিতে ফ্যামিলি ফ্ল্যাট']
            : ['2 Bed in Uttara', 'Bachelor Room in Mirpur', 'Family Flat in Dhanmondi'],
      );
    }

    // 5. Default Greetings & Help
    return AIResponseData(
      replyText: isBn
          ? (isAdmin
              ? 'স্বাগতম অ্যাডমিন! আমি বাসাবন্ধু এআই সহকারী। প্ল্যাটফর্মের পরিসংখ্যান, প্রপার্টি পোস্ট বা সাবস্ক্রিপশন রিপোর্ট জানতে প্রশ্ন করতে পারেন।'
              : isOwner
                  ? 'স্বাগতম! আমি বাসাবন্ধু এআই সহকারী। আকর্ষণীয় বিজ্ঞাপন তৈরি করতে, ফ্ল্যাটের ভাড়া নির্ধারণে বা আগ্রহী ভাড়াটিয়া খুঁজতে আমি সাহায্য করতে পারি।'
                  : 'স্বাগতম! আমি বাসাবন্ধু এআই সহকারী। আপনি কোনো ফর্ম পূরণ না করে কেবল মুখে বলে বা লিখে বাসা খুঁজতে ও ডিমান্ড পোস্ট করতে পারেন।')
          : (isAdmin
              ? 'Welcome Admin! I am your BashaBondhu AI Assistant. Ask about platform analytics, user stats, or property reports.'
              : isOwner
                  ? 'Welcome! I am your BashaBondhu AI Assistant. I can help you write To-Let ads, evaluate fair rent, and match prospective tenants.'
                  : 'Welcome! I am your BashaBondhu AI Assistant. Tell me your preferred location, budget, or room requirements to search or post demands.'),
      intent: 'general',
      quickFollowUps: isBn
          ? (isAdmin
              ? ['মোট ইউজার ও প্রপার্টি পরিসংখ্যান', 'সাবস্ক্রিপশন ট্রানজেকশন দেখাও', 'জনপ্রিয় এলাকাগুলো কী কী?']
              : isOwner
                  ? ['বিজ্ঞাপনের আকর্ষণীয় বিবরণ লিখুন', 'মিরপুরে ৩ বেডের সঠিক ভাড়া কত?', 'ভাড়াটিয়াদের ডিমান্ড দেখাও']
                  : ['🔍 ১৫০০০ টাকার মধ্যে বাসা দেখাও', '📝 ডিমান্ড পোস্ট করতে চাই', '📍 উত্তরায় ২ বেডরুমের বাসা'])
          : (isAdmin
              ? ['Show platform stats', 'Recent subscriptions', 'Top areas']
              : isOwner
                  ? ['Write To-Let Description', 'Estimate Fair Rent in Mirpur', 'Show Tenant Demands']
                  : ['Find flats under ৳15000', 'Create a Tenant Demand', '2-Bed in Uttara']),
    );
  }
}
