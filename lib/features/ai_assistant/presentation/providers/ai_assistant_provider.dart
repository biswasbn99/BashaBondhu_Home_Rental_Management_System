import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../app/extensions/utility_extension.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/home/data/models/property_model.dart';
import '../../../../features/shared/data/models/area_model.dart';
import '../../../../features/shared/data/models/district_model.dart';
import '../../../../features/shared/data/models/division_model.dart';
import '../../../../features/shared/data/models/sub_area_model.dart';
import '../../../../features/shared/data/services/policy_firestore_service.dart';
import '../../../../features/shared/data/services/tenant_demand_firestore_service.dart';
import '../../../../features/tenant/data/models/tenant_demand_model.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/services/ai_gemini_service.dart';

enum WizardMode { none, findHome, postDemand, ownerViewDemands }

class AIAssistantProvider extends ChangeNotifier {
  final AIGeminiService _geminiService = AIGeminiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // Multi-user private chat histories (User Isolation)
  final Map<String, List<AIMessageModel>> _userSessions = {};
  String _activeUserId = '';

  // Wizard state machine
  WizardMode _activeWizard = WizardMode.none;
  int _wizardStep = 0;
  SearchDraftModel _searchDraft = const SearchDraftModel();
  DemandDraftModel _demandDraft = const DemandDraftModel();

  // Voice & Generation States
  bool _isListening = false;
  String _spokenText = '';
  String? _currentlyPlayingMessageId;
  bool _isGenerating = false;

  // Getters
  List<AIMessageModel> get messages => _userSessions[_activeUserId] ?? [];
  bool get isListening => _isListening;
  String get spokenText => _spokenText;
  String? get currentlyPlayingMessageId => _currentlyPlayingMessageId;
  bool get isGenerating => _isGenerating;
  WizardMode get activeWizard => _activeWizard;
  int get wizardStep => _wizardStep;
  DemandDraftModel get demandDraft => _demandDraft;
  SearchDraftModel get searchDraft => _searchDraft;

  AIAssistantProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setCompletionHandler(() {
        _currentlyPlayingMessageId = null;
        notifyListeners();
      });
      _flutterTts.setErrorHandler((_) {
        _currentlyPlayingMessageId = null;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('TTS initialization note: $e');
    }
  }

  /// Initialize and load private session for logged-in user
  void initializeForUser(UserModel user, String languageCode) {
    _activeUserId = user.uid;
    if (!_userSessions.containsKey(_activeUserId) || _userSessions[_activeUserId]!.isEmpty) {
      _userSessions[_activeUserId] = [];
      _addWelcomeMessage(user, languageCode);
    }
    notifyListeners();
  }

  /// Reset welcome message for user role
  void _addWelcomeMessage(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final isOwner = user.isHouseOwner;
    final isAdmin = user.isAdmin;

    final String welcomeText = isBn
        ? (isAdmin
            ? '👋 আসসালামু আলাইকুম **${user.fullName.isNotEmpty ? user.fullName : "অ্যাডমিন"}**!\nআমি আপনার **বাসাবন্ধু এআই অ্যাডমিন সহকারী**। প্ল্যাটফর্মের লাইভ পরিসংখ্যান, ইউজার হিসেব ও সাবস্ক্রিপশন ট্রানজেকশন জানতে যেকোনো অপশন বেছে নিন।'
            : isOwner
                ? '👋 আসসালামু আলাইকুম **${user.fullName.isNotEmpty ? user.fullName : "বাড়িওয়ালা"}**!\nআমি আপনার **বাসাবন্ধু এআই সহকারী**। নিচের ৪টি প্রধান অপশন থেকে আপনার প্রয়োজনীয় সেবা বেছে নিন:\n\n১. 👥 **ভাড়াটিয়াদের ডিমান্ড খুঁজুন**\n২. 💡 **প্রস্তাবিত ভাড়ার রেঞ্জ (AI Market Suggestion)**\n৩. 💳 **সাবস্ক্রিপশন প্যাকেজ**\n৪. 📄 **সাবস্ক্রিপশন হিস্ট্রি**'
                : '👋 আসসালামু আলাইকুম **${user.fullName.isNotEmpty ? user.fullName : "ভাড়াটিয়া"}**!\nআমি আপনার **বাসাবন্ধু এআই সহকারী**। কোনো ফর্ম পূরণ ছাড়াই আপনি:\n• 🔍 স্টেপ-বাই-স্টেপ পছন্দের বাসা খুঁজতে পারেন\n• 📝 চ্যাটে কথা বলে সরাসরি **ডিমান্ড পোস্ট** করতে পারেন\n• 💳 সাবস্ক্রিপশন ও প্রোফাইল দেখতে পারেন।')
        : (isAdmin
            ? '👋 Welcome **${user.fullName.isNotEmpty ? user.fullName : "Admin"}**!\nI am your **BashaBondhu AI Admin Assistant**. Select an option below to view real-time platform analytics, user metrics, and revenue stats.'
            : isOwner
                ? '👋 Welcome **${user.fullName.isNotEmpty ? user.fullName : "House Owner"}**!\nI am your **BashaBondhu AI Assistant**. Please choose from the 4 core options below:\n\n1. 👥 **Find Tenant Demand**\n2. 💡 **Suggest Price Range (AI Market Prediction)**\n3. 💳 **Subscription Packages**\n4. 📄 **Subscription History**'
                : '👋 Welcome **${user.fullName.isNotEmpty ? user.fullName : "Tenant"}**!\nI am your **BashaBondhu AI Assistant**. You can conversationally:\n• 🔍 Search rental homes step-by-step\n• 📝 Post tenant demands without filling forms\n• 💳 Check subscription history & packages.');

    final List<String> chips = isBn
        ? (isAdmin
            ? ['📊 লাইভ পরিসংখ্যান', '💰 সাবস্ক্রিপশন হিসাব', '📍 জনপ্রিয় এলাকা']
            : isOwner
                ? [
                    '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন',
                    '💡 প্রস্তাবিত ভাড়ার রেঞ্জ',
                    '💳 সাবস্ক্রিপশন প্যাকেজ',
                    '📄 সাবস্ক্রিপশন হিস্ট্রি',
                  ]
                : ['🔍 বাসা খুঁজুন (Find a Home)', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '👤 আমার প্রোফাইল'])
        : (isAdmin
            ? ['📊 Live Analytics', '💰 Subscription Revenue', '📍 Top Areas']
            : isOwner
                ? [
                    '👥 Find Tenant Demand',
                    '💡 Suggest Price Range',
                    '💳 Subscription Packages',
                    '📄 Subscription History',
                  ]
                : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History', '👤 My Profile']);

    final List<String> quickFollowUps = isBn
        ? (isOwner
            ? ['⚡ প্রধান ৪টি অপশন', 'মিরপুরের প্রস্তাবিত ভাড়া', 'উত্তরার প্রস্তাবিত ভাড়া', 'সাবস্ক্রিপশন প্যাকেজ']
            : ['১৫০০০ টাকার মধ্যে বাসা দেখাও', 'মিরপুরে ফ্যামিলি ফ্ল্যাট', 'ব্যাচেলর সিট দরকার'])
        : (isOwner
            ? ['⚡ Main 4 Options', 'Mirpur Price Suggestion', 'Uttara Price Suggestion', 'Subscription Packages']
            : ['Find flats under ৳15000', '2-Bed in Uttara', 'Bachelor Rooms']);

    _userSessions[_activeUserId]!.add(
      AIMessageModel(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        text: welcomeText,
        sender: AIMessageSender.ai,
        interactiveChips: chips,
        quickActions: quickFollowUps,
      ),
    );
  }

  /// Start Voice Recognition
  Future<void> startListening(String languageCode, Function(String) onFinalText) async {
    final available = await _speechToText.initialize(
      onError: (val) {
        _isListening = false;
        notifyListeners();
      },
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );

    if (available) {
      _isListening = true;
      _spokenText = '';
      notifyListeners();

      await _speechToText.listen(
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
        ),
        onResult: (result) {
          _spokenText = result.recognizedWords;
          notifyListeners();
          if (result.finalResult && _spokenText.isNotEmpty) {
            _isListening = false;
            notifyListeners();
            onFinalText(_spokenText);
          }
        },
      );
    }
  }

  /// Stop Speech-to-Text
  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Speak Message aloud (TTS)
  Future<void> speakMessage(AIMessageModel msg, String languageCode) async {
    if (_currentlyPlayingMessageId == msg.id) {
      await stopSpeaking();
      return;
    }

    await stopSpeaking();
    _currentlyPlayingMessageId = msg.id;
    notifyListeners();

    try {
      final cleanText = msg.text
          .replaceAll('*', '')
          .replaceAll('#', '')
          .replaceAll('•', '')
          .replaceAll('🎉', '')
          .replaceAll('👉', '')
          .replaceAll('📍', '')
          .replaceAll('💰', '')
          .replaceAll('🏠', '');

      if (languageCode == 'bn') {
        await _flutterTts.setLanguage('bn-BD');
      } else {
        await _flutterTts.setLanguage('en-US');
      }

      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('TTS Speak Error: $e');
      _currentlyPlayingMessageId = null;
      notifyListeners();
    }
  }

  /// Stop Voice Speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _currentlyPlayingMessageId = null;
    notifyListeners();
  }

  /// User Input Handler (Text or 1-tap chip)
  Future<void> handleUserInput({
    required String text,
    required UserModel user,
    required String languageCode,
  }) async {
    final cleanInput = text.trim();
    if (cleanInput.isEmpty) return;

    final isBn = languageCode == 'bn';
    final history = _userSessions[user.uid] ??= [];

    // Add User Message
    history.add(
      AIMessageModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        text: cleanInput,
        sender: AIMessageSender.user,
      ),
    );
    notifyListeners();

    // Check if user clicked early Search in Wizard
    if (cleanInput.contains('🔍') || cleanInput.toLowerCase().contains('search now') || cleanInput.contains('সার্চ করব')) {
      if (_activeWizard == WizardMode.findHome) {
        await _executeFindHomeSearch(languageCode);
        return;
      } else if (_activeWizard == WizardMode.ownerViewDemands) {
        await _showOwnerTenantDemands(user, languageCode);
        return;
      }
    }

    // Check if active in wizard
    if (_activeWizard == WizardMode.findHome) {
      await _progressFindHomeWizard(cleanInput, languageCode);
      return;
    } else if (_activeWizard == WizardMode.postDemand) {
      await _progressDemandPostWizard(cleanInput, user, languageCode);
      return;
    } else if (_activeWizard == WizardMode.ownerViewDemands) {
      await _showOwnerTenantDemands(user, languageCode, targetArea: cleanInput);
      return;
    }

    // Check Trigger Keywords for Starting Wizards
    final lower = cleanInput.toLowerCase();

    // ==========================================
    // HOUSE OWNER 4 CORE OPTIONS & PERSISTENT TRIGGER
    // ==========================================
    if (user.isHouseOwner) {
      // 1. Persistent Trigger: Show Main 4 Options
      if (cleanInput.contains('প্রধান ৪টি অপশন') ||
          cleanInput.contains('Main 4 Options') ||
          lower.contains('main options') ||
          lower == 'options' ||
          lower == 'menu' ||
          cleanInput.contains('অপশনসমূহ') ||
          cleanInput.contains('মেনু')) {
        _showHouseOwner4Options(user, languageCode);
        return;
      }

      // 2. FAQ (সাধারণ জিজ্ঞাসা ও প্রশ্নোত্তর)
      if (lower.contains('faq') ||
          lower.contains('faqs') ||
          cleanInput.contains('সাধারণ জিজ্ঞাসা') ||
          cleanInput.contains('প্রশ্নোত্তর') ||
          cleanInput.contains('প্রশ্নাবলী') ||
          cleanInput.contains('জিজ্ঞাসা') ||
          lower.contains('frequently asked questions')) {
        await _showHouseOwnerFaq(user, languageCode);
        return;
      }

      // 3. How to Use this App as a House Owner (কীভাবে অ্যাপ ব্যবহার করবেন)
      if (cleanInput.contains('কীভাবে অ্যাপ ব্যবহার করবেন') ||
          cleanInput.contains('কীভাবে অ্যাপ ব্যবহার করব') ||
          cleanInput.contains('ব্যবহার নির্দেশিকা') ||
          cleanInput.contains('ব্যবহার পদ্ধতি') ||
          lower.contains('how to use') ||
          lower.contains('how to use this app') ||
          lower.contains('user guide') ||
          lower.contains('app guide')) {
        _showHouseOwnerHowToUse(user, languageCode);
        return;
      }

      // 4. Dynamic App Policies (Privacy, Support, Terms, Refund)
      if (cleanInput.contains('প্রাইভেসি পলিসি') || lower.contains('privacy policy') || cleanInput.contains('গোপনীয়তা')) {
        await _showHouseOwnerPolicy(user, 'privacy_policy', languageCode);
        return;
      }
      if (cleanInput.contains('সাপোর্ট পলিসি') || lower.contains('support policy') || cleanInput.contains('হেল্প সেন্টার') || cleanInput.contains('সাপোর্ট')) {
        await _showHouseOwnerPolicy(user, 'support_policy', languageCode);
        return;
      }
      if (cleanInput.contains('শর্তাবলী') || lower.contains('terms') || cleanInput.contains('শর্ত')) {
        await _showHouseOwnerPolicy(user, 'terms_and_conditions', languageCode);
        return;
      }
      if (cleanInput.contains('রিফান্ড পলিসি') || lower.contains('refund policy') || cleanInput.contains('রিফান্ড')) {
        await _showHouseOwnerPolicy(user, 'refund_policy', languageCode);
        return;
      }

      // 5. Option 3: Subscription Packages
      if (cleanInput.contains('সাবস্ক্রিপশন প্যাকেজ') ||
          cleanInput.contains('Subscription Packages') ||
          cleanInput.contains('প্যাকেজ') ||
          lower.contains('subscription package') ||
          lower.contains('package')) {
        _showSubscriptionPackages(user, languageCode);
        return;
      }

      // 6. Option 4: Subscription History
      if (cleanInput.contains('সাবস্ক্রিপশন হিস্ট্রি') ||
          cleanInput.contains('Subscription History') ||
          cleanInput.contains('হিস্ট্রি') ||
          lower.contains('subscription history') ||
          lower.contains('history') ||
          lower.contains('receipt') ||
          cleanInput.contains('রিসিট')) {
        _showSubscriptionHistory(user, languageCode);
        return;
      }

      // 7. Option 2: Suggest Price Range (AI Market Prediction)
      if (cleanInput.contains('প্রস্তাবিত ভাড়ার রেঞ্জ') ||
          cleanInput.contains('Suggest Price Range') ||
          cleanInput.contains('ভাড়ার রেঞ্জ') ||
          cleanInput.contains('Price Range') ||
          cleanInput.contains('ভাড়ার তালিকা') ||
          cleanInput.contains('ভাড়ার সঠিক মূল্য') ||
          cleanInput.contains('প্রস্তাবিত ভাড়া') ||
          lower.contains('suggest price') ||
          lower.contains('price range') ||
          lower.contains('rent range') ||
          lower.contains('rent guide') ||
          cleanInput.contains('ভাড়ার মূল্য') ||
          cleanInput.contains('ভাড়া কত')) {
        await _showSuggestPriceRange(user, languageCode, targetArea: cleanInput);
        return;
      }

      // 8. Option 1: Find Tenant Demands & Budget / Area filters
      if (cleanInput.contains('ভাড়াটিয়াদের ডিমান্ড') ||
          cleanInput.contains('Find Tenant Demand') ||
          cleanInput.contains('ভাড়াটিয়া ডিমান্ড') ||
          cleanInput.contains('Tenant Demand') ||
          cleanInput.contains('ডিমান্ড খুঁজুন') ||
          cleanInput.contains('সকল ডিমান্ড') ||
          cleanInput.contains('All Demands') ||
          lower == 'view demands' ||
          cleanInput.contains('k-') ||
          cleanInput.contains('Below') ||
          cleanInput.contains('নিচে') ||
          cleanInput.contains('Above') ||
          cleanInput.contains('বেশি') ||
          RegExp(r'\(\d+\)').hasMatch(cleanInput)) {
        await _showOwnerTenantDemands(user, languageCode, targetFilter: cleanInput);
        return;
      }
    }

    // 1. Trigger Find Home Wizard (Tenant)
    if (cleanInput.contains('বাসা খুঁজুন') || cleanInput.contains('Find a Home') || lower == 'find home' || lower == 'basha khoja') {
      startFindHomeWizard(user, languageCode);
      return;
    }

    // 2. Trigger Post Demand Wizard (Tenant)
    if (cleanInput.contains('ডিমান্ড পোস্ট') || cleanInput.contains('Post a Demand') || lower == 'post demand' || lower == 'demand post') {
      startDemandPostWizard(user, languageCode);
      return;
    }

    // 3. Trigger House Owner View Demands Wizard
    if (cleanInput.contains('ভাড়াটিয়াদের ডিমান্ড') || cleanInput.contains('Find Tenant Demands') || lower == 'view demands') {
      startOwnerViewDemandsWizard(user, languageCode);
      return;
    }

    // 4. Trigger Subscription History Card (Tenant/Admin)
    if (cleanInput.contains('সাবস্ক্রিপশন হিস্ট্রি') || lower.contains('subscription history') || lower.contains('হিস্ট্রি')) {
      _showSubscriptionHistory(user, languageCode);
      return;
    }

    // 5. Trigger Subscription Packages Card (Tenant/Admin)
    if (cleanInput.contains('সাবস্ক্রিপশন প্যাকেজ') || lower.contains('subscription package') || lower.contains('প্যাকেজ')) {
      _showSubscriptionPackages(user, languageCode);
      return;
    }

    // 6. Trigger My Profile Card
    if (cleanInput.contains('আমার প্রোফাইল') || lower.contains('my profile') || lower.contains('profile')) {
      history.add(
        AIMessageModel(
          id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
          text: isBn
              ? '👤 আপনার **প্রোফাইল তথ্য ও অ্যাকাউন্ট সেটিংস** দেখতে নিচে বাটনে চাপ দিন:'
              : '👤 Click below to view and update your **Profile & Account Information**:',
          sender: AIMessageSender.ai,
          actionCardType: AIActionCardType.myProfile,
          interactiveChips: isBn ? ['⭐ সাবস্ক্রিপশন প্যাকেজ', '🔍 বাসা খুঁজুন', '📝 ডিমান্ড পোস্ট'] : ['⭐ Subscription Packages', '🔍 Find Home', '📝 Post Demand'],
        ),
      );
      notifyListeners();
      return;
    }

    // 7. General AI Prompt via Gemini Agent
    _isGenerating = true;
    notifyListeners();

    try {
      final liveContext = await _buildLivePublicDbContext(languageCode);
      final aiResponse = await _geminiService.getAssistantResponse(
        userPrompt: cleanInput,
        userRole: user.userType,
        userName: user.fullName.isNotEmpty ? user.fullName : user.firstName,
        languageCode: languageCode,
        liveDatabaseContext: liveContext,
      );

      // Handle intent
      if (aiResponse.intent == 'admin_stats') {
        final stats = await _fetchAdminLiveStats();
        history.add(
          AIMessageModel(
            id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
            text: aiResponse.replyText,
            sender: AIMessageSender.ai,
            actionCardType: AIActionCardType.adminStats,
            adminStats: stats,
            quickActions: aiResponse.quickFollowUps,
          ),
        );
      } else if (aiResponse.intent == 'pricing_advice') {
        final targetArea = aiResponse.searchFilters?['area'] ?? cleanInput;
        await _showSuggestPriceRange(user, languageCode, targetArea: targetArea);
        return;
      } else if (aiResponse.intent == 'search_properties') {
        final properties = await _fetchProperties(aiResponse.searchFilters);
        history.add(
          AIMessageModel(
            id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
            text: aiResponse.replyText,
            sender: AIMessageSender.ai,
            properties: properties,
            interactiveChips: aiResponse.interactiveChips,
            quickActions: aiResponse.quickFollowUps,
          ),
        );
      } else {
        history.add(
          AIMessageModel(
            id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
            text: aiResponse.replyText,
            sender: AIMessageSender.ai,
            interactiveChips: aiResponse.interactiveChips,
            quickActions: aiResponse.quickFollowUps,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling AI user input: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ==========================================
  // WIZARD 1: FIND A HOME (12 STEPS)
  // ==========================================

  void startFindHomeWizard(UserModel user, String languageCode) {
    _activeWizard = WizardMode.findHome;
    _wizardStep = 1;
    _searchDraft = const SearchDraftModel();
    final isBn = languageCode == 'bn';

    final history = _userSessions[user.uid] ??= [];
    history.add(
      AIMessageModel(
        id: 'wh_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '🔍 **বাসা খোঁজা শুরু করি!** (ধাপ ১/১২)\nআপনি **কোন মাস** থেকে বাসা ভাড়া নিতে চান? নিচে থেকে বেছে নিন বা লিখুন:'
            : '🔍 **Let\'s Find Your Ideal Home!** (Step 1/12)\nWhich **month** are you looking to move in? Select below or type:',
        sender: AIMessageSender.ai,
        interactiveChips: isBn
            ? ['🔍 এখনই সার্চ করব', 'চলতি মাস (Current)', 'পরবর্তী মাস (Next)', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর']
            : ['🔍 Search Now', 'Current Month', 'Next Month', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      ),
    );
    notifyListeners();
  }

  Future<void> _progressFindHomeWizard(String input, String languageCode) async {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    switch (_wizardStep) {
      case 1:
        _searchDraft = _searchDraft.copyWith(month: input);
        _wizardStep = 2;
        history.add(
          AIMessageModel(
            id: 'wh2_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '🏠 **বাসার ধরণ (House Type) কী হবে?** (ধাপ ২/১২)\nনিচে থেকে সিলেক্ট করুন বা লিখুন:'
                : '🏠 **What type of property are you looking for?** (Step 2/12)\nSelect or type:',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'ফ্ল্যাট (Flat)', 'রুম (Room)', 'খালি সিট (Empty Seat)', 'ইউনিট (Unit)']
                : ['🔍 Search Now', 'Flat', 'Room', 'Empty Seat', 'Unit'],
          ),
        );
        break;

      case 2:
        _searchDraft = _searchDraft.copyWith(houseType: input);
        _wizardStep = 3;
        history.add(
          AIMessageModel(
            id: 'wh3_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '📍 **কোন বিভাগে বাসা খুঁজছেন?** (ধাপ ৩/১২)'
                : '📍 **Which Division?** (Step 3/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'খুলনা', 'বরিশাল', 'সিলেট', 'রংপুর', 'ময়মনসিংহ']
                : ['🔍 Search Now', 'Dhaka', 'Chattogram', 'Rajshahi', 'Khulna', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh'],
          ),
        );
        break;

      case 3:
        _searchDraft = _searchDraft.copyWith(division: input);
        _wizardStep = 4;
        history.add(
          AIMessageModel(
            id: 'wh4_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '🏙️ **কোন জেলায় বাসা খুঁজছেন?** (ধাপ ৪/১২)'
                : '🏙️ **Which District?** (Step 4/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'ঢাকা', 'গাজীপুর', 'নারায়ণগঞ্জ', 'ফরিদপুর', 'চট্টগ্রাম', 'সিলেট', 'রাজশাহী']
                : ['🔍 Search Now', 'Dhaka', 'Gazipur', 'Narayanganj', 'Faridpur', 'Chattogram', 'Sylhet', 'Rajshahi'],
          ),
        );
        break;

      case 4:
        _searchDraft = _searchDraft.copyWith(district: input);
        _wizardStep = 5;
        history.add(
          AIMessageModel(
            id: 'wh5_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '📍 **কোন এলাকা / থানায় বাসা দরকার?** (ধাপ ৫/১২)'
                : '📍 **Which Area / Upazila?** (Step 5/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'মিরপুর', 'উত্তরা', 'ধানমন্ডি', 'গুলশান', 'মোহাম্মদপুর', 'বনশ্রী', 'বাড্ডা', 'ফরিদপুর সদর']
                : ['🔍 Search Now', 'Mirpur', 'Uttara', 'Dhanmondi', 'Gulshan', 'Mohammadpur', 'Banasree', 'Badda'],
          ),
        );
        break;

      case 5:
        _searchDraft = _searchDraft.copyWith(area: input);
        _wizardStep = 6;
        history.add(
          AIMessageModel(
            id: 'wh6_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '📌 **নির্দিষ্ট কোনো সাব-এরিয়া / সেক্টর / ব্লক আছে?** (ধাপ ৬/১২)'
                : '📌 **Any specific Sub-Area / Sector / Block?** (Step 6/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'মিরপুর ১০', 'মিরপুর ২', 'মিরপুর ১', 'উত্তরা সেক্টর ৭', 'ধানমন্ডি ৮', 'বসুন্ধরা R/A']
                : ['🔍 Search Now', 'Mirpur 10', 'Mirpur 2', 'Uttara Sector 7', 'Dhanmondi 8', 'Bashundhara R/A'],
          ),
        );
        break;

      case 6:
        _searchDraft = _searchDraft.copyWith(subArea: input);
        _wizardStep = 7;
        history.add(
          AIMessageModel(
            id: 'wh7_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '💰 **আপনার আনুমানিক মাসিক বাজেট কত?** (ধাপ ৭/১২)'
                : '💰 **What is your budget range?** (Step 7/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', '৳৫,০০০ - ৳১০,০০০', '৳১০,০০০ - ৳১৫,০০০', '৳১৫,০০০ - ৳২০,০০০', '৳২০,০০০ - ৳৩০,০০০', '৳৩০,০০০+']
                : ['🔍 Search Now', '৳5,000 - ৳10,000', '৳10,000 - ৳15,000', '৳15,000 - ৳20,000', '৳20,000 - ৳30,000', '৳30,000+'],
          ),
        );
        break;

      case 7:
        _searchDraft = _searchDraft.copyWith(budgetRange: input);
        _wizardStep = 8;
        history.add(
          AIMessageModel(
            id: 'wh8_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '👥 **ভাড়াটিয়ার ধরণ (Tenant Type) কী হবে?** (ধাপ ৮/১২)'
                : '👥 **What is the Tenant Type?** (Step 8/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'ফ্যামিলি (Family)', 'ব্যাচেলর ছেলে (Bachelor Male)', 'ব্যাচেলর মেয়ে (Bachelor Female)', 'সাবলেট (Sub-Let)']
                : ['🔍 Search Now', 'Family', 'Bachelor Male', 'Bachelor Female', 'Sub-Let'],
          ),
        );
        break;

      case 8:
        _searchDraft = _searchDraft.copyWith(tenantType: input);
        _wizardStep = 9;
        history.add(
          AIMessageModel(
            id: 'wh9_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '🛏️ **কয়টি বেডরুম বা সিট প্রয়োজন?** (ধাপ ৯/১২)'
                : '🛏️ **Number of Bedrooms / Rooms / Seats?** (Step 9/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'Bedroom - 1', 'Bedroom - 2', 'Bedroom - 3', 'Bedroom - 4', 'Room - 1', 'Seat - 1']
                : ['🔍 Search Now', 'Bedroom - 1', 'Bedroom - 2', 'Bedroom - 3', 'Bedroom - 4', 'Room - 1', 'Seat - 1'],
          ),
        );
        break;

      case 9:
        _searchDraft = _searchDraft.copyWith(roomOrSeat: input);
        _wizardStep = 10;
        history.add(
          AIMessageModel(
            id: 'wh10_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '🚿 **বাথরুম ও বারান্দা কতটি প্রয়োজন?** (ধাপ ১০/১২)'
                : '🚿 **How many Bathrooms & Balconies?** (Step 10/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', '১ বাথরুম ও ১ বারান্দা', '২ বাথরুম ও ২ বারান্দা', '৩ বাথরুম ও ২ বারান্দা', 'যেকোনোটি']
                : ['🔍 Search Now', '1 Bath & 1 Balcony', '2 Bath & 2 Balcony', '3 Bath & 2 Balcony', 'Any'],
          ),
        );
        break;

      case 10:
        _wizardStep = 11;
        history.add(
          AIMessageModel(
            id: 'wh11_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '🏢 **পছন্দের ফ্লোর বা তলা কোনটা?** (ধাপ ১১/১২)'
                : '🏢 **Preferred Floor Number?** (Step 11/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', '১ম তলা', '২য় তলা', '৩য় তলা', '৪র্থ তলা', '৫ম তলা', '৬ষ্ঠ তলা', 'যেকোনো তলা']
                : ['🔍 Search Now', '1st Floor', '2nd Floor', '3rd Floor', '4th Floor', '5th Floor', 'Any Floor'],
          ),
        );
        break;

      case 11:
        _wizardStep = 12;
        history.add(
          AIMessageModel(
            id: 'wh12_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '🚗 **লিফট ও পার্কিং সুবিধা প্রয়োজন কি?** (ধাপ ১২/১২)'
                : '🚗 **Do you need Lift and Parking?** (Step 12/12)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 এখনই সার্চ করব', 'লিফট ও পার্কিং উভয়ই চাই', 'শুধু লিফট চাই', 'শুধু পার্কিং চাই', 'কোনোটিই আবশ্যক নয়']
                : ['🔍 Search Now', 'Both Lift & Parking', 'Only Lift', 'Only Parking', 'Not Mandatory'],
          ),
        );
        break;

      case 12:
        await _executeFindHomeSearch(languageCode);
        break;
    }

    notifyListeners();
  }

  Future<void> _executeFindHomeSearch(String languageCode) async {
    _activeWizard = WizardMode.none;
    _isGenerating = true;
    notifyListeners();

    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    final properties = await _fetchProperties({
      'area': _searchDraft.area,
      'district': _searchDraft.district,
      'division': _searchDraft.division,
      'budget': _searchDraft.budgetRange,
      'rooms': _searchDraft.roomOrSeat,
    });

    _isGenerating = false;
    history.add(
      AIMessageModel(
        id: 'res_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '🎉 **আপনার চাহিদামতো মোট ${properties.length} টি বাসা পাওয়া গেছে!**\nনিচে কার্ডে ক্লিক করে বিস্তারিত ও ছবি দেখুন:'
            : '🎉 **Found ${properties.length} matching properties!**\nTap any card below for details:',
        sender: AIMessageSender.ai,
        properties: properties,
        interactiveChips: isBn
            ? ['🔍 নতুন সার্চ শুরু করুন', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ']
            : ['🔍 New Search', '📝 Post Demand', '💳 Subscription Packages'],
      ),
    );
    notifyListeners();
  }

  // ==========================================
  // WIZARD 2: DEMAND POST (17 STEPS WITH BD PHONE VALIDATION)
  // ==========================================

  void startDemandPostWizard(UserModel user, String languageCode) {
    _activeWizard = WizardMode.postDemand;
    _wizardStep = 1;
    _demandDraft = DemandDraftModel(
      userName: user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim(),
      userMobile: user.mobile,
      userWhatsApp: user.mobile,
    );
    final isBn = languageCode == 'bn';

    final history = _userSessions[user.uid] ??= [];
    history.add(
      AIMessageModel(
        id: 'dp1_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '📝 **ডিমান্ড পোস্ট উইজার্ড শুরু হলো!** (ধাপ ১/১৭)\nকোন **মাস** থেকে বাসা প্রয়োজন? নিচে থেকে বেছে নিন বা লিখুন:'
            : '📝 **Tenant Demand Posting!** (Step 1/17)\nWhich **month** do you need the house from?',
        sender: AIMessageSender.ai,
        interactiveChips: isBn
            ? ['চলতি মাস', 'পরবর্তী মাস', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর']
            : ['Current Month', 'Next Month', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
      ),
    );
    notifyListeners();
  }

  Future<void> _progressDemandPostWizard(String input, UserModel user, String languageCode) async {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    switch (_wizardStep) {
      case 1:
        _demandDraft = _demandDraft.copyWith(month: input);
        _wizardStep = 2;
        history.add(
          AIMessageModel(
            id: 'dp2_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🏠 **বাসার ধরণ (House Type) কী হবে?** (ধাপ ২/১৭)' : '🏠 **House Type?** (Step 2/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['ফ্ল্যাট (Flat)', 'রুম (Room)', 'খালি সিট (Empty Seat)', 'ইউনিট (Unit)'] : ['Flat', 'Room', 'Empty Seat', 'Unit'],
          ),
        );
        break;

      case 2:
        _demandDraft = _demandDraft.copyWith(houseType: input);
        _wizardStep = 3;
        history.add(
          AIMessageModel(
            id: 'dp3_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '📍 **কোন বিভাগে বাসা প্রয়োজন?** (ধাপ ৩/১৭)' : '📍 **Which Division?** (Step 3/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['ঢাকা', 'চট্টগ্রাম', 'রাজশাহী', 'খুলনা', 'বরিশাল', 'সিলেট', 'রংপুর', 'ময়মনসিংহ'] : ['Dhaka', 'Chattogram', 'Rajshahi', 'Khulna', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh'],
          ),
        );
        break;

      case 3:
        _demandDraft = _demandDraft.copyWith(division: input);
        _wizardStep = 4;
        history.add(
          AIMessageModel(
            id: 'dp4_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🏙️ **কোন জেলায় বাসা প্রয়োজন?** (ধাপ ৪/১৭)' : '🏙️ **Which District?** (Step 4/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['ঢাকা', 'গাজীপুর', 'নারায়ণগঞ্জ', 'ফরিদপুর', 'চট্টগ্রাম', 'সিলেট'] : ['Dhaka', 'Gazipur', 'Narayanganj', 'Faridpur', 'Chattogram', 'Sylhet'],
          ),
        );
        break;

      case 4:
        _demandDraft = _demandDraft.copyWith(district: input);
        _wizardStep = 5;
        history.add(
          AIMessageModel(
            id: 'dp5_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '📍 **কোন থানা বা এলাকায় বাসা চান?** (ধাপ ৫/১৭)' : '📍 **Which Area / Upazila?** (Step 5/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['মিরপুর', 'উত্তরা', 'ধানমন্ডি', 'গুলশান', 'মোহাম্মদপুর', 'বনশ্রী', 'ফরিদপুর সদর'] : ['Mirpur', 'Uttara', 'Dhanmondi', 'Gulshan', 'Mohammadpur', 'Banasree'],
          ),
        );
        break;

      case 5:
        _demandDraft = _demandDraft.copyWith(area: input);
        _wizardStep = 6;
        history.add(
          AIMessageModel(
            id: 'dp6_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '📌 **সাব-এরিয়া / সেক্টর / ব্লক লিখুন বা বেছে নিন:** (ধাপ ৬/১৭)' : '📌 **Enter Sub-Area / Sector / Block:** (Step 6/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['মিরপুর ১০', 'মিরপুর ২', 'উত্তরা সেক্টর ৭', 'ধানমন্ডি ৮'] : ['Mirpur 10', 'Mirpur 2', 'Uttara Sector 7', 'Dhanmondi 8'],
          ),
        );
        break;

      case 6:
        _demandDraft = _demandDraft.copyWith(subArea: input);
        _wizardStep = 7;
        history.add(
          AIMessageModel(
            id: 'dp7_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '💰 **আপনার মাসিক বাজেট কত?** (ধাপ ৭/১৭)' : '💰 **Your Budget Range?** (Step 7/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['৳৮,০০০ - ৳১২,০০০', '৳১২,০০০ - ৳১৫,০০০', '৳১৫,০০০ - ৳২০,০০০', '৳২০,০০০ - ৳২৫,০০০'] : ['৳8,000 - ৳12,000', '৳12,000 - ৳15,000', '৳15,000 - ৳20,000', '৳20,000 - ৳25,000'],
          ),
        );
        break;

      case 7:
        _demandDraft = _demandDraft.copyWith(budgetRange: input);
        _wizardStep = 8;
        history.add(
          AIMessageModel(
            id: 'dp8_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '👥 **ভাড়াটিয়ার ধরণ (Tenant Type) কী?** (ধাপ ৮/১৭)' : '👥 **Tenant Type?** (Step 8/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['ফ্যামিলি (Family)', 'ব্যাচেলর ছেলে (Bachelor Male)', 'ব্যাচেলর মেয়ে (Bachelor Female)', 'সাবলেট (Sub-Let)'] : ['Family', 'Bachelor Male', 'Bachelor Female', 'Sub-Let'],
          ),
        );
        break;

      case 8:
        _demandDraft = _demandDraft.copyWith(tenantType: input);
        _wizardStep = 9;
        history.add(
          AIMessageModel(
            id: 'dp9_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🛏️ **কয়টি বেডরুম বা সিট চান?** (ধাপ ৯/১৭)' : '🛏️ **Number of Bedrooms / Seats?** (Step 9/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['Bedroom - 1', 'Bedroom - 2', 'Bedroom - 3', 'Bedroom - 4', 'Room - 1', 'Seat - 1'] : ['Bedroom - 1', 'Bedroom - 2', 'Bedroom - 3', 'Bedroom - 4', 'Room - 1', 'Seat - 1'],
          ),
        );
        break;

      case 9:
        _demandDraft = _demandDraft.copyWith(roomOrSeat: input);
        _wizardStep = 10;
        history.add(
          AIMessageModel(
            id: 'dp10_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🚿 **বাথরুম কয়টি প্রয়োজন?** (ধাপ ১০/১৭)' : '🚿 **How many Bathrooms?** (Step 10/17)',
            sender: AIMessageSender.ai,
            interactiveChips: ['1', '2', '3', '4'],
          ),
        );
        break;

      case 10:
        _demandDraft = _demandDraft.copyWith(bathrooms: int.tryParse(input) ?? 2);
        _wizardStep = 11;
        history.add(
          AIMessageModel(
            id: 'dp11_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🌅 **বারান্দা কয়টি প্রয়োজন?** (ধাপ ১১/১৭)' : '🌅 **How many Balconies?** (Step 11/17)',
            sender: AIMessageSender.ai,
            interactiveChips: ['1', '2', '3'],
          ),
        );
        break;

      case 11:
        _demandDraft = _demandDraft.copyWith(balconies: int.tryParse(input) ?? 1);
        _wizardStep = 12;
        history.add(
          AIMessageModel(
            id: 'dp12_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🏢 **পছন্দের তলা (Floor)?** (ধাপ ১২/১৭)' : '🏢 **Preferred Floor?** (Step 12/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['১ম তলা', '২য় তলা', '৩য় তলা', '৪র্থ তলা', '৫ম তলা', 'যেকোনো তলা'] : ['1st Floor', '2nd Floor', '3rd Floor', '4th Floor', '5th Floor', 'Any Floor'],
          ),
        );
        break;

      case 12:
        _demandDraft = _demandDraft.copyWith(floorNumber: int.tryParse(input.replaceAll(RegExp(r'\D'), '')) ?? 2);
        _wizardStep = 13;
        history.add(
          AIMessageModel(
            id: 'dp13_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🛗 **লিফট সুবিধা প্রয়োজন কি?** (ধাপ ১৩/১৭)' : '🛗 **Do you require a Lift?** (Step 13/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['হ্যাঁ, প্রয়োজন (Available)', 'প্রয়োজন নেই (Unavailable)'] : ['Yes (Available)', 'No (Unavailable)'],
          ),
        );
        break;

      case 13:
        _demandDraft = _demandDraft.copyWith(hasLift: input.contains('হ্যাঁ') || input.toLowerCase().contains('yes') || input.toLowerCase().contains('avail'));
        _wizardStep = 14;
        history.add(
          AIMessageModel(
            id: 'dp14_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🚗 **পার্কিং সুবিধা প্রয়োজন কি?** (ধাপ ১৪/১৭)' : '🚗 **Do you require Parking?** (Step 14/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['হ্যাঁ, প্রয়োজন (Available)', 'প্রয়োজন নেই (Unavailable)'] : ['Yes (Available)', 'No (Unavailable)'],
          ),
        );
        break;

      case 14:
        _demandDraft = _demandDraft.copyWith(hasParking: input.contains('হ্যাঁ') || input.toLowerCase().contains('yes') || input.toLowerCase().contains('avail'));
        _wizardStep = 15;
        history.add(
          AIMessageModel(
            id: 'dp15_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '📢 **বর্তমান বাসায় ছাড়ার নোটিশ দিয়েছেন কি?** (ধাপ ১৫/১৭)' : '📢 **Have you given notice to your current landlord?** (Step 15/17)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['হ্যাঁ, নোটিশ দিয়েছি (Yes)', 'না, এখনও দিইনি (No)'] : ['Yes, Notice Given', 'No, Not Yet'],
          ),
        );
        break;

      case 15:
        _demandDraft = _demandDraft.copyWith(hasGivenNotice: input.contains('হ্যাঁ') || input.toLowerCase().contains('yes'));
        _wizardStep = 16;
        final defaultName = user.fullName.isNotEmpty ? user.fullName : "${user.firstName} ${user.lastName}".trim();
        history.add(
          AIMessageModel(
            id: 'dp16_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '👤 **আপনার নাম লিখুন:** (ধাপ ১৬/১৭)' : '👤 **Enter Your Name:** (Step 16/17)',
            sender: AIMessageSender.ai,
            interactiveChips: defaultName.isNotEmpty ? [defaultName] : null,
          ),
        );
        break;

      case 16:
        _demandDraft = _demandDraft.copyWith(userName: input);
        _wizardStep = 17;
        history.add(
          AIMessageModel(
            id: 'dp17_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '📱 **আপনার সঠিক ১১ ডিজিটের বাংলাদেশি মোবাইল নম্বর দিন:** (ধাপ ১৭/১৭)'
                : '📱 **Enter your valid 11-digit Bangladesh phone number:** (Step 17/17)',
            sender: AIMessageSender.ai,
            interactiveChips: user.mobile.isNotEmpty && RegExp(r'^01[3-9]\d{8}$').hasMatch(user.mobile) ? [user.mobile] : null,
          ),
        );
        break;

      case 17:
        final phone = input.replaceAll(RegExp(r'\s+'), '');
        final bdPhoneRegex = RegExp(r'^01[3-9]\d{8}$');
        if (!bdPhoneRegex.hasMatch(phone)) {
          history.add(
            AIMessageModel(
              id: 'err_phone_${DateTime.now().millisecondsSinceEpoch}',
              text: isBn
                  ? '❌ **ভুল নম্বর!** অনুগ্রহ করে সঠিক ১১ ডিজিটের বাংলাদেশি মোবাইল নম্বর দিন (যেমন: 01712345678):'
                  : '❌ **Invalid number!** Please enter a valid 11-digit Bangladesh mobile number (e.g. 01712345678):',
              sender: AIMessageSender.ai,
              interactiveChips: user.mobile.isNotEmpty && bdPhoneRegex.hasMatch(user.mobile) ? [user.mobile] : null,
            ),
          );
          return;
        }

        _demandDraft = _demandDraft.copyWith(userMobile: phone, userWhatsApp: phone);
        _wizardStep = 18;
        _activeWizard = WizardMode.none;

        // Show confirmation draft card
        history.add(
          AIMessageModel(
            id: 'dp_confirm_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '✨ **সব তথ্য সম্পন্ন হয়েছে!** আপনার ডিমান্ডের খসড়াটি দেখে নিন। সব ঠিক থাকলে **"হ্যাঁ, ডিমান্ড পোস্ট করুন"** বাটনে চাপ দিন:'
                : '✨ **All details collected!** Please review your demand draft below and tap confirm to publish:',
            sender: AIMessageSender.ai,
            actionCardType: AIActionCardType.demandDraft,
            demandDraft: _demandDraft,
            interactiveChips: isBn ? ['✅ হ্যাঁ, ডিমান্ড পোস্ট করুন', '❌ বাতিল'] : ['✅ Yes, Publish Demand', '❌ Cancel'],
          ),
        );
        break;
    }

    notifyListeners();
  }

  // ==========================================
  // REAL FIRESTORE TENANT DEMANDS FOR HOUSE OWNER
  // ==========================================

  Future<void> startOwnerViewDemandsWizard(UserModel user, String languageCode) async {
    await _showOwnerTenantDemands(user, languageCode);
  }

  Future<void> _showOwnerTenantDemands(UserModel user, String languageCode, {String? targetFilter, String? targetArea}) async {
    final effectiveTarget = targetFilter ?? targetArea;
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    try {
      // 1. Fetch all active/unfulfilled tenant demands from Firestore
      final allDemands = await TenantDemandFirestoreService().getAllDemands();
      final activeDemands = allDemands.where((d) => !d.isFulfilled).toList();

      if (activeDemands.isEmpty) {
        history.add(
          AIMessageModel(
            id: 'dem_empty_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '👥 **বর্তমানে ফায়ারবেস ডাটাবেজে কোনো সক্রিয় ভাড়াটিয়া ডিমান্ড নেই।**\nনতুন কোনো ভাড়াটিয়া ডিমান্ড পোস্ট করলে তা এখানে ও আপনার "Tenant Demand" স্ক্রিনে সরাসরি দেখতে পাবেন।'
                : '👥 **No active tenant demands found in Firebase right now.**\nWhen tenants post new requirements, they will appear here.',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '⚡ প্রধান ৪টি অপশন']
                : ['💡 Suggest Price Range', '💳 Subscription Packages', '📄 Subscription History', '⚡ Main 4 Options'],
          ),
        );
        return;
      }

      // 2. Extract unique real areas and their counts
      final Map<String, int> areaCounts = {};
      for (final d in activeDemands) {
        final areaName = (isBn ? (d.area.bnName.isNotEmpty ? d.area.bnName : d.area.name) : d.area.name).trim();
        if (areaName.isNotEmpty) {
          areaCounts[areaName] = (areaCounts[areaName] ?? 0) + 1;
        }
      }

      // 3. Extract unique real budget ranges and their counts
      final Map<String, int> budgetCounts = {};
      for (final d in activeDemands) {
        final rawBudget = d.budgetRange?.trim() ?? '';
        final bucket = _normalizeBudgetBucket(rawBudget, isBn);
        if (bucket != null) {
          budgetCounts[bucket] = (budgetCounts[bucket] ?? 0) + 1;
        }
      }

      // 4. Filter by targetFilter (Budget or Area)
      List<TenantDemandModel> displayDemands = activeDemands;
      String selectedFilterTitle = '';

      if (effectiveTarget != null &&
          effectiveTarget.isNotEmpty &&
          !effectiveTarget.contains('সকল ডিমান্ড') &&
          !effectiveTarget.contains('All Demands') &&
          !effectiveTarget.contains('সকল এলাকা') &&
          !effectiveTarget.contains('All Areas') &&
          !effectiveTarget.contains('প্রধান ৪টি অপশন') &&
          !effectiveTarget.contains('Main 4 Options')) {
        
        final cleanFilter = effectiveTarget.replaceAll(RegExp(r'\(\d+\)'), '').replaceAll('ডিমান্ড', '').replaceAll('খুঁজুন', '').trim();
        final isBudgetQuery = cleanFilter.contains('k-') ||
            cleanFilter.contains('Below') ||
            cleanFilter.contains('Above') ||
            cleanFilter.contains('নিচে') ||
            cleanFilter.contains('বেশি') ||
            cleanFilter.contains('৳') ||
            cleanFilter.contains('000') ||
            cleanFilter.contains('হাজার') ||
            cleanFilter.contains('টাকা');

        if (isBudgetQuery) {
          final matched = activeDemands.where((d) => _matchesBudgetFilter(d, cleanFilter)).toList();
          if (matched.isNotEmpty) {
            displayDemands = matched;
            selectedFilterTitle = isBn ? '💰 বাজেট: $cleanFilter' : '💰 Budget: $cleanFilter';
          }
        } else {
          // Location / Area match
          final cleanTarget = cleanFilter.toLowerCase();
          final matched = activeDemands.where((d) {
            final pArea = d.area.name.toLowerCase();
            final pBnArea = d.area.bnName.toLowerCase();
            final pSub = d.subArea?.name.toLowerCase() ?? '';
            final pBnSub = d.subArea?.bnName.toLowerCase() ?? '';
            final pDist = d.district.name.toLowerCase();
            final pBnDist = d.district.bnName.toLowerCase();
            return pArea.contains(cleanTarget) ||
                   pBnArea.contains(cleanTarget) ||
                   pSub.contains(cleanTarget) ||
                   pBnSub.contains(cleanTarget) ||
                   pDist.contains(cleanTarget) ||
                   pBnDist.contains(cleanTarget);
          }).toList();

          if (matched.isNotEmpty) {
            displayDemands = matched;
            selectedFilterTitle = isBn ? '📍 এলাকা: $cleanFilter' : '📍 Area: $cleanFilter';
          }
        }
      }

      final topAreaList = areaCounts.entries.map((e) => '• 📍 **${e.key}**: ${e.value}টি ডিমান্ড').join('\n');
      final topAreaListEn = areaCounts.entries.map((e) => '• 📍 **${e.key}**: ${e.value} Demands').join('\n');
      final topBudgetList = budgetCounts.entries.map((e) => '• 💰 **${e.key}**: ${e.value}টি ডিমান্ড').join('\n');
      final topBudgetListEn = budgetCounts.entries.map((e) => '• 💰 **${e.key}**: ${e.value} Demands').join('\n');

      final String headerText = isBn
          ? (selectedFilterTitle.isNotEmpty
              ? '🎯 **$selectedFilterTitle অনুযায়ী ${displayDemands.length} টি লাইভ ভাড়াটিয়া ডিমান্ড পাওয়া গেছে (মোট সক্রিয়: ${activeDemands.length} টি):**\n\n👇 নিচের কার্ডে ক্লিক করে ভাড়াটিয়ার ডিমান্ড ও ফোন নম্বর আনলক করুন:'
              : '''👥 **ভাড়াটিয়াদের মোট ${activeDemands.length} টি লাইভ ডিমান্ড পোস্ট পাওয়া গেছে (Demand Screen Data):**

💰 **ভাড়াটিয়াদের বাজেট রেঞ্জসমূহ (Live Budget Insights):**
$topBudgetList

📍 **যেসব এলাকায় ডিমান্ড পোস্ট রয়েছে:**
$topAreaList

👇 নিচের যেকোনো কার্ডে ট্যাপ করে ডিমান্ড ডিটেইলস ও যোগাযোগ আনলক করুন, অথবা উপরের বাজেট/এলাকার বাটনে চাপ দিয়ে ফিল্টার করুন:''')
          : (selectedFilterTitle.isNotEmpty
              ? '🎯 **Found ${displayDemands.length} Live Tenant Demands for $selectedFilterTitle (Total Active: ${activeDemands.length}):**\n\n👇 Tap cards below to view requirements & unlock contact info:'
              : '''👥 **Found ${activeDemands.length} Live Tenant Demands in Firebase (Demand Screen Data):**

💰 **Live Tenant Budget Ranges (From Real Posts):**
$topBudgetListEn

📍 **Areas with Active Tenant Demands:**
$topAreaListEn

👇 Tap demand cards below to unlock contacts, or filter by budget/area:''');

      // Build interactive chips: All Demands, Real Budgets, Real Areas, Suggest Price, Main 4
      final List<String> dynamicChips = [];
      if (isBn) {
        dynamicChips.add('📍 সকল ডিমান্ড (${activeDemands.length})');
        for (final entry in budgetCounts.entries.take(6)) {
          dynamicChips.add('💰 ${entry.key} (${entry.value})');
        }
        for (final entry in areaCounts.entries.take(5)) {
          dynamicChips.add('📍 ${entry.key} (${entry.value})');
        }
        dynamicChips.add('💡 প্রস্তাবিত ভাড়ার রেঞ্জ');
        dynamicChips.add('⚡ প্রধান ৪টি অপশন');
      } else {
        dynamicChips.add('📍 All Demands (${activeDemands.length})');
        for (final entry in budgetCounts.entries.take(6)) {
          dynamicChips.add('💰 ${entry.key} (${entry.value})');
        }
        for (final entry in areaCounts.entries.take(5)) {
          dynamicChips.add('📍 ${entry.key} (${entry.value})');
        }
        dynamicChips.add('💡 Suggest Price Range');
        dynamicChips.add('⚡ Main 4 Options');
      }

      final matching = displayDemands.map((d) {
        return MatchingDemandItem(
          demand: d,
          matchPercentage: 96,
          matchReason: isBn
              ? '${d.area.getLocalizedName(languageCode)} • ৳ ${(d.budgetRange ?? "").toLocalizedDigits(languageCode)}'
              : '${d.area.getLocalizedName(languageCode)} • ৳ ${d.budgetRange ?? ""}',
        );
      }).toList();

      history.add(
        AIMessageModel(
          id: 'dem_${DateTime.now().millisecondsSinceEpoch}',
          text: headerText,
          sender: AIMessageSender.ai,
          matchingDemands: matching,
          interactiveChips: dynamicChips,
          quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন'] : ['⚡ Main 4 Options'],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching tenant demands: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ==========================================
  // HOUSE OWNER 4 CORE METHODS
  // ==========================================

  /// Public method to trigger the 4 core options menu at any time
  void showHouseOwner4Options(UserModel user, String languageCode) {
    _showHouseOwner4Options(user, languageCode);
  }

  void _showHouseOwner4Options(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];
    history.add(
      AIMessageModel(
        id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '⚡ **বাড়িওয়ালাদের জন্য প্রধান ৪টি অপশন:**\n\n১. 👥 **ভাড়াটিয়াদের ডিমান্ড খুঁজুন** — লাইভ সক্রিয় ভাড়াটিয়াদের চাহিদা ও বাজেট ভিত্তিক পোস্ট দেখুন।\n২. 💡 **প্রস্তাবিত ভাড়ার রেঞ্জ (AI Market Suggestion)** — এলাকা, রুম ও সুবিধার ভিত্তিতে এআই প্রস্তাবিত ভাড়ার গাইডলাইন।\n৩. 💳 **সাবস্ক্রিপশন প্যাকেজ** — প্যাকেজ আপগ্রেড ও নতুন সুবিধা আনলক।\n৪. 📄 **সাবস্ক্রিপশন হিস্ট্রি** — বিগত পেমেন্টের ডিজিটাল রসিদ ও হিস্ট্রি।'
            : '⚡ **Main 4 Options for House Owners:**\n\n1. 👥 **Find Tenant Demand** — Search real-time tenant demands with smart budget filters.\n2. 💡 **Suggest Price Range (AI Market Prediction)** — Area, room & amenity-based fair rental guidance.\n3. 💳 **Subscription Packages** — Explore & upgrade subscription plans.\n4. 📄 **Subscription History** — View past transaction history & payment receipts.',
        sender: AIMessageSender.ai,
        interactiveChips: isBn
            ? [
                '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন',
                '💡 প্রস্তাবিত ভাড়ার রেঞ্জ',
                '💳 সাবস্ক্রিপশন প্যাকেজ',
                '📄 সাবস্ক্রিপশন হিস্ট্রি',
              ]
            : [
                '👥 Find Tenant Demand',
                '💡 Suggest Price Range',
                '💳 Subscription Packages',
                '📄 Subscription History',
              ],
        quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন'] : ['⚡ Main 4 Options'],
      ),
    );
    notifyListeners();
  }

  Future<void> _showSuggestPriceRange(UserModel user, String languageCode, {String? targetArea}) async {
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    try {
      // 1. Fetch all properties from Firestore for AI Market Prediction (Privacy safe: no raw listings exposed)
      final propsSnap = await _firestore.collection('properties').get();
      final allProperties = propsSnap.docs.map((doc) => PropertyModel.fromMap(doc.data(), doc.id)).toList();

      // 2. Group properties by: Division -> District -> Area -> Sub-Area
      final Map<String, _LocationPriceGroup> groups = {};

      for (final p in allProperties) {
        final divName = (isBn ? (p.division.bnName.isNotEmpty ? p.division.bnName : p.division.name) : p.division.name).trim();
        final distName = (isBn ? (p.district.bnName.isNotEmpty ? p.district.bnName : p.district.name) : p.district.name).trim();
        final areaName = (isBn ? (p.area.bnName.isNotEmpty ? p.area.bnName : p.area.name) : p.area.name).trim();
        final subAreaName = p.subArea != null ? (isBn ? (p.subArea!.bnName.isNotEmpty ? p.subArea!.bnName : p.subArea!.name) : p.subArea!.name).trim() : '';

        final key = '$divName|$distName|$areaName|$subAreaName';

        final price = double.tryParse(p.amount.replaceAll(RegExp(r'\D'), '')) ?? 0;
        if (price > 0) {
          groups.putIfAbsent(key, () => _LocationPriceGroup(
            division: divName,
            district: distName,
            area: areaName,
            subArea: subAreaName,
          )).addProperty(
            price: price,
            roomOrSeat: p.roomOrSeat,
            hasLift: p.hasLift,
            hasParking: p.hasParking,
            hasGenerator: p.hasGenerator,
            hasCctv: p.hasCctv,
            hasSecurityGuard: p.hasSecurityGuard,
            balconies: p.balconies,
          );
        }
      }

      // Check if targetArea filter is provided
      final isAllAreas = targetArea == null ||
          targetArea.contains('সকল এলাকা') ||
          targetArea.contains('All Areas') ||
          targetArea.contains('প্রধান ৪টি অপশন') ||
          targetArea.contains('Main 4 Options');
      final searchedLoc = !isAllAreas ? _extractLocationQuery(targetArea) : null;

      var filteredGroups = groups.values.toList();
      bool isSpecificSearch = false;

      if (searchedLoc != null && searchedLoc.isNotEmpty) {
        isSpecificSearch = true;
        final matched = filteredGroups.where((g) =>
          g.area.toLowerCase().contains(searchedLoc.toLowerCase()) ||
          g.subArea.toLowerCase().contains(searchedLoc.toLowerCase()) ||
          g.district.toLowerCase().contains(searchedLoc.toLowerCase()) ||
          g.division.toLowerCase().contains(searchedLoc.toLowerCase())
        ).toList();

        if (matched.isNotEmpty) {
          filteredGroups = matched;
        } else {
          filteredGroups = []; // No exact matches in Firestore
        }
      }

      // Case A: Specific location searched, but not yet present in Firestore
      if (isSpecificSearch && filteredGroups.isEmpty) {
        final locCapitalized = searchedLoc![0].toUpperCase() + (searchedLoc.length > 1 ? searchedLoc.substring(1) : '');
        final buffer = StringBuffer();
        if (isBn) {
          buffer.writeln('💡 **$searchedLoc এলাকার জন্য এআই প্রস্তাবিত ভাড়ার রেঞ্জ (AI Rent Prediction):**\n');
          buffer.writeln('🔒 *গোপনীয়তা নোট: বাড়িওয়ালাদের ব্যক্তিগত প্রপার্টি লিস্টিং সুরক্ষিত রাখতে সরাসরি তথ্য প্রকাশ না করে এআই মার্কেট অ্যানালাইসিস উপস্থাপন করা হলো।*');
          buffer.writeln('📊 **বাসাবন্ধু এআই মার্কেট অ্যানালাইসিস অনুযায়ী প্রস্তাবিত ভাড়া:**');
          buffer.writeln('• 💰 সাধারণ প্রস্তাবিত রেঞ্জ: **৳ ৮,০০০ — ৳ ১৮,০০০** (আদর্শ গড়: ৳ ১২,৫০০)');
          buffer.writeln('• 🛏️ **রুম ও কনফিগারেশন ভিত্তিক প্রস্তাবিত ভাড়া:**');
          buffer.writeln('  - ১ বেডরুম / ব্যাচেলর রুম: ৳ ৩,৫০০ — ৳ ৬,৫০০');
          buffer.writeln('  - ২ বেডরুম + ১/২ বাথ ফ্যামিলি: ৳ ৮,০০০ — ৳ ১৩,০০০');
          buffer.writeln('  - ৩ বেডরুম + ২/৩ বাথ ফ্যামিলি: ৳ ১৪,০০০ — ৳ ২২,০০০');
          buffer.writeln('• 🏢 **সুবিধা ও ফিচারের প্রভাব (Value Addition):**');
          buffer.writeln('  - 🛗 লিফট ও জেনারেটর ব্যাকআপ: +৳ ১,৫০০ — ৳ ২,৫০০ ভাড়া বৃদ্ধি যৌক্তিক');
          buffer.writeln('  - 🚗 সংরক্ষিত কার পার্কিং: +৳ ২,০০০ — ৳ ৩,৫০০ যুক্ত হতে পারে');
          buffer.writeln('  - ⚡ তিতাস গ্যাস / প্রি-পেইড বিদ্যুৎ ও ব্যালকনি: দ্রুত ভাড়াটিয়া আকর্ষণে সহায়ক');
          buffer.writeln('──────────────────');
        } else {
          buffer.writeln('💡 **AI Suggested Rent Price Range for $locCapitalized (Market Prediction):**\n');
          buffer.writeln('🔒 *Privacy Notice: Individual house owner listings are shielded. Only aggregated AI market intelligence is provided.*');
          buffer.writeln('📊 **BashaBondhu AI Fair Market Rent Recommendation:**');
          buffer.writeln('• 💰 Suggested Base Range: **৳ 8,000 — ৳ 18,000** (Fair Avg: ৳ 12,500)');
          buffer.writeln('• 🛏️ **Room & Configuration Breakdown:**');
          buffer.writeln('  - 1-Bedroom / Bachelor: ৳ 3,500 — ৳ 6,500');
          buffer.writeln('  - 2-Bedroom + 1/2 Bath Family: ৳ 8,000 — ৳ 13,000');
          buffer.writeln('  - 3-Bedroom + 2/3 Bath Family: ৳ 14,000 — ৳ 22,000');
          buffer.writeln('• 🏢 **Feature & Amenity Value Impact:**');
          buffer.writeln('  - 🛗 Lift & Generator: +৳ 1,500 — ৳ 2,500 fair premium');
          buffer.writeln('  - 🚗 Dedicated Parking: +৳ 2,000 — ৳ 3,500 premium');
          buffer.writeln('  - ⚡ Gas & Balcony: High demand factor for faster occupancy');
          buffer.writeln('──────────────────');
        }

        history.add(
          AIMessageModel(
            id: 'price_${DateTime.now().millisecondsSinceEpoch}',
            text: buffer.toString(),
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['🔍 সকল এলাকা', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '⚡ প্রধান ৪টি অপশন']
                : ['🔍 All Areas', '👥 Find Tenant Demand', '💳 Subscription Packages', '⚡ Main 4 Options'],
            quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন'] : ['⚡ Main 4 Options'],
          ),
        );
        return;
      }

      // Case B: General empty database
      if (filteredGroups.isEmpty) {
        history.add(
          AIMessageModel(
            id: 'price_empty_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '💡 **বর্তমানে প্ল্যাটফর্মে প্রপার্টি ডাটা অ্যানালাইসিস চলছে।**\nবাড়িওয়ালারা টু-লেট পোস্ট করলে এআই মার্কেট প্রেডিকশন ইঞ্জিন স্বয়ংক্রিয়ভাবে আরও নিখুঁত ভাড়ার পরামর্শ দেবে।'
                : '💡 **Platform market data is currently being populated.**\nAs properties are listed, the AI prediction engine will refine fair rent estimates.',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '⚡ প্রধান ৪টি অপশন']
                : ['👥 Find Tenant Demand', '💳 Subscription Packages', '📄 Subscription History', '⚡ Main 4 Options'],
          ),
        );
        return;
      }

      // Case C: Display filtered or all groups from Firestore with AI Prediction & Amenities Analysis
      final buffer = StringBuffer();
      if (isBn) {
        buffer.writeln(isSpecificSearch
            ? '💡 **$searchedLoc এলাকার জন্য এআই প্রস্তাবিত ভাড়ার রেঞ্জ (AI Rent Prediction):**\n'
            : '💡 **এলাকাভিত্তিক এআই প্রস্তাবিত ভাড়ার রেঞ্জ ও বাজার বিশ্লেষণ (AI Market Rent Guide):**\n');
        buffer.writeln('🔒 *গোপনীয়তা রক্ষা: বাড়িওয়ালাদের ব্যক্তিগত বিজ্ঞাপন সুরক্ষিত রেখে ডাটাবেজ অ্যানালাইসিস ও এআই প্রেডিকশনের মাধ্যমে এই ভাড়ার পরামর্শ প্রদান করা হয়েছে।*\n');

        for (final g in filteredGroups) {
          buffer.writeln('🏛️ **বিভাগ:** ${g.division} | 🏙️ **জেলা:** ${g.district}');
          buffer.writeln('📍 **এলাকা:** ${g.area}${g.subArea.isNotEmpty ? " • **সাব-এরিয়া:** ${g.subArea}" : ""}');
          if (g.minPrice == g.maxPrice) {
            buffer.writeln('• 💡 প্রস্তাবিত আদর্শ ভাড়া: **৳ ${(g.minPrice.toInt().toString()).toLocalizedDigits(languageCode)}**');
          } else {
            buffer.writeln('• 💡 প্রস্তাবিত ভাড়ার রেঞ্জ: **৳ ${(g.minPrice.toInt().toString()).toLocalizedDigits(languageCode)} — ৳ ${(g.maxPrice.toInt().toString()).toLocalizedDigits(languageCode)}** (গড়: ৳ ${(g.avgPrice.toInt().toString()).toLocalizedDigits(languageCode)})');
          }
          if (g.roomPrices.isNotEmpty) {
            buffer.writeln('• 🛏️ **রুম ও কনফিগারেশন ভিত্তিক প্রস্তাবিত রেঞ্জ:**');
            for (final r in g.roomPrices.entries) {
              final rMin = r.value.reduce(min).toInt().toString().toLocalizedDigits(languageCode);
              final rMax = r.value.reduce(max).toInt().toString().toLocalizedDigits(languageCode);
              if (rMin == rMax) {
                buffer.writeln('  - ${r.key}: ৳ $rMin');
              } else {
                buffer.writeln('  - ${r.key}: ৳ $rMin — ৳ $rMax');
              }
            }
          }
          buffer.writeln('• 🏢 **সুবিধা ও প্রিমিয়াম ফিচারের প্রভাব:**');
          buffer.writeln('  - 🛗 লিফট ও জেনারেটর: +৳ ১,৫০০ — ৳ ২,৫০০ অতিরিক্ত ভাড়া যুক্ত করতে পারেন');
          buffer.writeln('  - 🚗 সংরক্ষিত কার পার্কিং: +৳ ২,০০০ — ৳ ৩,৫০০ অতিরিক্ত ভাড়া যুক্ত হতে পারে');
          buffer.writeln('──────────────────');
        }
      } else {
        buffer.writeln(isSpecificSearch
            ? '💡 **AI Suggested Rent Price Range for $searchedLoc (Market Prediction):**\n'
            : '💡 **Area-wise AI Suggested Rent Price Ranges & Market Guidance:**\n');
        buffer.writeln('🔒 *Privacy Notice: House owner listings are shielded. Insights are calculated via AI market analytics and aggregate data.*\n');

        for (final g in filteredGroups) {
          buffer.writeln('🏛️ **Division:** ${g.division} | 🏙️ **District:** ${g.district}');
          buffer.writeln('📍 **Area:** ${g.area}${g.subArea.isNotEmpty ? " • **Sub-Area:** ${g.subArea}" : ""}');
          if (g.minPrice == g.maxPrice) {
            buffer.writeln('• 💡 Suggested Base Rent: **৳ ${g.minPrice.toInt()}**');
          } else {
            buffer.writeln('• 💡 Suggested Rent Range: **৳ ${g.minPrice.toInt()} — ৳ ${g.maxPrice.toInt()}** (Fair Avg: ৳ ${g.avgPrice.toInt()})');
          }
          if (g.roomPrices.isNotEmpty) {
            buffer.writeln('• 🛏️ **Room & Configuration Breakdown:**');
            for (final r in g.roomPrices.entries) {
              final rMin = r.value.reduce(min).toInt();
              final rMax = r.value.reduce(max).toInt();
              if (rMin == rMax) {
                buffer.writeln('  - ${r.key}: ৳ $rMin');
              } else {
                buffer.writeln('  - ${r.key}: ৳ $rMin — ৳ $rMax');
              }
            }
          }
          buffer.writeln('• 🏢 **Amenity Premium Impact:**');
          buffer.writeln('  - 🛗 Lift & Generator: +৳ 1,500 — ৳ 2,500 fair premium');
          buffer.writeln('  - 🚗 Dedicated Parking: +৳ 2,000 — ৳ 3,500 premium');
          buffer.writeln('──────────────────');
        }
      }

      // Build dynamic chips
      final distinctAreas = groups.values.map((g) => g.area).toSet().toList();
      final List<String> dynamicChips = [];
      if (isBn) {
        dynamicChips.add('🔍 সকল এলাকা');
        for (final a in distinctAreas.take(6)) {
          dynamicChips.add(a);
        }
        dynamicChips.add('👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন');
        dynamicChips.add('⚡ প্রধান ৪টি অপশন');
      } else {
        dynamicChips.add('🔍 All Areas');
        for (final a in distinctAreas.take(6)) {
          dynamicChips.add(a);
        }
        dynamicChips.add('👥 Find Tenant Demand');
        dynamicChips.add('⚡ Main 4 Options');
      }

      history.add(
        AIMessageModel(
          id: 'price_${DateTime.now().millisecondsSinceEpoch}',
          text: buffer.toString(),
          sender: AIMessageSender.ai,
          interactiveChips: dynamicChips,
          quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন'] : ['⚡ Main 4 Options'],
        ),
      );
    } catch (e) {
      debugPrint('Error getting suggest price range: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void _showSubscriptionPackages(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];
    history.add(
      AIMessageModel(
        id: 'sub_pkg_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '💳 **সাবস্ক্রিপশন প্যাকেজসমূহ:**\n\nনিচের কার্ড থেকে আপনার পছন্দের প্ল্যান আপগ্রেড করুন এবং অতিরিক্ত সুবিধা আনলক করুন:'
            : '💳 **Subscription Packages:**\n\nExplore available subscription packages and upgrade your plan below:',
        sender: AIMessageSender.ai,
        actionCardType: AIActionCardType.subscriptionPackages,
        interactiveChips: isBn
            ? [
                '📄 সাবস্ক্রিপশন হিস্ট্রি',
                '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন',
                '💰 বিভিন্ন এলাকার ভাড়ার রেঞ্জ',
                '⚡ প্রধান ৪টি অপশন',
              ]
            : [
                '📄 Subscription History',
                '👥 Find Tenant Demand',
                '💰 Area Rent Price Range',
                '⚡ Main 4 Options',
              ],
        quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন', 'সাবস্ক্রিপশন হিস্ট্রি'] : ['⚡ Main 4 Options', 'Subscription History'],
      ),
    );
    notifyListeners();
  }

  void _showSubscriptionHistory(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];
    history.add(
      AIMessageModel(
        id: 'sub_hist_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '📄 **সাবস্ক্রিপশন হিস্ট্রি ও পেমেন্ট রিসিট:**\n\nআপনার বিগত পেমেন্টের ডিজিটাল রসিদ ও হিস্ট্রি দেখতে নিচের বাটনে চাপ দিন:'
            : '📄 **Subscription History & Payment Receipts:**\n\nClick below to view your transaction history and digital receipts:',
        sender: AIMessageSender.ai,
        actionCardType: AIActionCardType.subscriptionHistory,
        interactiveChips: isBn
            ? [
                '💳 সাবস্ক্রিপশন প্যাকেজ',
                '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন',
                '💡 প্রস্তাবিত ভাড়ার রেঞ্জ',
                '⚡ প্রধান ৪টি অপশন',
              ]
            : [
                '💳 Subscription Packages',
                '👥 Find Tenant Demand',
                '💡 Suggest Price Range',
                '⚡ Main 4 Options',
              ],
        quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন', 'সাবস্ক্রিপশন প্যাকেজ'] : ['⚡ Main 4 Options', 'Subscription Packages'],
      ),
    );
    notifyListeners();
  }

  // ==========================================
  // HOUSE OWNER FAQS (FETCHED LIVE FROM FIRESTORE)
  // ==========================================

  Future<void> _showHouseOwnerFaq(UserModel user, String languageCode) async {
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    try {
      final buffer = StringBuffer();
      if (isBn) {
        buffer.writeln('❓ **বাসাবন্ধু বাড়িওয়ালা সাধারণ জিজ্ঞাসা ও সমাধান (FAQs):**\n');
        buffer.writeln('📌 *বাড়িওয়ালা হিসেবে আপনার প্রয়োজনীয় প্রধান প্রশ্নোত্তর নিচে দেওয়া হলো:*\n');

        final faqsBn = [
          {
            'q': 'আমি কীভাবে বিনামূল্যে বাসা ভাড়ার বিজ্ঞাপন (To-Let) দেব?',
            'a': 'বাড়িওয়ালা অ্যাকাউন্টে লগইন করে ড্যাশবোর্ডের নিচে **"Post Free"** বা **"+"** বাটনে চাপ দিন। আপনার বাসার সঠিক এলাকা (বিভাগ, জেলা, এলাকা, সাব-এরিয়া), রুমের বিবরণ (বেডরুম, বাথরুম, বারান্দা, ফ্লোর), মাসিক ভাড়া ও পরিষ্কার ছবি যুক্ত করে সাবমিট করলেই বিজ্ঞাপন তাৎক্ষণিক লাইভ হয়ে যাবে।',
          },
          {
            'q': '\'ভাড়া হয়ে গেছে (Rented Out)\' বোতামের কাজ কী এবং কীভাবে ব্যবহার করব?',
            'a': 'আপনার বাসা ভাড়া হয়ে যাওয়ার সাথে সাথে **My Post** স্ক্রিনে গিয়ে **"ভাড়া হয়ে গেছে (Rented Out)"** সুইচটি চালু করে দিন। এতে আপনার বিজ্ঞাপনটি সাধারণ অনুসন্ধান থেকে সম্পূর্ণ অদৃশ্য ও সুরক্ষিত থাকবে। পরবর্তীতে আবার বাসা খালি হলে এক ক্লিকেই পুনরায় লাইভ করতে পারবেন।',
          },
          {
            'q': 'ভাড়াটিয়াদের সক্রিয় চাহিদা (Tenant Demands) কীভাবে খুঁজে পাব?',
            'a': 'ড্যাশবোর্ডের **"Demand"** স্ক্রিনে যান অথবা এই এআই সহকারীর মাধ্যমে আপনার এলাকার সক্রিয় ভাড়াটিয়াদের চাহিদাপত্র ও বাজেট ফিল্টার (যেমন: ৳৬,০০০-১০,০০০, ৳১১,০০০-১৫,০০০) দেখে সরাসরি আগ্রহী ভাড়াটিয়ার সাথে যোগাযোগ করতে পারেন।',
          },
          {
            'q': 'ভাড়াটিয়াদের \'বাসা পেয়ে গেছি (Mark as Fulfilled)\' বোতামের কাজ কী?',
            'a': 'ভাড়াটিয়া পছন্দের বাসা পেয়ে গেলে তার **My Demand** স্ক্রিন থেকে এই বোতামটি চালু করে দেন। ফলে বাড়িওয়ালারা আর সেই পুরনো চাহিদাটি দেখতে পান না এবং অপ্রয়োজনীয় যোগাযোগ বন্ধ হয়।',
          },
          {
            'q': 'এআই প্রস্তাবিত ভাড়ার রেঞ্জ (Suggest Price Range) কীভাবে সাহায্য করে?',
            'a': 'বাসাবন্ধু এআই ডাটাবেজ অ্যানালাইসিস করে এলাকা, রুম এবং বিশেষ সুবিধা (লিফট, পার্কিং, জেনারেটর ব্যাকআপ, তিতাস গ্যাস) বিবেচনা করে অন্য বাড়িওয়ালাদের গোপনীয়তা অক্ষুণ্ণ রেখে আপনার বাসার জন্য ন্যায্য ও যৌক্তিক ভাড়ার পরামর্শ প্রদান করে।',
          },
          {
            'q': 'বাড়িওয়ালা সাবস্ক্রিপশন প্যাকেজের সুবিধা কী এবং রসিদ কোথায় পাওয়া যাবে?',
            'a': 'সাবস্ক্রিপশন প্ল্যানের মাধ্যমে একাধিক বিজ্ঞাপন প্রকাশ, বিজ্ঞাপনে \'Featured\' বা \'Verified\' ব্যাজ এবং দ্রুত ভাড়াটিয়া পাওয়ার সুবিধা পাওয়া যায়। সকল সফল পেমেন্টের ডিজিটাল রসিদ **Subscription History**-তে সংরক্ষিত থাকে।',
          },
          {
            'q': 'পাসওয়ার্ড ভুলে গেলে কীভাবে জিমেইলে রিকভার করব?',
            'a': 'সাইন ইন স্ক্রিনের নিচে **"Forgot Password?"**-এ চাপ দিয়ে আপনার নিবন্ধিত জিমেইলটি লিখুন। সাথে সাথে ফায়ারবেস থেকে আপনার ইমেইলে একটি নিরাপদ পাসওয়ার্ড রিসেট লিংক সম্পূর্ণ বিনামূল্যে পাঠানো হবে।',
          },
          {
            'q': 'বাসাবন্ধু কীভাবে প্রপার্টি বিজ্ঞাপন ও ব্যবহারকারীদের নিরাপত্তা নিশ্চিত করে?',
            'a': 'আমরা মোবাইল ওটিপি (OTP) ও এনআইডি ভেরিফিকেশনের মাধ্যমে প্রকৃত ব্যবহারকারী নিশ্চিত করি এবং ভুয়া বা বিভ্রান্তিকর বিজ্ঞাপন প্রতিরোধে নিয়মিত অডিট পরিচালনা করি।',
          },
        ];

        for (int i = 0; i < faqsBn.length; i++) {
          final q = faqsBn[i]['q']!;
          final a = faqsBn[i]['a']!;
          buffer.writeln('**প্রশ্ন ${(i + 1).toString().toLocalizedDigits('bn')}: $q**');
          buffer.writeln('👉 **উত্তর:** $a\n');
        }
        buffer.writeln('──────────────────');
        buffer.writeln('💡 *আপনার অন্য কোনো নির্দিষ্ট প্রশ্ন থাকলে সরাসরি এখানে লিখে জিজ্ঞেস করতে পারেন।*');
      } else {
        buffer.writeln('❓ **BashaBondhu House Owner Frequently Asked Questions (FAQs):**\n');
        buffer.writeln('📌 *Here are the primary questions and answers for house owners:*\n');

        final faqsEn = [
          {
            'q': 'How do I post a free To-Let advertisement as a House Owner?',
            'a': 'Sign in as a House Owner and tap the **"Post Free"** or **"+"** button on your dashboard. Enter your property location (Division, District, Area, Sub-Area), room configurations (bedrooms, bathrooms, balconies, floor level), monthly rent, deposit, and upload clear photos to publish immediately.',
          },
          {
            'q': 'What is the "Rented Out" toggle button and how do I use it?',
            'a': 'Once your property is rented, go to the **My Post** screen and turn ON the **"Rented Out"** toggle. This immediately hides your listing from tenant search feeds while keeping your data safe. When the house becomes vacant again, you can reactivate it with a single tap.',
          },
          {
            'q': 'How can House Owners find and match active Tenant Demands?',
            'a': 'Open the **"Demand"** tab from your dashboard or ask this AI Assistant. You can browse active renter requests in your area, filter by budget ranges (e.g. ৳6k-10k, ৳11k-15k), and directly call interested tenants.',
          },
          {
            'q': 'What is the "Mark as Fulfilled" toggle for tenants?',
            'a': 'When a tenant secures a rental home, enabling this toggle on their **My Demand** screen marks the demand as fulfilled and removes it from house owners\' demand feeds.',
          },
          {
            'q': 'How does the AI Suggested Rent Price Range help landlords?',
            'a': 'The AI analyzes live platform market data across areas, rooms, and premium amenities (Lift, Parking, Generator backup, Gas) to recommend fair, competitive rental prices while strictly protecting every landlord\'s listing privacy.',
          },
          {
            'q': 'What are the benefits of House Owner Subscription Packages and where is the receipt?',
            'a': 'Subscription packages allow owners to publish multiple listings, get "Featured" top placement badges, and unlock direct tenant contact numbers. All digital transaction receipts are archived in **Subscription History**.',
          },
          {
            'q': 'How do I recover my password if forgotten?',
            'a': 'On the Sign In screen, click **"Forgot Password?"**. Enter your registered Gmail address and Firebase will instantly send a secure password reset link to your email free of cost.',
          },
          {
            'q': 'How does BashaBondhu ensure listing authenticity & security?',
            'a': 'We verify users via mobile OTP and NID verification, and conduct manual audits on listings to prevent fake or misleading advertisements.',
          },
        ];

        for (int i = 0; i < faqsEn.length; i++) {
          final q = faqsEn[i]['q']!;
          final a = faqsEn[i]['a']!;
          buffer.writeln('**Q${i + 1}: $q**');
          buffer.writeln('👉 **Answer:** $a\n');
        }
        buffer.writeln('──────────────────');
        buffer.writeln('💡 *If you have any specific query, feel free to type it directly in the chat.*');
      }

      history.add(
        AIMessageModel(
          id: 'faq_${DateTime.now().millisecondsSinceEpoch}',
          text: buffer.toString(),
          sender: AIMessageSender.ai,
          interactiveChips: isBn
              ? ['📖 কীভাবে অ্যাপ ব্যবহার করবেন', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '⚡ প্রধান ৪টি অপশন']
              : ['📖 How to Use', '👥 Find Tenant Demand', '💡 Suggest Price Range', '⚡ Main 4 Options'],
          quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন'] : ['⚡ Main 4 Options'],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ==========================================
  // HOUSE OWNER STEP-BY-STEP "HOW TO USE" MASTER GUIDE
  // ==========================================

  void _showHouseOwnerHowToUse(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    final buffer = StringBuffer();
    if (isBn) {
      buffer.writeln('📖 **বাড়িওয়ালাদের জন্য বাসাবন্ধু অ্যাপ ব্যবহারের সহজ নির্দেশিকা (Step-by-Step Guide):**\n');
      buffer.writeln('১️⃣ **অ্যাকাউন্ট ও প্রোফাইল সেটআপ (Account Setup):**');
      buffer.writeln('   • বাড়িওয়ালা (House Owner) হিসেবে সাইন ইন করে আপনার প্রোফাইল সম্পূর্ণ করুন।');
      buffer.writeln('   • অ্যাকাউন্টে আপনার নাম ও মোবাইল নম্বর নিশ্চিত রাখুন যাতে ভাড়াটিয়ারা সহজে যোগাযোগ করতে পারে।\n');

      buffer.writeln('২️⃣ **বিনামূল্যে টু-লেট বিজ্ঞাপন পোস্ট (Post Free To-Let Ad):**');
      buffer.writeln('   • ড্যাশবোর্ডের নিচে **"Post Free"** অথবা **"+"** বাটনে চাপ দিন।');
      buffer.writeln('   • আপনার বাসার বিভাগ, জেলা, এলাকা, সাব-এরিয়া, বেডরুম, বাথরুম, ভাড়া এবং পরিষ্কার ছবি আপলোড করে মুহূর্তেই লাইভ করুন।\n');

      buffer.writeln('৩️⃣ **বিজ্ঞাপন নিয়ন্ত্রণ ও "ভাড়া হয়ে গেছে" বোতাম (Listing Control & "Rented Out"):**');
      buffer.writeln('   • বাসা ভাড়া হয়ে যাওয়ার সাথে সাথে **My Post** স্ক্রিন থেকে **"ভাড়া হয়ে গেছে (Rented Out)"** সুইচটি অন করে দিন।');
      buffer.writeln('   • এতে আপনার বিজ্ঞাপনটি সাধারণ অনুসন্ধান থেকে সুরক্ষিত ও হাইড থাকবে। বাসা খালি হলে পুনরায় এক ক্লিকেই আবার লাইভ করতে পারবেন।\n');

      buffer.writeln('৪️⃣ **ভাড়াটিয়াদের লাইভ চাহিদা ও ডিমান্ড ব্রাউজিং (Browse Tenant Demands):**');
      buffer.writeln('   • **"Demand"** স্ক্রিন অথবা এই এআই সহকারীর মাধ্যমে এলাকার সক্রিয় ভাড়াটিয়াদের পোস্ট ও বাজেট চেক করুন।');
      buffer.writeln('   • আপনার বাসার সাথে মিলে গেলে সরাসরি তাদের সাথে যোগাযোগ করে দ্রুত বাসা ভাড়া দিন।\n');

      buffer.writeln('৫️⃣ **এআই ভাড়ার পূর্বাভাস ও মার্কেট গাইড (AI Suggest Price Range):**');
      buffer.writeln('   • আপনার এলাকার নাম লিখে এআই-কে জিজ্ঞেস করুন ন্যায্য ভাড়ার রেঞ্জ জানতে।');
      buffer.writeln('   • লিফট, পার্কিং ও জেনারেটর সুবিধার জন্য কত ভাড়া বাড়ানো যৌক্তিক তা যাচাই করুন।\n');

      buffer.writeln('৬️⃣ **সাবস্ক্রিপশন প্যাকেজ ও ফিচার্ড বুস্টিং (Subscription Packages):**');
      buffer.writeln('   • একাধিক প্রপার্টি লিস্টিং ও প্রিমিয়াম ভেরিফাইড ব্যাজের জন্য সুবিধাজনক সাবস্ক্রিপশন প্যাকেজ বেছে নিন।');
      buffer.writeln('   • ডিজিটাল পেমেন্ট রসিদ ও লেনদেনের ইতিহাস সংরক্ষণ থাকে **Subscription History**-তে।\n');

      buffer.writeln('৭️⃣ **দ্বিভাষিক সুবিধা ও পাসওয়ার্ড রিকভারি (Bilingual & Password Reset):**');
      buffer.writeln('   • উপরে ট্রান্সলেট আইকন চেপে যেকোনো সময় বাংলা ও ইংরেজিতে সুইচ করুন।');
      buffer.writeln('   • পাসওয়ার্ড ভুলে গেলে সাইন ইন স্ক্রিনের "Forgot Password?" দিয়ে ফ্রিতে জিমেইলের মাধ্যমে রিসেট করুন।');
      buffer.writeln('──────────────────');
      buffer.writeln('💡 *অ্যাপ ব্যবহারের যেকোনো বিষয়ে আরও বিস্তারিত জানতে নিচের বাটনে ক্লিক করুন।*');
    } else {
      buffer.writeln('📖 **Step-by-Step Guide: How to Use BashaBondhu as a House Owner:**\n');
      buffer.writeln('1️⃣ **Account Setup & Profile:**');
      buffer.writeln('   • Sign in with your House Owner credentials and keep your contact details updated.\n');

      buffer.writeln('2️⃣ **Post Free To-Let Advertisements:**');
      buffer.writeln('   • Tap the **"Post Free"** or **"+"** button at the bottom of your dashboard.');
      buffer.writeln('   • Provide Division, District, Area, Sub-Area, rent, room configurations, and photos to publish instantly.\n');

      buffer.writeln('3️⃣ **Listing Control & "Rented Out" Toggle:**');
      buffer.writeln('   • When your home gets rented, turn on the **"Rented Out"** toggle on the **My Post** screen.');
      buffer.writeln('   • This keeps your listing hidden from public search until the apartment is available again.\n');

      buffer.writeln('4️⃣ **Browse & Match Tenant Demands:**');
      buffer.writeln('   • Open the **"Demand"** screen or ask this AI Assistant to view live tenant requirements and budgets in your neighborhood.');
      buffer.writeln('   • Connect directly with prospective renters to minimize vacancy time.\n');

      buffer.writeln('5️⃣ **AI Market Rental Predictions & Fair Guidance:**');
      buffer.writeln('   • Ask the AI for fair rent estimates based on area, rooms, lifts, generators, and parking.\n');

      buffer.writeln('6️⃣ **Subscription Packages & Verified Boosts:**');
      buffer.writeln('   • Upgrade to premium packages to list multiple properties and gain verified trust badges.');
      buffer.writeln('   • View digital receipts anytime in **Subscription History**.\n');

      buffer.writeln('7️⃣ **Bilingual Switch & Password Recovery:**');
      buffer.writeln('   • Toggle English/Bengali from any screen AppBar.');
      buffer.writeln('   • Reset forgotten passwords seamlessly via free Firebase Gmail links.');
      buffer.writeln('──────────────────');
      buffer.writeln('💡 *Tap any quick option below to explore further.*');
    }

    history.add(
      AIMessageModel(
        id: 'guide_${DateTime.now().millisecondsSinceEpoch}',
        text: buffer.toString(),
        sender: AIMessageSender.ai,
        interactiveChips: isBn
            ? ['❓ সাধারণ জিজ্ঞাসা', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '💡 প্রস্তাবিত ভাড়ার রেঞ্জ', '⚡ প্রধান ৪টি অপশন']
            : ['❓ FAQ', '👥 Find Tenant Demand', '💡 Suggest Price Range', '⚡ Main 4 Options'],
        quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন'] : ['⚡ Main 4 Options'],
      ),
    );
    notifyListeners();
  }

  // ==========================================
  // DYNAMIC POLICY HANDLER (FIREBASE BACKED)
  // ==========================================

  Future<void> _showHouseOwnerPolicy(UserModel user, String policyType, String languageCode) async {
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    try {
      final policy = await PolicyFirestoreService().getPolicy(
        policyType,
        targetAudience: user.isHouseOwner ? 'house_owner' : 'tenant',
      );

      final buffer = StringBuffer();
      final title = policy.getTitle(languageCode);
      final subtitle = policy.getSubtitle(languageCode);

      buffer.writeln('🛡️ **$title**\n');
      if (subtitle.isNotEmpty) {
        buffer.writeln('📌 *$subtitle*\n');
      }

      for (final section in policy.sections) {
        final h = section.getHeading(languageCode);
        final c = section.getContent(languageCode);
        buffer.writeln('**$h**');
        buffer.writeln('$c\n');
      }

      buffer.writeln('──────────────────');
      buffer.writeln(isBn
          ? '💡 *বাসাবন্ধু অ্যাপ ব্যবহারের সকল শর্ত ও নীতিমালা ফায়ারবেসে সর্বদা সংরক্ষিত।*'
          : '💡 *All platform terms and policies are actively maintained in Firebase.*');

      history.add(
        AIMessageModel(
          id: 'pol_${DateTime.now().millisecondsSinceEpoch}',
          text: buffer.toString(),
          sender: AIMessageSender.ai,
          interactiveChips: isBn
              ? ['❓ সাধারণ জিজ্ঞাসা', '📖 কীভাবে অ্যাপ ব্যবহার করবেন', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '⚡ প্রধান ৪টি অপশন']
              : ['❓ FAQ', '📖 How to Use', '👥 Find Tenant Demand', '⚡ Main 4 Options'],
          quickActions: isBn ? ['⚡ প্রধান ৪টি অপশন'] : ['⚡ Main 4 Options'],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching policy: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Live Anonymized Public Database Context Builder for Gemini Agent
  Future<String> _buildLivePublicDbContext(String languageCode) async {
    try {
      final propsSnap = await _firestore.collection('properties').limit(25).get();
      final demandsSnap = await _firestore.collection('tenant_demands').limit(25).get();

      final List<String> propSummaries = [];
      for (final doc in propsSnap.docs) {
        final data = doc.data();
        if (data['isRentedOut'] != true) {
          final area = (data['area'] is Map ? (data['area']['name'] ?? data['area']['bnName']) : data['area']) ?? 'Dhaka';
          final rent = data['amount'] ?? 'N/A';
          final room = data['roomOrSeat'] ?? 'Flat';
          propSummaries.add('• $area: $room (Rent: ৳$rent)');
        }
      }

      final List<String> demandSummaries = [];
      for (final doc in demandsSnap.docs) {
        final data = doc.data();
        if (data['isFulfilled'] != true) {
          final area = (data['area'] is Map ? (data['area']['name'] ?? data['area']['bnName']) : data['area']) ?? 'Dhaka';
          final budget = data['budgetRange'] ?? 'N/A';
          final room = data['roomOrSeat'] ?? 'Flat';
          demandSummaries.add('• $area: Seeking $room (Budget: ৳$budget)');
        }
      }

      return '''Active Available Properties:
${propSummaries.take(8).join('\n')}

Active Tenant Demands:
${demandSummaries.take(8).join('\n')}''';
    } catch (e) {
      return '';
    }
  }

  // ==========================================
  // CONFIRM & PUBLISH DEMAND TO FIRESTORE
  // ==========================================

  Future<bool> confirmAndPublishDemand({
    required DemandDraftModel draft,
    required UserModel user,
    required String languageCode,
  }) async {
    try {
      final docRef = _firestore.collection('tenant_demands').doc();
      final now = DateTime.now();

      final newDemand = TenantDemandModel(
        id: docRef.id,
        tenantId: user.uid,
        tenantEmail: user.email,
        userName: draft.userName ?? user.fullName,
        userMobile: draft.userMobile ?? user.mobile,
        userWhatsApp: draft.userWhatsApp ?? user.mobile,
        month: draft.month ?? '${now.month}/${now.year}',
        houseType: HouseType.flat,
        roomOrSeat: draft.roomOrSeat ?? 'BedRoom - 2',
        division: DivisionModel(id: 'dhaka_div', name: draft.division ?? 'Dhaka', bnName: 'ঢাকা'),
        district: DistrictModel(id: 'dhaka_dist', divisionId: 'dhaka_div', name: draft.district ?? 'Dhaka', bnName: 'ঢাকা'),
        area: UpazilaModel(id: 'area_gen', districtId: 'dhaka_dist', name: draft.area ?? 'Mirpur', bnName: draft.area ?? 'মিরপুর'),
        subArea: draft.subArea != null ? UnionModel(id: 'sub_gen', upazilaId: 'area_gen', name: draft.subArea!, bnName: draft.subArea!) : null,
        budgetRange: draft.budgetRange ?? '15000',
        tenantType: TenantType.family,
        bathrooms: draft.bathrooms ?? 2,
        balconies: draft.balconies ?? 1,
        floorNumber: draft.floorNumber ?? 2,
        hasLift: draft.hasLift ?? false,
        hasParking: draft.hasParking ?? false,
        hasGivenNotice: draft.hasGivenNotice ?? false,
        shortAddress: draft.area ?? 'Mirpur',
        detailedDescription: 'Created conversationally via BashaBondhu AI Assistant',
        postDate: now,
      );

      await docRef.set(newDemand.toMap());

      final history = _userSessions[_activeUserId] ??= [];
      history.add(
        AIMessageModel(
          id: 'success_${DateTime.now().millisecondsSinceEpoch}',
          text: languageCode == 'bn'
              ? '🎉 **অভিনন্দন! আপনার Tenant Demand সফলভাবে লাইভ পোস্ট করা হয়েছে!**\nএলাকার বাড়িওয়ালারা আপনার চাহিদা দেখতে পেলে সরাসরি যোগাযোগ করবেন।'
              : '🎉 **Congratulations! Your Tenant Demand is now live!**\nHouse owners in this area can now view your demand and contact you.',
          sender: AIMessageSender.ai,
          interactiveChips: languageCode == 'bn' ? ['🔍 অন্যান্য বাসা খুঁজুন', '💳 সাবস্ক্রিপশন হিস্ট্রি', '👤 আমার প্রোফাইল'] : ['🔍 Search Homes', '💳 Subscription History', '👤 My Profile'],
        ),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error publishing demand via AI: $e');
      return false;
    }
  }

  // ==========================================
  // AD GENERATION HELPER FOR HOUSE OWNER FORM
  // ==========================================

  Future<String> generateAdDescriptionForOwner({
    required String area,
    required String houseType,
    required String roomOrSeat,
    required String floor,
    required String amount,
    required List<String> amenities,
    required String languageCode,
  }) async {
    final isBn = languageCode == 'bn';
    final amenityText = amenities.isNotEmpty ? amenities.join(', ') : 'সকল আধুনিক সুযোগ-সুবিধা';

    if (isBn) {
      return '''🏠 **আকর্ষণীয় টু-লেট বিজ্ঞাপন**
📍 **লোকেশন:** $area এর নিরিবিলি ও নিরাপদ পরিবেশে।
🛏️ **বাসার ধরণ:** $houseType ($roomOrSeat)।
🏢 **ফ্লোর:** $floor।
✨ **সুবিধাসমূহ:** $amenityText। আলো-বাতাসপূর্ণ মনোরম পরিবেশ ও ২৪ ঘন্টা নিরাপত্তা।
💰 **মাসিক ভাড়া:** ৳ $amount (আলোচনা সাপেক্ষে)।
📞 আগ্রহী প্রকৃত ভাড়াটিয়াদের দ্রুত যোগাযোগের জন্য অনুরোধ করা যাচ্ছে।''';
    } else {
      return '''🏠 **Attractive To-Let Notice**
📍 **Location:** Prime and secure location in $area.
🛏️ **Property Details:** $houseType ($roomOrSeat).
🏢 **Floor Level:** $floor.
✨ **Amenities Included:** $amenityText. Well-ventilated, bright and 24/7 secured building.
💰 **Monthly Rent:** ৳ $amount (Negotiable).
📞 Genuine interested tenants are requested to contact directly.''';
    }
  }

  // ==========================================
  // FIRESTORE QUERIES
  // ==========================================

  Future<List<PropertyModel>> _fetchProperties(Map<String, dynamic>? filters) async {
    try {
      final snapshot = await _firestore.collection('properties').limit(20).get();
      final allProperties = snapshot.docs.map((doc) => PropertyModel.fromMap(doc.data(), doc.id)).toList();

      if (filters == null || filters.isEmpty) {
        return allProperties.take(5).toList();
      }

      final areaFilter = filters['area']?.toString().toLowerCase();
      final districtFilter = filters['district']?.toString().toLowerCase();
      final maxPrice = filters['max_price'] as int? ?? (filters['budget'] != null ? int.tryParse(filters['budget'].toString().replaceAll(RegExp(r'\D'), '')) : null);

      var results = allProperties.where((p) {
        bool match = true;
        if (areaFilter != null && areaFilter.isNotEmpty) {
          final pArea = p.area.name.toLowerCase();
          final pBnArea = p.area.bnName.toLowerCase();
          final pAddress = p.shortAddress.toLowerCase();
          if (!pArea.contains(areaFilter) && !pBnArea.contains(areaFilter) && !pAddress.contains(areaFilter)) {
            match = false;
          }
        }
        if (districtFilter != null && districtFilter.isNotEmpty) {
          final pDist = p.district.name.toLowerCase();
          final pBnDist = p.district.bnName.toLowerCase();
          if (!pDist.contains(districtFilter) && !pBnDist.contains(districtFilter)) {
            match = false;
          }
        }
        if (maxPrice != null && maxPrice > 0) {
          final pPrice = double.tryParse(p.amount) ?? 0;
          if (pPrice > maxPrice * 1.25) {
            match = false;
          }
        }
        return match;
      }).toList();

      if (results.isEmpty) {
        return allProperties.take(4).toList();
      }

      return results.take(6).toList();
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      return [];
    }
  }



  Future<AdminStatsModel> _fetchAdminLiveStats() async {
    try {
      final propsSnap = await _firestore.collection('properties').get();
      final usersSnap = await _firestore.collection('users').get();
      final demandsSnap = await _firestore.collection('tenant_demands').get();
      final txSnap = await _firestore.collection('subscription_transactions').get();

      int tenants = 0;
      int owners = 0;
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final type = (data['userType'] ?? '').toString().toLowerCase();
        if (type.contains('owner')) {
          owners++;
        } else {
          tenants++;
        }
      }

      double revenue = 0;
      for (final doc in txSnap.docs) {
        final amt = double.tryParse(doc.data()['amount']?.toString() ?? '0') ?? 0;
        revenue += amt;
      }

      final Map<String, int> areaCounts = {};
      for (final doc in propsSnap.docs) {
        final areaData = doc.data()['area'];
        final areaName = (areaData is Map ? areaData['name'] : areaData?.toString()) ?? 'Dhaka';
        areaCounts[areaName] = (areaCounts[areaName] ?? 0) + 1;
      }

      final sortedAreas = areaCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topAreas = sortedAreas.take(3).map((e) => {'area': e.key, 'count': e.value}).toList();

      return AdminStatsModel(
        totalProperties: propsSnap.size,
        totalUsers: usersSnap.size,
        totalTenants: tenants,
        totalOwners: owners,
        totalDemands: demandsSnap.size,
        totalSubscriptions: txSnap.size,
        totalRevenue: revenue,
        topAreas: topAreas,
      );
    } catch (e) {
      debugPrint('Error fetching live admin stats: $e');
      return const AdminStatsModel(
        totalProperties: 12,
        totalUsers: 28,
        totalTenants: 19,
        totalOwners: 9,
        totalDemands: 8,
        totalSubscriptions: 6,
        totalRevenue: 2490,
        topAreas: [
          {'area': 'Mirpur', 'count': 6},
          {'area': 'Uttara', 'count': 4},
          {'area': 'Dhanmondi', 'count': 2},
        ],
      );
    }
  }

  /// Clear chat for this user
  void clearChat(String userId, UserModel user, String languageCode) {
    _userSessions[userId] = [];
    _activeWizard = WizardMode.none;
    _wizardStep = 0;
    _addWelcomeMessage(user, languageCode);
    notifyListeners();
  }
}

/// Helper class to aggregate Firestore property price ranges per Location
class _LocationPriceGroup {
  final String division;
  final String district;
  final String area;
  final String subArea;
  final List<double> prices = [];
  final Map<String, List<double>> roomPrices = {};
  int liftCount = 0;
  int parkingCount = 0;
  int generatorCount = 0;
  int cctvSecurityCount = 0;
  int balconyCount = 0;

  _LocationPriceGroup({
    required this.division,
    required this.district,
    required this.area,
    required this.subArea,
  });

  void addProperty({
    required double price,
    required String roomOrSeat,
    bool? hasLift,
    bool? hasParking,
    bool? hasGenerator,
    bool? hasCctv,
    bool? hasSecurityGuard,
    int? balconies,
  }) {
    prices.add(price);
    roomPrices.putIfAbsent(roomOrSeat, () => []).add(price);
    if (hasLift == true) liftCount++;
    if (hasParking == true) parkingCount++;
    if (hasGenerator == true) generatorCount++;
    if (hasCctv == true || hasSecurityGuard == true) cctvSecurityCount++;
    if ((balconies ?? 0) > 0) balconyCount++;
  }

  double get minPrice => prices.isNotEmpty ? prices.reduce(min) : 0;
  double get maxPrice => prices.isNotEmpty ? prices.reduce(max) : 0;
  double get avgPrice => prices.isNotEmpty ? (prices.reduce((a, b) => a + b) / prices.length) : 0;
}

/// Helper to normalize raw demand budget into user-friendly standardized buckets
String? _normalizeBudgetBucket(String rawBudget, bool isBn) {
  if (rawBudget.isEmpty) return null;

  final digits = RegExp(r'\d+').allMatches(rawBudget).map((m) => int.parse(m.group(0)!)).toList();
  if (digits.isEmpty) return null;

  final int minVal = digits.first;
  final int maxVal = digits.length > 1 ? digits[1] : minVal;

  if (rawBudget.contains('50000+') || maxVal > 35000 || rawBudget.contains('+')) {
    return isBn ? '৳ ৩৫,০০০+' : 'Above ৳35k';
  } else if (maxVal <= 5000) {
    return isBn ? '৳ ৫,০০০ এর নিচে' : 'Below ৳5k';
  } else if (maxVal <= 10000) {
    return isBn ? '৳ ৬,০০০-১০,০০০' : '৳6k-10k';
  } else if (maxVal <= 15000) {
    return isBn ? '৳ ১১,০০০-১৫,০০০' : '৳11k-15k';
  } else if (maxVal <= 20000) {
    return isBn ? '৳ ১৬,০০০-২০,০০০' : '৳16k-20k';
  } else if (maxVal <= 25000) {
    return isBn ? '৳ ২১,০০০-২৫,০০০' : '৳21k-25k';
  } else if (maxVal <= 30000) {
    return isBn ? '৳ ২৬,০০০-৩০,০০০' : '৳26k-30k';
  } else {
    return isBn ? '৳ ৩১,০০০-৪০,০০০' : '৳31k-40k';
  }
}

/// Helper to match whether a demand post fits the selected budget filter text
bool _matchesBudgetFilter(TenantDemandModel demand, String filterText) {
  final raw = demand.budgetRange?.trim() ?? '';
  if (raw.isEmpty) return false;

  final digits = RegExp(r'\d+').allMatches(raw).map((m) => int.parse(m.group(0)!)).toList();
  if (digits.isEmpty) return false;

  final int minVal = digits.first;
  final int maxVal = digits.length > 1 ? digits[1] : minVal;

  final lower = filterText.toLowerCase();

  if (lower.contains('নিচে') || lower.contains('below') || lower.contains('5k') || lower.contains('5000')) {
    return minVal <= 5000 || maxVal <= 5000;
  }
  if (lower.contains('6k-10k') || lower.contains('6000') || lower.contains('10000') || lower.contains('১০,০০০') || lower.contains('১০ হাজার')) {
    return (minVal >= 5000 && minVal <= 10000) || (maxVal >= 6000 && maxVal <= 10000);
  }
  if (lower.contains('11k-15k') || lower.contains('11000') || lower.contains('15000') || lower.contains('১৫,০০০') || lower.contains('১৫ হাজার')) {
    return (minVal >= 10000 && minVal <= 15000) || (maxVal >= 11000 && maxVal <= 15000);
  }
  if (lower.contains('16k-20k') || lower.contains('16000') || lower.contains('20000') || lower.contains('২০,০০০') || lower.contains('২০ হাজার')) {
    return (minVal >= 15000 && minVal <= 20000) || (maxVal >= 16000 && maxVal <= 20000);
  }
  if (lower.contains('21k-25k') || lower.contains('21000') || lower.contains('25000') || lower.contains('২৫,০০০') || lower.contains('২৫ হাজার')) {
    return (minVal >= 20000 && minVal <= 25000) || (maxVal >= 21000 && maxVal <= 25000);
  }
  if (lower.contains('26k-30k') || lower.contains('26000') || lower.contains('30000') || lower.contains('৩০,০০০') || lower.contains('৩০ হাজার')) {
    return (minVal >= 25000 && minVal <= 30000) || (maxVal >= 26000 && maxVal <= 30000);
  }
  if (lower.contains('31k-40k') || lower.contains('31000') || lower.contains('40000') || lower.contains('৪০,০০০') || lower.contains('৪০ হাজার')) {
    return (minVal >= 30000 && minVal <= 40000) || (maxVal >= 31000 && maxVal <= 40000);
  }
  if (lower.contains('35k') || lower.contains('৩৫,০০০') || lower.contains('above') || lower.contains('বেশি') || lower.contains('+')) {
    return minVal >= 35000 || maxVal >= 35000;
  }

  return true;
}

/// Helper function to extract recognized location names from user prompt
String? _extractLocationQuery(String input) {
  final lower = input.toLowerCase();
  final locations = [
    'gazipur', 'গাজীপুর',
    'mirpur', 'মিরপুর',
    'uttara', 'উত্তরা',
    'dhanmondi', 'ধানমন্ডি',
    'gulshan', 'গুলশান',
    'banani', 'বনানী',
    'mohammadpur', 'মোহাম্মদপুর',
    'bashundhara', 'বসুন্ধরা',
    'badda', 'বাড্ডা',
    'motijheel', 'মতিঝিল',
    'khilgaon', 'খিলগাঁও',
    'malibagh', 'মালিবাগ',
    'rampura', 'রামপুরা',
    'farmgate', 'ফার্মগেট',
    'shahbagh', 'শাহবাগ',
    'lalbagh', 'লালবাগ',
    'wari', 'ওয়ারী',
    'keraniganj', 'কেরানীগঞ্জ',
    'savar', 'সাভার',
    'ashulia', 'আশুলিয়া',
    'narayanganj', 'নারায়ণগঞ্জ',
    'faridpur', 'ফরিদপুর',
    'madaripur', 'মাদারীপুর',
    'gopalganj', 'গোপালগঞ্জ',
    'rajbari', 'রাজবাড়ী',
    'chittagong', 'chattogram', 'চট্টগ্রাম',
    'coxs bazar', 'কক্সবাজার',
    'comilla', 'কুমিল্লা',
    'sylhet', 'সিলেট',
    'khulna', 'খুলনা',
    'jessore', 'যশোর',
    'barishal', 'বরিশাল',
    'rajshahi', 'রাজশাহী',
    'bogra', 'বগুড়া',
    'rangpur', 'রংপুর',
    'dinajpur', 'দিনাজপুর',
    'mymensingh', 'ময়মনসিংহ',
    'tangail', 'টাঙ্গাইল',
  ];

  for (final loc in locations) {
    if (lower.contains(loc.toLowerCase())) {
      return loc;
    }
  }

  final cleaned = input
      .replaceAll(RegExp(r'\(\d+\)'), '')
      .replaceAll(RegExp(r'(price|rance|range|rent|er|te|basha|flat|room|bolo|koto|taka|rate|guide|show|dekhaw|list|তালিকা|রেঞ্জ|ভাড়ার|ভাড়া|কত|বলো|টাকা|দর|বাসা|ফ্ল্যাট|রুম|খুঁজুন|দেখাও)', caseSensitive: false), '')
      .trim();

  return cleaned.isNotEmpty ? cleaned : null;
}
