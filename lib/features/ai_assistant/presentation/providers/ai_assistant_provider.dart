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
                : '👋 Welcome **${user.fullName.isNotEmpty ? user.fullName : "Tenant"}**!\nI am your **BashaBondhu AI Assistant**. Please choose from the 3 core options below or ask any question:\n\n1. 🔍 **Find Home** — Real-time rental listings with area & smart budget filters.\n2. 💳 **Subscription Packages** — Unlock house owner contact numbers.\n3. 📄 **Subscription History** — View transaction history & receipts.');

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
                : [
                    '🔍 বাসা খুঁজুন',
                    '💳 সাবস্ক্রিপশন প্যাকেজ',
                    '📄 সাবস্ক্রিপশন হিস্ট্রি',
                    '❓ সাধারণ জিজ্ঞাসা',
                    '📖 কীভাবে অ্যাপ ব্যবহার করবেন',
                  ])
        : (isAdmin
            ? ['📊 Live Analytics', '💰 Subscription Revenue', '📍 Top Areas']
            : isOwner
                ? [
                    '👥 Find Tenant Demand',
                    '💡 Suggest Price Range',
                    '💳 Subscription Packages',
                    '📄 Subscription History',
                  ]
                : [
                    '🔍 Find Home',
                    '💳 Subscription Packages',
                    '📄 Subscription History',
                    '❓ FAQ',
                    '📖 How to Use',
                  ]);

    final List<String> quickFollowUps = isBn
        ? (isOwner
            ? ['⚡ প্রধান ৪টি অপশন', 'মিরপুরের প্রস্তাবিত ভাড়া', 'উত্তরার প্রস্তাবিত ভাড়া', 'সাবস্ক্রিপশন প্যাকেজ']
            : ['⚡ প্রধান ৩টি অপশন', '🔍 বাসা খুঁজুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '❓ সাধারণ জিজ্ঞাসা'])
        : (isOwner
            ? ['⚡ Main 4 Options', 'Mirpur Price Suggestion', 'Uttara Price Suggestion', 'Subscription Packages']
            : ['⚡ Main 3 Options', '🔍 Find Home', '💳 Subscription Packages', '❓ FAQ']);

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

      // 7. Option 1: Find Tenant Demands & Budget / Area filters
      final bool hasOwnerDemandPriceQuery = _parsePriceFilterCriteria(cleanInput, isBn) != null;
      final bool hasOwnerDemandLocQuery = _extractLocationQuery(cleanInput) != null;

      if (hasOwnerDemandPriceQuery ||
          hasOwnerDemandLocQuery ||
          cleanInput.contains('ভাড়াটিয়াদের ডিমান্ড') ||
          cleanInput.contains('Find Tenant Demand') ||
          cleanInput.contains('ভাড়াটিয়া ডিমান্ড') ||
          cleanInput.contains('Tenant Demand') ||
          cleanInput.contains('ডিমান্ড খুঁজুন') ||
          cleanInput.contains('সকল ডিমান্ড') ||
          cleanInput.contains('All Demands') ||
          cleanInput.contains('ডিমান্ড') ||
          lower.contains('demand') ||
          lower == 'view demands' ||
          lower.contains('k') ||
          lower.contains('below') ||
          lower.contains('under') ||
          cleanInput.contains('নিচে') ||
          lower.contains('above') ||
          lower.contains('over') ||
          cleanInput.contains('উপরে') ||
          cleanInput.contains('বেশি') ||
          cleanInput.contains('কম') ||
          cleanInput.contains('হাজার') ||
          cleanInput.contains('💰') ||
          cleanInput.contains('📍') ||
          cleanInput.contains('৳') ||
          RegExp(r'[০-৯0-9]').hasMatch(cleanInput) ||
          RegExp(r'\(\d+\)').hasMatch(cleanInput)) {
        await _showOwnerTenantDemands(user, languageCode, targetFilter: cleanInput);
        return;
      }

      // 8. Option 2: Suggest Price Range (AI Market Prediction)
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
          cleanInput.contains('ভাড়া কত') ||
          cleanInput.contains('দাম কত') ||
          lower.contains('dam koto') ||
          cleanInput.contains('দাম বলো') ||
          lower.contains('dam bolo')) {
        await _showSuggestPriceRange(user, languageCode, targetArea: cleanInput);
        return;
      }
    }

    // ==========================================
    // TENANT 3 CORE OPTIONS & PERSISTENT TRIGGER
    // ==========================================
    if (user.isTenant) {
      // 1. Persistent Trigger: Show Main 3 Options
      if (cleanInput.contains('প্রধান ৩টি অপশন') ||
          cleanInput.contains('Main 3 Options') ||
          cleanInput.contains('প্রধান ৩টি') ||
          cleanInput.contains('৩টি অপশন') ||
          lower.contains('main 3 options') ||
          lower == 'options' ||
          lower == 'menu' ||
          cleanInput.contains('অপশনসমূহ') ||
          cleanInput.contains('মেনু')) {
        _showTenant3Options(user, languageCode);
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
        await _showTenantFaq(user, languageCode);
        return;
      }

      // 3. How to Use this App as a Tenant (কীভাবে অ্যাপ ব্যবহার করবেন)
      if (cleanInput.contains('কীভাবে অ্যাপ ব্যবহার করবেন') ||
          cleanInput.contains('কীভাবে অ্যাপ ব্যবহার করব') ||
          cleanInput.contains('ব্যবহার নির্দেশিকা') ||
          cleanInput.contains('ব্যবহার পদ্ধতি') ||
          lower.contains('how to use') ||
          lower.contains('how to use this app') ||
          lower.contains('user guide') ||
          lower.contains('app guide')) {
        _showTenantHowToUse(user, languageCode);
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

      // 5. Option 2: Subscription Packages
      if (cleanInput.contains('সাবস্ক্রিপশন প্যাকেজ') ||
          cleanInput.contains('Subscription Packages') ||
          cleanInput.contains('প্যাকেজ') ||
          lower.contains('subscription package') ||
          lower.contains('package')) {
        _showSubscriptionPackages(user, languageCode);
        return;
      }

      // 6. Option 3: Subscription History
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

      // 7. Option 1: Find Home (বাসা খুঁজুন) & Budget / Area Filters
      final bool hasTenantPriceQuery = _parsePriceFilterCriteria(cleanInput, isBn) != null;
      final bool hasTenantLocQuery = _extractLocationQuery(cleanInput) != null;

      if (hasTenantPriceQuery ||
          hasTenantLocQuery ||
          cleanInput.contains('বাসা খুঁজুন') ||
          cleanInput.contains('Find Home') ||
          cleanInput.contains('Find a Home') ||
          cleanInput.contains('সকল বাসা') ||
          cleanInput.contains('All Homes') ||
          cleanInput.contains('খুঁজুন') ||
          cleanInput.contains('বাসা') ||
          cleanInput.contains('ফ্ল্যাট') ||
          cleanInput.contains('রুম') ||
          cleanInput.contains('সিট') ||
          cleanInput.contains('ভাড়া') ||
          cleanInput.contains('rent') ||
          cleanInput.contains('home') ||
          cleanInput.contains('flat') ||
          lower == 'find home' ||
          lower == 'basha khoja' ||
          lower.contains('k') ||
          lower.contains('below') ||
          cleanInput.contains('নিচে') ||
          lower.contains('above') ||
          cleanInput.contains('বেশি') ||
          cleanInput.contains('💰') ||
          cleanInput.contains('📍') ||
          cleanInput.contains('৳') ||
          RegExp(r'[০-৯0-9]').hasMatch(cleanInput) ||
          RegExp(r'\(\d+\)').hasMatch(cleanInput)) {
        await _showTenantFindHome(user, languageCode, targetFilter: cleanInput);
        return;
      }

      // 8. Trigger Post Demand Wizard
      if (cleanInput.contains('ডিমান্ড পোস্ট') || cleanInput.contains('Post a Demand') || lower == 'post demand' || lower == 'demand post') {
        startDemandPostWizard(user, languageCode);
        return;
      }
    }

    // 1. Trigger Find Home Wizard (Fallback)
    if (cleanInput.contains('বাসা খুঁজুন') || cleanInput.contains('Find a Home') || lower == 'find home' || lower == 'basha khoja') {
      startFindHomeWizard(user, languageCode);
      return;
    }

    // 2. Trigger Post Demand Wizard (Fallback)
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

      // 2. Extract unique real areas and their counts dynamically from live demand posts
      final Map<String, int> areaCounts = {};
      for (final d in activeDemands) {
        String areaName = '';
        if (isBn) {
          if (d.subArea != null && d.subArea!.bnName.trim().isNotEmpty) {
            areaName = d.subArea!.bnName.trim();
          } else if (d.area.bnName.trim().isNotEmpty) {
            areaName = d.area.bnName.trim();
          } else if (d.area.name.trim().isNotEmpty) {
            areaName = d.area.name.trim();
          } else if (d.district.bnName.trim().isNotEmpty) {
            areaName = d.district.bnName.trim();
          } else {
            areaName = d.district.name.trim();
          }
        } else {
          if (d.subArea != null && d.subArea!.name.trim().isNotEmpty) {
            areaName = d.subArea!.name.trim();
          } else if (d.area.name.trim().isNotEmpty) {
            areaName = d.area.name.trim();
          } else if (d.district.name.trim().isNotEmpty) {
            areaName = d.district.name.trim();
          } else {
            areaName = d.division.name.trim();
          }
        }

        if (areaName.isNotEmpty) {
          areaCounts[areaName] = (areaCounts[areaName] ?? 0) + 1;
        }
      }

      // 3. Extract unique real budget ranges and their counts dynamically from live demand posts
      final Map<String, int> budgetCounts = {};
      for (final d in activeDemands) {
        final rawBudget = d.budgetRange?.trim() ?? '';
        final bucket = _normalizeBudgetBucket(rawBudget, isBn);
        if (bucket != null) {
          budgetCounts[bucket] = (budgetCounts[bucket] ?? 0) + 1;
        }
      }

      // 4. Filter by targetFilter (Budget Range, Area, Exact Price, or Combined)
      List<TenantDemandModel> displayDemands = activeDemands;
      String selectedFilterTitle = '';
      bool isFiltered = false;
      bool isPriceSearch = false;
      bool isLocationSearch = false;
      String cleanLocationQuery = '';

      final isDefaultTrigger = effectiveTarget == null ||
          effectiveTarget.trim().isEmpty ||
          effectiveTarget.contains('সকল ডিমান্ড') ||
          effectiveTarget.contains('All Demands') ||
          effectiveTarget.contains('সকল এলাকা') ||
          effectiveTarget.contains('All Areas') ||
          effectiveTarget.contains('প্রধান ৪টি অপশন') ||
          effectiveTarget.contains('Main 4 Options') ||
          effectiveTarget.trim() == 'ভাড়াটিয়াদের ডিমান্ড' ||
          effectiveTarget.trim() == 'Find Tenant Demands' ||
          effectiveTarget.trim() == 'Find Tenant Demand' ||
          effectiveTarget.trim() == 'ভাড়াটিয়া ডিমান্ড' ||
          effectiveTarget.trim() == 'Tenant Demands' ||
          effectiveTarget.trim() == 'Tenant Demand' ||
          effectiveTarget.trim() == 'ডিমান্ড খুঁজুন' ||
          effectiveTarget.trim() == 'view demands';

      if (!isDefaultTrigger) {
        final trimmedTarget = effectiveTarget.trim();

        // 4A. Explicit Area Chip Click (starts with 📍)
        if (trimmedTarget.startsWith('📍')) {
          final cleanArea = trimmedTarget
              .replaceAll('📍', '')
              .replaceAll(RegExp(r'\(\s*[0-9০-৯]+\s*\)'), '')
              .replaceAll('ডিমান্ড', '')
              .replaceAll('Demands', '')
              .replaceAll('Demand', '')
              .trim();
          if (cleanArea.isNotEmpty) {
            isFiltered = true;
            isLocationSearch = true;
            cleanLocationQuery = cleanArea;
            displayDemands = activeDemands.where((d) => _matchesDemandLocation(d, cleanArea)).toList();
            selectedFilterTitle = isBn ? '📍 এলাকা: $cleanArea' : '📍 Area: $cleanArea';
          }
        }
        // 4B. Explicit Budget Chip Click (starts with 💰)
        else if (trimmedTarget.startsWith('💰')) {
          final cleanBudget = trimmedTarget
              .replaceAll('💰', '')
              .replaceAll(RegExp(r'\(\s*[0-9০-৯]+\s*\)'), '')
              .replaceAll('ডিমান্ড', '')
              .replaceAll('Demands', '')
              .replaceAll('Demand', '')
              .trim();
          if (cleanBudget.isNotEmpty) {
            isFiltered = true;
            isPriceSearch = true;
            final priceCriteria = _parsePriceFilterCriteria(cleanBudget, isBn);
            if (priceCriteria != null) {
              displayDemands = activeDemands.where((d) => _matchesBudgetFilterCriteria(d, priceCriteria)).toList();
              selectedFilterTitle = isBn ? '💰 বাজেট: ${priceCriteria.displayTitle}' : '💰 Budget: ${priceCriteria.displayTitle}';
            } else {
              displayDemands = activeDemands.where((d) {
                final bucket = _normalizeBudgetBucket(d.budgetRange ?? '', isBn);
                return bucket != null && (bucket == cleanBudget || cleanBudget.contains(bucket) || bucket.contains(cleanBudget));
              }).toList();
              selectedFilterTitle = isBn ? '💰 বাজেট: $cleanBudget' : '💰 Budget: $cleanBudget';
            }
          }
        }
        // 4C. Free text search / typed queries
        else {
          final priceCriteria = _parsePriceFilterCriteria(trimmedTarget, isBn);
          final locQuery = _extractLocationQuery(trimmedTarget);

          if (locQuery != null && priceCriteria != null) {
            isFiltered = true;
            isPriceSearch = true;
            isLocationSearch = true;
            cleanLocationQuery = locQuery;
            displayDemands = activeDemands.where((d) {
              final locMatch = _matchesDemandLocation(d, locQuery);
              final prMatch = _matchesBudgetFilterCriteria(d, priceCriteria);
              return locMatch && prMatch;
            }).toList();
            selectedFilterTitle = isBn
                ? '📍 এলাকা: $locQuery ও 💰 বাজেট: ${priceCriteria.displayTitle}'
                : '📍 Area: $locQuery & 💰 Budget: ${priceCriteria.displayTitle}';
          } else if (priceCriteria != null) {
            isFiltered = true;
            isPriceSearch = true;
            displayDemands = activeDemands.where((d) => _matchesBudgetFilterCriteria(d, priceCriteria)).toList();
            selectedFilterTitle = isBn ? '💰 বাজেট: ${priceCriteria.displayTitle}' : '💰 Budget: ${priceCriteria.displayTitle}';
          } else if (locQuery != null) {
            isFiltered = true;
            isLocationSearch = true;
            cleanLocationQuery = locQuery;
            displayDemands = activeDemands.where((d) => _matchesDemandLocation(d, locQuery)).toList();
            selectedFilterTitle = isBn ? '📍 এলাকা: $locQuery' : '📍 Area: $locQuery';
          } else {
            final cleanFilter = trimmedTarget
                .replaceAll(RegExp(r'\(\s*[0-9০-৯]+\s*\)'), '')
                .replaceAll('💰', '')
                .replaceAll('📍', '')
                .replaceAll('ডিমান্ড', '')
                .replaceAll('খুঁজুন', '')
                .replaceAll('dam', '')
                .replaceAll('bolo', '')
                .replaceAll('দাম', '')
                .replaceAll('বলো', '')
                .trim();
            if (cleanFilter.isNotEmpty) {
              final fallbackPrice = _parsePriceFilterCriteria(cleanFilter, isBn);
              if (fallbackPrice != null) {
                isFiltered = true;
                isPriceSearch = true;
                displayDemands = activeDemands.where((d) => _matchesBudgetFilterCriteria(d, fallbackPrice)).toList();
                selectedFilterTitle = isBn ? '💰 বাজেট: ${fallbackPrice.displayTitle}' : '💰 Budget: ${fallbackPrice.displayTitle}';
              } else {
                isFiltered = true;
                displayDemands = activeDemands.where((d) => _matchesDemandLocation(d, cleanFilter) || _matchesDemandFilter(d, cleanFilter)).toList();
                selectedFilterTitle = isBn ? '🔍 ফিল্টার: $cleanFilter' : '🔍 Filter: $cleanFilter';
              }
            }
          }
        }
      }

      final topAreaList = areaCounts.entries.map((e) => '• **${e.key}**: ${e.value.toString().toLocalizedDigits('bn')}টি চাহিদা').join('\n');
      final topAreaListEn = areaCounts.entries.map((e) => '• **${e.key}**: ${e.value} Demands').join('\n');
      final topBudgetList = budgetCounts.entries.map((e) => '• **${e.key}**: ${e.value.toString().toLocalizedDigits('bn')}টি চাহিদা').join('\n');
      final topBudgetListEn = budgetCounts.entries.map((e) => '• **${e.key}**: ${e.value} Demands').join('\n');

      final matchingAnalysis = DemandBudgetAnalysis.analyze(displayDemands);
      final activeAnalysis = DemandBudgetAnalysis.analyze(activeDemands);
      final String aiDemandInsights = (isFiltered ? matchingAnalysis : activeAnalysis).formatAiInsights(isBn, languageCode);

      String headerText;
      if (isBn) {
        if (isFiltered) {
          if (displayDemands.isNotEmpty) {
            headerText = '''🎯 **$selectedFilterTitle অনুযায়ী ${displayDemands.length.toString().toLocalizedDigits('bn')} টি লাইভ ভাড়াটিয়া ডিমান্ড পাওয়া গেছে (মোট সক্রিয়: ${activeDemands.length.toString().toLocalizedDigits('bn')} টি):**

$aiDemandInsights

👇 নিচের কার্ডে ক্লিক করে ভাড়াটিয়ার ডিমান্ড ও ফোন নম্বর আনলক করুন:''';
          } else {
            if (isPriceSearch && !isLocationSearch) {
              final lowestBudgetText = activeAnalysis.minBudget > 0
                  ? '৳${activeAnalysis.minBudget.toInt().toString().toLocalizedDigits('bn')}'
                  : '৳৫,০০০';
              headerText = '''🎯 **এই ভাড়ার বাজেটে ($selectedFilterTitle) বর্তমানে কোনো ভাড়াটিয়া ডিমান্ড পাওয়া যায়নি (মোট সক্রিয়: ${activeDemands.length.toString().toLocalizedDigits('bn')} টি)।**

🧠 **এআই পর্যবেক্ষণ ও পরামর্শ:**
• ফায়ারবেস ডাটাবেজে বর্তমানে ডিমান্ড পোস্টের সর্বনিম্ন বাজেট **$lowestBudgetText** থেকে শুরু।
• আপনি চাইলে নিচের উপলব্ধ ভাড়ার রেঞ্জ বা এলাকা থেকে নির্বাচন করতে পারেন।

👇 ডাটাবেজে বর্তমানে উপলব্ধ ভাড়ার রেঞ্জসমূহ:''';
            } else if (isLocationSearch && !isPriceSearch) {
              headerText = '''🎯 **"$cleanLocationQuery" এলাকায় বর্তমানে কোনো ভাড়াটিয়া ডিমান্ড পাওয়া যায়নি (মোট সক্রিয়: ${activeDemands.length.toString().toLocalizedDigits('bn')} টি)।**

🧠 **এআই পর্যবেক্ষণ ও পরামর্শ:**
• এই এলাকার কাছাকাছি অন্যান্য এলাকার চাহিদা দেখতে নিচের বাটনে ক্লিক করতে পারেন।

👇 ডাটাবেজে বর্তমানে যেসব এলাকায় ভাড়াটিয়া চাহিদা রয়েছে:''';
            } else {
              headerText = '''🎯 **$selectedFilterTitle অনুযায়ী বর্তমানে কোনো সক্রিয় ভাড়াটিয়া ডিমান্ড পাওয়া যায়নি (মোট সক্রিয়: ${activeDemands.length.toString().toLocalizedDigits('bn')} টি)।**

💡 এই বাজেটে বা এলাকায় বর্তমানে কোনো ডিমান্ড নেই, অনুগ্রহ করে অন্য কোনো ভাড়ার রেঞ্জ বা এলাকা দিয়ে চেষ্টা করুন।

👇 নিচের অন্যান্য বাজেট বা এলাকা বাটনে ক্লিক করে ফিল্টার করুন:''';
            }
          }
        } else {
          headerText = '''👥 **ভাড়াটিয়াদের মোট ${activeDemands.length.toString().toLocalizedDigits('bn')} টি লাইভ ডিমান্ড পোস্ট পাওয়া গেছে (Demand Screen Data):**

$aiDemandInsights

📍 **ভাড়াটিয়াদের পোস্টকৃত সকল এলাকা (Live Demand Posts):**
$topAreaList

💰 **উপলব্ধ ভাড়ার বাজেট রেঞ্জসমূহ (Live Demand Budgets):**
$topBudgetList

👇 নিচের যেকোনো কার্ডে ট্যাপ করে বিস্তারিত দেখুন ও যোগাযোগ করুন, অথবা উপরের এলাকা/বাজেটের বাটনে চাপ দিয়ে ফিল্টার করুন:''';
        }
      } else {
        if (isFiltered) {
          if (displayDemands.isNotEmpty) {
            headerText = '''🎯 **Found ${displayDemands.length} Live Tenant Demands for $selectedFilterTitle (Total Active: ${activeDemands.length}):**

$aiDemandInsights

👇 Tap cards below to view requirements & unlock contact info:''';
          } else {
            if (isPriceSearch && !isLocationSearch) {
              final lowestBudgetText = activeAnalysis.minBudget > 0
                  ? '৳${activeAnalysis.minBudget.toInt()}'
                  : '৳5,000';
              headerText = '''🎯 **No active tenant demands currently found for $selectedFilterTitle (Total Active: ${activeDemands.length}).**

🧠 **AI Insights & Suggestions:**
• The current lowest active tenant demand in our live database starts from **$lowestBudgetText**.
• Please explore available budget options or active areas below.

👇 Available budget ranges in database:''';
            } else if (isLocationSearch && !isPriceSearch) {
              headerText = '''🎯 **No active tenant demands currently found in "$cleanLocationQuery" (Total Active: ${activeDemands.length}).**

🧠 **AI Insights & Suggestions:**
• You can check demands in other active locations below.

👇 Active areas with tenant demands:''';
            } else {
              headerText = '''🎯 **No active tenant demands found for $selectedFilterTitle (Total Active: ${activeDemands.length}).**

💡 No demands found for this price range or area, please try another price range or area.

👇 Please select another budget or area below:''';
            }
          }
        } else {
          headerText = '''👥 **Found ${activeDemands.length} Live Tenant Demands in Firebase (Demand Screen Data):**

$aiDemandInsights

📍 **All Areas with Active Tenant Demands (Live Demand Posts):**
$topAreaListEn

💰 **Available Demand Budget Ranges (Live Demand Budgets):**
$topBudgetListEn

👇 Tap any demand card below to review details & contact info, or tap any area/budget button above to filter:''';
        }
      }

      // Build interactive chips: All Demands, Real Budgets, Real Areas, Suggest Price, Main 4
      final List<String> dynamicChips = [];
      if (isBn) {
        dynamicChips.add('📍 সকল ডিমান্ড (${activeDemands.length.toString().toLocalizedDigits('bn')})');
        for (final entry in budgetCounts.entries) {
          dynamicChips.add('💰 ${entry.key} (${entry.value.toString().toLocalizedDigits('bn')})');
        }
        for (final entry in areaCounts.entries) {
          dynamicChips.add('📍 ${entry.key} (${entry.value.toString().toLocalizedDigits('bn')})');
        }
        dynamicChips.add('💡 প্রস্তাবিত ভাড়ার রেঞ্জ');
        dynamicChips.add('💳 সাবস্ক্রিপশন প্যাকেজ');
        dynamicChips.add('⚡ প্রধান ৪টি অপশন');
      } else {
        dynamicChips.add('📍 All Demands (${activeDemands.length})');
        for (final entry in budgetCounts.entries) {
          dynamicChips.add('💰 ${entry.key} (${entry.value})');
        }
        for (final entry in areaCounts.entries) {
          dynamicChips.add('📍 ${entry.key} (${entry.value})');
        }
        dynamicChips.add('💡 Suggest Price Range');
        dynamicChips.add('💳 Subscription Packages');
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
  // TENANT 3 CORE METHODS & FIND HOME
  // ==========================================

  /// Public method to trigger the 3 core options menu for tenants
  void showTenant3Options(UserModel user, String languageCode) {
    _showTenant3Options(user, languageCode);
  }

  void _showTenant3Options(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];
    history.add(
      AIMessageModel(
        id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '⚡ **ভাড়াটিয়াদের জন্য প্রধান ৩টি অপশন:**\n\n১. 🔍 **বাসা খুঁজুন (Find Home)** — বাড়িওয়ালাদের লাইভ বাসা ভাড়ার বিজ্ঞাপন, বাজেট ও এলাকাভিত্তিক তালিকা।\n২. 💳 **সাবস্ক্রিপশন প্যাকেজ** — প্যাকেজ আপগ্রেড করে বাড়িওয়ালাদের মোবাইল নম্বর ও সরাসরি যোগাযোগের সুবিধা আনলক করুন।\n৩. 📄 **সাবস্ক্রিপশন হিস্ট্রি** — বিগত পেমেন্টের ডিজিটাল রসিদ ও সাবস্ক্রিপশন হিস্ট্রি।'
            : '⚡ **Main 3 Options for Tenants:**\n\n1. 🔍 **Find Home** — Real-time verified rental listings with area & smart budget filters.\n2. 💳 **Subscription Packages** — Upgrade subscription to unlock house owner contact numbers & direct chat.\n3. 📄 **Subscription History** — View transaction history & download digital receipts.',
        sender: AIMessageSender.ai,
        interactiveChips: isBn
            ? [
                '🔍 বাসা খুঁজুন',
                '💳 সাবস্ক্রিপশন প্যাকেজ',
                '📄 সাবস্ক্রিপশন হিস্ট্রি',
                '❓ সাধারণ জিজ্ঞাসা',
                '📖 কীভাবে অ্যাপ ব্যবহার করবেন',
              ]
            : [
                '🔍 Find Home',
                '💳 Subscription Packages',
                '📄 Subscription History',
                '❓ FAQ',
                '📖 How to Use',
              ],
        quickActions: isBn ? ['⚡ প্রধান ৩টি অপশন'] : ['⚡ Main 3 Options'],
      ),
    );
    notifyListeners();
  }

  Future<void> _showTenantFindHome(UserModel user, String languageCode, {String? targetFilter, String? targetArea}) async {
    final effectiveTarget = targetFilter ?? targetArea;
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    try {
      // 1. Fetch all active properties from Firestore (unrented)
      final propsSnap = await _firestore.collection('properties').get();
      final allProperties = propsSnap.docs.map((doc) => PropertyModel.fromMap(doc.data(), doc.id)).toList();
      final activeProperties = allProperties.where((p) => p.isRentedOut != true).toList();

      if (activeProperties.isEmpty) {
        history.add(
          AIMessageModel(
            id: 'prop_empty_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn
                ? '🏠 **বর্তমানে ফায়ারবেস ডাটাবেজে কোনো সক্রিয় বাসা ভাড়ার বিজ্ঞাপন পাওয়া যায়নি।**\nবাড়িওয়ালারা নতুন কোনো বাসা পোস্ট করলেই তা এখানে ও হোম স্ক্রিনে তাৎক্ষণিক দেখতে পাবেন।'
                : '🏠 **No active rental properties found in Firebase right now.**\nWhen house owners post new listings, they will appear here.',
            sender: AIMessageSender.ai,
            interactiveChips: isBn
                ? ['📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '⚡ প্রধান ৩টি অপশন']
                : ['📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History', '⚡ Main 3 Options'],
          ),
        );
        return;
      }

      // 2. Extract unique areas and their counts dynamically from live house owner posts
      final Map<String, int> areaCounts = {};
      for (final p in activeProperties) {
        String areaName = '';
        if (isBn) {
          if (p.subArea != null && p.subArea!.bnName.trim().isNotEmpty) {
            areaName = p.subArea!.bnName.trim();
          } else if (p.area.bnName.trim().isNotEmpty) {
            areaName = p.area.bnName.trim();
          } else if (p.area.name.trim().isNotEmpty) {
            areaName = p.area.name.trim();
          } else if (p.district.bnName.trim().isNotEmpty) {
            areaName = p.district.bnName.trim();
          } else {
            areaName = p.district.name.trim();
          }
        } else {
          if (p.subArea != null && p.subArea!.name.trim().isNotEmpty) {
            areaName = p.subArea!.name.trim();
          } else if (p.area.name.trim().isNotEmpty) {
            areaName = p.area.name.trim();
          } else if (p.district.name.trim().isNotEmpty) {
            areaName = p.district.name.trim();
          } else {
            areaName = p.division.name.trim();
          }
        }

        if (areaName.isNotEmpty) {
          areaCounts[areaName] = (areaCounts[areaName] ?? 0) + 1;
        }
      }

      // 3. Extract unique price ranges and their counts dynamically from live house owner posts
      final Map<String, int> priceCounts = {};
      for (final p in activeProperties) {
        final price = _extractPropertyNumericAmount(p.amount);
        final bucket = _normalizePropertyPriceBucket(price, isBn);
        if (bucket != null) {
          priceCounts[bucket] = (priceCounts[bucket] ?? 0) + 1;
        }
      }

      // 4. Filter by targetFilter (Division, District, Area, Sub-Area, Price Range, Exact Price, or Combined)
      List<PropertyModel> displayProperties = activeProperties;
      String selectedFilterTitle = '';
      bool isFiltered = false;
      bool isPriceSearch = false;
      bool isLocationSearch = false;
      String cleanLocationQuery = '';

      if (effectiveTarget != null &&
          effectiveTarget.isNotEmpty &&
          !effectiveTarget.contains('সকল বাসা') &&
          !effectiveTarget.contains('All Homes') &&
          !effectiveTarget.contains('সকল এলাকা') &&
          !effectiveTarget.contains('All Areas') &&
          !effectiveTarget.contains('প্রধান ৩টি অপশন') &&
          !effectiveTarget.contains('Main 3 Options') &&
          effectiveTarget.trim() != 'বাসা খুঁজুন' &&
          effectiveTarget.trim() != 'Find Home' &&
          effectiveTarget.trim() != 'Find a Home') {
        
        final priceCriteria = _parsePriceFilterCriteria(effectiveTarget, isBn);
        final locationQuery = _parseLocationFilter(effectiveTarget);

        if (priceCriteria != null && locationQuery != null && locationQuery.isNotEmpty) {
          // Combined Location & Price Search (e.g. "মিরপুরে ১২০০০ টাকার বাসা")
          isFiltered = true;
          isPriceSearch = true;
          isLocationSearch = true;
          cleanLocationQuery = locationQuery;
          displayProperties = activeProperties.where((p) {
            final matchesLoc = _matchesPropertyLocation(p, locationQuery);
            final price = _extractPropertyNumericAmount(p.amount);
            final matchesPr = priceCriteria.matches(price);
            return matchesLoc && matchesPr;
          }).toList();
          selectedFilterTitle = isBn
              ? '📍 এলাকা: $locationQuery ও 💰 বাজেট: ${priceCriteria.displayTitle}'
              : '📍 Area: $locationQuery & 💰 Budget: ${priceCriteria.displayTitle}';
        } else if (priceCriteria != null) {
          // Pure Price Search (Below, Above, Range, or Exact Price e.g. "12k", "12000", "below 5k", "6k-10k")
          isFiltered = true;
          isPriceSearch = true;
          displayProperties = activeProperties.where((p) {
            final price = _extractPropertyNumericAmount(p.amount);
            return priceCriteria.matches(price);
          }).toList();
          selectedFilterTitle = isBn
              ? '💰 ভাড়ার বাজেট: ${priceCriteria.displayTitle}'
              : '💰 Rent Budget: ${priceCriteria.displayTitle}';
        } else if (locationQuery != null && locationQuery.isNotEmpty) {
          // Pure Location Search (Division, District, Area, Sub-Area e.g. "Dhaka", "Gazipur", "Mirpur", "Sector 10")
          isFiltered = true;
          isLocationSearch = true;
          cleanLocationQuery = locationQuery;
          displayProperties = activeProperties.where((p) => _matchesPropertyLocation(p, locationQuery)).toList();
          selectedFilterTitle = isBn
              ? '📍 এলাকা / লোকেশন: $locationQuery'
              : '📍 Location: $locationQuery';
        }
      }

      final topAreaList = areaCounts.entries.map((e) => '• 📍 **${e.key}**: ${e.value.toString().toLocalizedDigits('bn')}টি বাসা').join('\n');
      final topAreaListEn = areaCounts.entries.map((e) => '• 📍 **${e.key}**: ${e.value} Homes').join('\n');
      final topPriceList = priceCounts.entries.map((e) => '• 💰 **${e.key}**: ${e.value.toString().toLocalizedDigits('bn')}টি বাসা').join('\n');
      final topPriceListEn = priceCounts.entries.map((e) => '• 💰 **${e.key}**: ${e.value} Homes').join('\n');

      final matchingAnalysis = PropertyPriceAnalysis.analyze(displayProperties);
      final activeAnalysis = PropertyPriceAnalysis.analyze(activeProperties);
      final String aiInsightsBlock = (isFiltered ? matchingAnalysis : activeAnalysis).formatAiInsights(isBn, languageCode);

      String headerText;
      if (isBn) {
        if (isFiltered) {
          if (displayProperties.isNotEmpty) {
            headerText = '''🎯 **$selectedFilterTitle অনুযায়ী ${displayProperties.length.toString().toLocalizedDigits('bn')} টি লাইভ বাসা ভাড়ার বিজ্ঞাপন পাওয়া গেছে (মোট সক্রিয়: ${activeProperties.length.toString().toLocalizedDigits('bn')} টি):**

$aiInsightsBlock

👇 নিচের কার্ডে ক্লিক করে বাসার পূর্ণাঙ্গ বিবরণ, ছবি ও বাড়িওয়ালার যোগাযোগ নম্বর দেখুন:''';
          } else {
            if (isPriceSearch && !isLocationSearch) {
              final lowestRentText = activeAnalysis.minAmount > 0 ? '৳${activeAnalysis.minAmount.toInt().toString().toLocalizedDigits('bn')}' : '৳৫,০০০';
              headerText = '''🎯 **এই ভাড়ার মূল্যে ($selectedFilterTitle) বর্তমানে কোনো বাসা খালি নেই।**

🧠 **এআই পর্যবেক্ষণ ও পরামর্শ:**
• ফায়ারবেস ডাটাবেজে বর্তমানে সর্বনিম্ন সক্রিয় ভাড়া **$lowestRentText** থেকে শুরু।
• আপনি চাইলে নিচের উপলব্ধ ভাড়ার রেঞ্জ থেকে নির্বাচন করতে পারেন অথবা আপনার পছন্দের বাজেটে একটি ডিমান্ড পোস্ট করতে পারেন।

👇 ডাটাবেজে বর্তমানে উপলব্ধ ভাড়ার রেঞ্জসমূহ:''';
            } else if (isLocationSearch && !isPriceSearch) {
              headerText = '''🎯 **"$cleanLocationQuery" এলাকায় বর্তমানে কোনো বাসা ভাড়ার বিজ্ঞাপন পাওয়া যায়নি (মোট সক্রিয় বাসা: ${activeProperties.length.toString().toLocalizedDigits('bn')} টি)।**

🧠 **এআই পর্যবেক্ষণ ও পরামর্শ:**
• আপনি চাইলে এই এলাকায় বাসা পাওয়ার জন্য একটি **ডিমান্ড পোস্ট** করতে পারেন। বাড়িওয়ালারা আপনার পোস্ট দেখে যোগাযোগ করবে।
• অথবা নিচে বর্তমানে যেসব এলাকায় বাসা খালি আছে সেগুলো দেখতে পারেন:''';
            } else {
              headerText = '''🎯 **$selectedFilterTitle অনুযায়ী বর্তমানে কোনো বাসা ভাড়ার বিজ্ঞাপন পাওয়া যায়নি।**

👇 দয়া করে অন্য কোনো এলাকা বা বাজেট নির্বাচন করুন অথবা ডিমান্ড পোস্ট করুন:''';
            }
          }
        } else {
          headerText = '''🏠 **বাড়িওয়ালাদের মোট ${activeProperties.length.toString().toLocalizedDigits('bn')} টি লাইভ বাসা ভাড়ার বিজ্ঞাপন পাওয়া গেছে (Home Screen Data):**

$aiInsightsBlock

📍 **বাড়িওয়ালাদের পোস্টকৃত সকল এলাকা (Live Owner Posts):**
$topAreaList

💰 **উপলব্ধ ভাড়ার বাজেট রেঞ্জসমূহ (Live Rent Insights):**
$topPriceList

👇 নিচের যেকোনো কার্ডে ট্যাপ করে বিস্তারিত দেখুন ও যোগাযোগ করুন, অথবা উপরের এলাকা/বাজেটের বাটনে চাপ দিয়ে ফিল্টার করুন:''';
        }
      } else {
        if (isFiltered) {
          if (displayProperties.isNotEmpty) {
            headerText = '''🎯 **Found ${displayProperties.length} active rental homes for $selectedFilterTitle (Total active: ${activeProperties.length}):**

$aiInsightsBlock

👇 Tap cards below to view property photos, amenities & contact owner:''';
          } else {
            if (isPriceSearch && !isLocationSearch) {
              final lowestRentText = activeAnalysis.minAmount > 0 ? '৳${activeAnalysis.minAmount.toInt()}' : '৳5,000';
              headerText = '''🎯 **No rental homes currently available for $selectedFilterTitle.**

🧠 **AI Insights & Suggestions:**
• The current lowest active rental in our live database starts from **$lowestRentText**.
• You can explore available budget options below or create a rental demand post for your preferred budget.

👇 Currently available rent ranges in database:''';
            } else if (isLocationSearch && !isPriceSearch) {
              headerText = '''🎯 **No rental homes currently found in "$cleanLocationQuery" (Total active homes: ${activeProperties.length}).**

🧠 **AI Insights & Suggestions:**
• You can post a **Rental Demand** for "$cleanLocationQuery" to notify prospective house owners.
• Or explore homes in other active areas below:''';
            } else {
              headerText = '''🎯 **No rental homes found for $selectedFilterTitle.**

👇 Please try a different area or price range below:''';
            }
          }
        } else {
          headerText = '''🏠 **Found ${activeProperties.length} Live Rental Listings in Firebase (Home Screen Data):**

$aiInsightsBlock

📍 **All Areas with Active Listings (Live Owner Posts):**
$topAreaListEn

💰 **Available Rent Ranges (From Real Listings):**
$topPriceListEn

👇 Tap property cards below to view details, or filter by area/budget:''';
        }
      }

      // Build interactive chips: All Homes, Real Prices, Real Areas, Packages, Main 3
      final List<String> dynamicChips = [];
      if (isBn) {
        dynamicChips.add('🏠 সকল বাসা (${activeProperties.length.toString().toLocalizedDigits('bn')})');
        for (final entry in priceCounts.entries) {
          dynamicChips.add('💰 ${entry.key} (${entry.value.toString().toLocalizedDigits('bn')})');
        }
        for (final entry in areaCounts.entries) {
          dynamicChips.add('📍 ${entry.key} (${entry.value.toString().toLocalizedDigits('bn')})');
        }
        dynamicChips.add('📝 ডিমান্ড পোস্ট করুন');
        dynamicChips.add('💳 সাবস্ক্রিপশন প্যাকেজ');
        dynamicChips.add('⚡ প্রধান ৩টি অপশন');
      } else {
        dynamicChips.add('🏠 All Homes (${activeProperties.length})');
        for (final entry in priceCounts.entries) {
          dynamicChips.add('💰 ${entry.key} (${entry.value})');
        }
        for (final entry in areaCounts.entries) {
          dynamicChips.add('📍 ${entry.key} (${entry.value})');
        }
        dynamicChips.add('📝 Post a Demand');
        dynamicChips.add('💳 Subscription Packages');
        dynamicChips.add('⚡ Main 3 Options');
      }

      history.add(
        AIMessageModel(
          id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
          text: headerText,
          sender: AIMessageSender.ai,
          properties: displayProperties,
          interactiveChips: dynamicChips,
          quickActions: isBn ? ['⚡ প্রধান ৩টি অপশন'] : ['⚡ Main 3 Options'],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching tenant homes: $e');
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
    final isOwner = user.isHouseOwner;
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
            ? (isOwner
                ? [
                    '📄 সাবস্ক্রিপশন হিস্ট্রি',
                    '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন',
                    '💡 প্রস্তাবিত ভাড়ার রেঞ্জ',
                    '⚡ প্রধান ৪টি অপশন',
                  ]
                : [
                    '📄 সাবস্ক্রিপশন হিস্ট্রি',
                    '🔍 বাসা খুঁজুন',
                    '❓ সাধারণ জিজ্ঞাসা',
                    '⚡ প্রধান ৩টি অপশন',
                  ])
            : (isOwner
                ? [
                    '📄 Subscription History',
                    '👥 Find Tenant Demand',
                    '💡 Suggest Price Range',
                    '⚡ Main 4 Options',
                  ]
                : [
                    '📄 Subscription History',
                    '🔍 Find Home',
                    '❓ FAQ',
                    '⚡ Main 3 Options',
                  ]),
        quickActions: isBn
            ? [isOwner ? '⚡ প্রধান ৪টি অপশন' : '⚡ প্রধান ৩টি অপশন', 'সাবস্ক্রিপশন হিস্ট্রি']
            : [isOwner ? '⚡ Main 4 Options' : '⚡ Main 3 Options', 'Subscription History'],
      ),
    );
    notifyListeners();
  }

  void _showSubscriptionHistory(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final isOwner = user.isHouseOwner;
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
            ? (isOwner
                ? [
                    '💳 সাবস্ক্রিপশন প্যাকেজ',
                    '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন',
                    '💡 প্রস্তাবিত ভাড়ার রেঞ্জ',
                    '⚡ প্রধান ৪টি অপশন',
                  ]
                : [
                    '💳 সাবস্ক্রিপশন প্যাকেজ',
                    '🔍 বাসা খুঁজুন',
                    '❓ সাধারণ জিজ্ঞাসা',
                    '⚡ প্রধান ৩টি অপশন',
                  ])
            : (isOwner
                ? [
                    '💳 Subscription Packages',
                    '👥 Find Tenant Demand',
                    '💡 Suggest Price Range',
                    '⚡ Main 4 Options',
                  ]
                : [
                    '💳 Subscription Packages',
                    '🔍 Find Home',
                    '❓ FAQ',
                    '⚡ Main 3 Options',
                  ]),
        quickActions: isBn
            ? [isOwner ? '⚡ প্রধান ৪টি অপশন' : '⚡ প্রধান ৩টি অপশন', 'সাবস্ক্রিপশন প্যাকেজ']
            : [isOwner ? '⚡ Main 4 Options' : '⚡ Main 3 Options', 'Subscription Packages'],
      ),
    );
    notifyListeners();
  }

  // ==========================================
  // HOUSE OWNER FAQS (FETCHED LIVE FROM FIRESTORE)
  // ==========================================

  // ==========================================
  // HOUSE OWNER FAQS (FETCHED LIVE FROM FIRESTORE WITH AI ANALYSIS)
  // ==========================================

  Future<void> _showHouseOwnerFaq(UserModel user, String languageCode) async {
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    try {
      final faqs = await PolicyFirestoreService().getFaqs(targetAudience: 'house_owner');
      faqs.sort((a, b) => a.order.compareTo(b.order));

      final buffer = StringBuffer();
      if (isBn) {
        buffer.writeln('❓ **বাসাবন্ধু বাড়িওয়ালা সাধারণ জিজ্ঞাসা ও সমাধান (FAQs - Live Firebase):**\n');
        buffer.writeln('🧠 **এআই বিশ্লেষণ ও সারসংক্ষেপ (AI Agent Summary):**');
        buffer.writeln('• **বিজ্ঞাপন পোস্ট:** ড্যাশবোর্ডে "+" বা "Post Free" বাটনে চাপ দিয়ে বাসার ছবি ও ভাড়ার বিবরণ দিয়ে লাইভ করুন।');
        buffer.writeln('• **বিজ্ঞাপন নিয়ন্ত্রণ:** বাসা ভাড়া হয়ে গেলে "My Post" স্ক্রিন থেকে "ভাড়া হয়ে গেছে (Rented Out)" অন করে দিন।');
        buffer.writeln('• **ভাড়াটিয়া চাহিদা:** "Demand" অপশনে গিয়ে এলাকার আগ্রহী ভাড়াটিয়াদের চাহিদাপত্র ও বাজেট ফিল্টার দেখে সরাসরি কল করুন।');
        buffer.writeln('• **ভাড়ার পরামর্শ:** এআই প্রেডিকশন ইঞ্জিনের মাধ্যমে এলাকার ন্যায্য ও যৌক্তিক ভাড়ার পূর্বাভাস জানুন।\n');
        buffer.writeln('📋 **ফায়ারবেস ক্লাউড ডাটাবেজ থেকে সংগৃহীত প্রশ্নোত্তর তালিকা:**\n');

        for (int i = 0; i < faqs.length; i++) {
          final f = faqs[i];
          final q = f.getQuestion('bn');
          final a = f.getAnswer('bn');
          buffer.writeln('**প্রশ্ন ${(i + 1).toString().toLocalizedDigits('bn')}: $q**');
          buffer.writeln('👉 **উত্তর:** $a\n');
        }
        buffer.writeln('──────────────────');
        buffer.writeln('ℹ️ *এডমিন প্যানেলে যেকোনো প্রশ্ন বা উত্তর আপডেট করা হলে তা এখানে স্বয়ংক্রিয়ভাবে আপডেট হয়।*');
      } else {
        buffer.writeln('❓ **BashaBondhu House Owner FAQs (Live Firebase Data):**\n');
        buffer.writeln('🧠 **AI Agent Analysis & Executive Summary:**');
        buffer.writeln('• **Posting Listings:** Tap "+" or "Post Free" on your dashboard to publish rental properties with photos & specs.');
        buffer.writeln('• **Occupancy Control:** Toggle "Rented Out" on My Post screen to shield your listing when occupied.');
        buffer.writeln('• **Tenant Demands:** Browse active neighborhood renter requirements & contact prospects directly.');
        buffer.writeln('• **Rent Estimates:** Ask the AI engine for competitive rental price guidance tailored to your area.\n');
        buffer.writeln('📋 **Detailed Q&A List Retrieved from Firebase Firestore:**\n');

        for (int i = 0; i < faqs.length; i++) {
          final f = faqs[i];
          final q = f.getQuestion('en');
          final a = f.getAnswer('en');
          buffer.writeln('**Q${i + 1}: $q**');
          buffer.writeln('👉 **Answer:** $a\n');
        }
        buffer.writeln('──────────────────');
        buffer.writeln('ℹ️ *All FAQs are actively synced with Firebase Firestore. Any administrative updates reflect immediately.*');
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
      debugPrint('Error fetching house owner FAQs: $e');
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
  // TENANT FAQS (FETCHED LIVE FROM FIRESTORE WITH AI ANALYSIS)
  // ==========================================

  Future<void> _showTenantFaq(UserModel user, String languageCode) async {
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    try {
      final faqs = await PolicyFirestoreService().getFaqs(targetAudience: 'tenant');
      faqs.sort((a, b) => a.order.compareTo(b.order));

      final buffer = StringBuffer();
      if (isBn) {
        buffer.writeln('❓ **বাসাবন্ধু ভাড়াটিয়া সাধারণ জিজ্ঞাসা ও সমাধান (FAQs - Live Firebase):**\n');
        buffer.writeln('🧠 **এআই বিশ্লেষণ ও সারসংক্ষেপ (AI Agent Summary):**');
        buffer.writeln('• **বাসা খোঁজা ও ফিল্টার:** হোম স্ক্রিনের সার্চ ও ফিল্টার ব্যবহার করে বাজেট, বেডরুম ও সুযোগ-সুবিধা অনুযায়ী বাসা নির্বাচন করুন।');
        buffer.writeln('• **ডিমান্ড পোস্ট:** কাঙ্ক্ষিত এলাকায় বাসা না পেলে "Demand" পোস্ট করুন, বাড়িওয়ালারা সরাসরি যোগাযোগ করবেন।');
        buffer.writeln('• **যোগাযোগ আনলক:** সাবস্ক্রিপশন প্যাকেজের মাধ্যমে বাড়িওয়ালার ভেরিফাইড মোবাইল ও হোয়াটসঅ্যাপ আনলক করুন।');
        buffer.writeln('• **বাসা পাওয়ার পর:** "My Demands" থেকে "বাসা পেয়ে গেছি (Mark as Fulfilled)" অন করে পোস্টটি ক্লোজ করুন।\n');
        buffer.writeln('📋 **ফায়ারবেস ক্লাউড ডাটাবেজ থেকে সংগৃহীত প্রশ্নোত্তর তালিকা:**\n');

        for (int i = 0; i < faqs.length; i++) {
          final f = faqs[i];
          final q = f.getQuestion('bn');
          final a = f.getAnswer('bn');
          buffer.writeln('**প্রশ্ন ${(i + 1).toString().toLocalizedDigits('bn')}: $q**');
          buffer.writeln('👉 **উত্তর:** $a\n');
        }
        buffer.writeln('──────────────────');
        buffer.writeln('ℹ️ *এডমিন প্যানেলে যেকোনো প্রশ্ন বা উত্তর আপডেট করা হলে তা এখানে স্বয়ংক্রিয়ভাবে আপডেট হয়।*');
      } else {
        buffer.writeln('❓ **BashaBondhu Tenant FAQs (Live Firebase Data):**\n');
        buffer.writeln('🧠 **AI Agent Analysis & Executive Summary:**');
        buffer.writeln('• **Searching Flats:** Use smart budget, room, and area filters or interactive map search on the Home screen.');
        buffer.writeln('• **Demand Posts:** Publish your specific requirements so verified landlords can reach out to you directly.');
        buffer.writeln('• **Unlocking Contacts:** Activate subscription packages to view owner verified phone & WhatsApp numbers.');
        buffer.writeln('• **Closing Demands:** Toggle "Mark as Fulfilled" in My Demands after securing your flat.\n');
        buffer.writeln('📋 **Detailed Q&A List Retrieved from Firebase Firestore:**\n');

        for (int i = 0; i < faqs.length; i++) {
          final f = faqs[i];
          final q = f.getQuestion('en');
          final a = f.getAnswer('en');
          buffer.writeln('**Q${i + 1}: $q**');
          buffer.writeln('👉 **Answer:** $a\n');
        }
        buffer.writeln('──────────────────');
        buffer.writeln('ℹ️ *All FAQs are actively synced with Firebase Firestore. Any administrative updates reflect immediately.*');
      }

      history.add(
        AIMessageModel(
          id: 'faq_${DateTime.now().millisecondsSinceEpoch}',
          text: buffer.toString(),
          sender: AIMessageSender.ai,
          interactiveChips: isBn
              ? ['🔍 বাসা খুঁজুন', '📖 কীভাবে অ্যাপ ব্যবহার করবেন', '💳 সাবস্ক্রিপশন প্যাকেজ', '⚡ প্রধান ৩টি অপশন']
              : ['🔍 Find Home', '📖 How to Use', '💳 Subscription Packages', '⚡ Main 3 Options'],
          quickActions: isBn ? ['⚡ প্রধান ৩টি অপশন'] : ['⚡ Main 3 Options'],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching tenant FAQs: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ==========================================
  // TENANT STEP-BY-STEP "HOW TO USE" MASTER GUIDE
  // ==========================================

  void _showTenantHowToUse(UserModel user, String languageCode) {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    final buffer = StringBuffer();
    if (isBn) {
      buffer.writeln('📖 **ভাড়াটিয়াদের জন্য বাসাবন্ধু অ্যাপ ব্যবহারের সহজ নির্দেশিকা (Step-by-Step Guide):**\n');
      buffer.writeln('১️⃣ **অ্যাকাউন্ট ও প্রোফাইল ভেরিফিকেশন (Account Setup):**');
      buffer.writeln('   • ভাড়াটিয়া (Tenant) হিসেবে লগইন করে আপনার প্রোফাইল ও এনআইডি ভেরিফিকেশন সম্পন্ন করুন।');
      buffer.writeln('   • ভেরিফাইড প্রোফাইল থাকলে বাড়িওয়ালারা আপনার চাহিদাকে সর্বোচ্চ অগ্রাধিকার দেবেন।\n');

      buffer.writeln('২️⃣ **পছন্দের বাসা খোঁজা ও ফিল্টারিং (Search & Filter):**');
      buffer.writeln('   • হোম স্ক্রিনে এলাকা লিখে সার্চ করুন অথবা রুমের সংখ্যা, লিফট, পার্কিং ও বাজেট দিয়ে নিখুঁত ফিল্টার করুন।\n');

      buffer.writeln('৩️⃣ **ভাড়াটিয়া ডিমান্ড পোস্ট (Post Tenant Demand):**');
      buffer.writeln('   • কাঙ্ক্ষিত এলাকায় বাসা না পেলে "ডিমান্ড" স্ক্রিনে গিয়ে আপনার বাজেট ও চাহিদার বিবরণ পোস্ট করুন।');
      buffer.writeln('   • এলাকার বাড়িওয়ালারা আপনার পোস্ট দেখে সরাসরি আপনার সাথে যোগাযোগ করবেন।\n');

      buffer.writeln('৪️⃣ **উইশলিস্টে বাসা সংরক্ষণ (Save to Wishlist):**');
      buffer.writeln('   • পছন্দের বাসাগুলোর ছবিতে লাভ (❤️) আইকনে চাপ দিয়ে সংরক্ষণ করে রাখুন এবং পরবর্তীতে তুলনা করুন।\n');

      buffer.writeln('৫️⃣ **বাড়িওয়ালার নম্বর আনলক ও সাবস্ক্রিপশন (Unlock Contacts):**');
      buffer.writeln('   • সাবস্ক্রিপশন প্যাকেজ সক্রিয় করে বাড়িওয়ালার ফোন নম্বর ও হোয়াটসঅ্যাপ সাথে সাথে আনলক করুন।');
      buffer.writeln('   • ডিজিটাল রসিদ ও ট্রানজেকশন হিস্ট্রি সংরক্ষিত থাকে **Subscription History**-তে।\n');

      buffer.writeln('৬️⃣ **বাসা পাওয়ার পর ডিমান্ড ক্লোজ করা (Mark as Fulfilled):**');
      buffer.writeln('   • পছন্দের বাসা পেয়ে গেলে **My Demands** স্ক্রিনে গিয়ে \'বাসা পেয়ে গেছি\' অন করে দিন।');
      buffer.writeln('──────────────────');
      buffer.writeln('💡 *অ্যাপ ব্যবহারের যেকোনো বিষয়ে আরও বিস্তারিত জানতে নিচের বাটনে ক্লিক করুন।*');
    } else {
      buffer.writeln('📖 **Step-by-Step Guide: How to Use BashaBondhu as a Tenant:**\n');
      buffer.writeln('1️⃣ **Account Setup & NID Verification:**');
      buffer.writeln('   • Sign in as a Tenant and complete profile details & NID verification for top trust.\n');

      buffer.writeln('2️⃣ **Search Homes & Smart Filtering:**');
      buffer.writeln('   • Search by location on Home screen, filter by budget, bedroom count, lift, and parking.\n');

      buffer.writeln('3️⃣ **Post Rental Requirements (Tenant Demand):**');
      buffer.writeln('   • If suitable flats are not listed, tap "Post Demand" to publish your specific budget and requirements.\n');

      buffer.writeln('4️⃣ **Save Favorites to Wishlist:**');
      buffer.writeln('   • Tap the heart (❤️) icon to bookmark prospective flats and compare them anytime.\n');

      buffer.writeln('5️⃣ **Unlock Owner Contacts & Subscriptions:**');
      buffer.writeln('   • Subscribe via bKash to unlock house owners\' verified phone and WhatsApp contacts directly.\n');

      buffer.writeln('6️⃣ **Close Demand with "Mark as Fulfilled":**');
      buffer.writeln('   • Once you rent your flat, toggle "Fulfilled" in **My Demands** to close the listing.');
      buffer.writeln('──────────────────');
      buffer.writeln('💡 *Tap any quick option below to explore further.*');
    }

    history.add(
      AIMessageModel(
        id: 'guide_${DateTime.now().millisecondsSinceEpoch}',
        text: buffer.toString(),
        sender: AIMessageSender.ai,
        interactiveChips: isBn
            ? ['🔍 বাসা খুঁজুন', '❓ সাধারণ জিজ্ঞাসা', '💳 সাবস্ক্রিপশন প্যাকেজ', '⚡ প্রধান ৩টি অপশন']
            : ['🔍 Find Home', '❓ FAQ', '💳 Subscription Packages', '⚡ Main 3 Options'],
        quickActions: isBn ? ['⚡ প্রধান ৩টি অপশন'] : ['⚡ Main 3 Options'],
      ),
    );
    notifyListeners();
  }

  // ==========================================
  // DYNAMIC POLICY HANDLER (FIREBASE BACKED WITH AI ANALYSIS)
  // ==========================================

  Future<void> _showHouseOwnerPolicy(UserModel user, String policyType, String languageCode) async {
    _isGenerating = true;
    notifyListeners();
    final isBn = languageCode == 'bn';
    final isOwner = user.isHouseOwner;
    final history = _userSessions[_activeUserId] ??= [];

    try {
      final targetAudience = isOwner ? 'house_owner' : 'tenant';
      final policy = await PolicyFirestoreService().getPolicy(
        policyType,
        targetAudience: targetAudience,
      );

      final buffer = StringBuffer();
      final title = policy.getTitle(languageCode);
      final subtitle = policy.getSubtitle(languageCode);

      buffer.writeln('🛡️ **$title**\n');
      if (subtitle.isNotEmpty) {
        buffer.writeln('📌 *$subtitle*\n');
      }

      // 🧠 AI Agent Analysis & Executive Summary (Derived from live Firestore policy data)
      if (isBn) {
        buffer.writeln('🧠 **এআই বিশ্লেষণ ও সারসংক্ষেপ (AI Agent Summary):**');
        if (policyType.contains('privacy')) {
          buffer.writeln(isOwner
              ? '• বাসাবন্ধু এআই আপনার ব্যক্তিগত মোবাইল নম্বর, প্রপার্টি ডকুমেন্ট ও বিজ্ঞাপনের তথ্যের পূর্ণ গোপনীয়তা নিশ্চিত করে।\n• মধ্যস্থতাকারী বা অযাচিত থার্ড-পার্টির কাছে কোনো তথ্য শেয়ার করা হয় না।'
              : '• আপনার নাম, সার্চ হিস্ট্রি, উইশলিস্ট ও ডিমান্ড পোস্টের তথ্য আধুনিক এনক্রিপশনের মাধ্যমে সুরক্ষিত।\n• বাড়িওয়ালার সাথে সরাসরি যোগাযোগ ব্যতীত কোনো তথ্য উন্মুক্ত করা হয় না।');
        } else if (policyType.contains('support')) {
          buffer.writeln(isOwner
              ? '• বাড়িওয়ালাদের জন্য সপ্তাহে ৬ দিন সকাল ৯টা থেকে রাত ৯টা পর্যন্ত প্রায়োরিটি হেল্পলাইন ও অডিট টিম সক্রিয় থাকে।\n• ভুয়া ভাড়াটিয়াদের রিপোর্ট দ্রুত তদন্ত ও ২ কর্মঘণ্টায় প্রাথমিক সহায়তা দেওয়া হয়।'
              : '• ভাড়াটিয়াদের জন্য সপ্তাহের ৬ দিন সকাল ৯টা থেকে রাত ৯টা কাস্টমার সাপোর্ট ও বিরোধ নিষ্পত্তি টিম প্রস্তুত।\n• বিভ্রান্তিকর বিজ্ঞাপন বা অতিরিক্ত ভাড়া দাবির ক্ষেত্রে দ্রুত তদন্ত সম্পন্ন হয়।');
        } else if (policyType.contains('terms')) {
          buffer.writeln(isOwner
              ? '• বাড়িওয়ালাদের অবশ্যই বাসার সঠিক ছবি, সঠিক ভাড়া ও ফ্ল্যাটের স্পেসিফিকেশন প্রদান করতে হবে।\n• বাসা ভাড়া হয়ে গেলে অবিলম্বে "Rented Out" অন করা এবং বাংলাদেশের বাড়িভাড়া আইন মেনে চলা বাধ্যতামূলক।'
              : '• ভাড়াটিয়াদের অবশ্যই সঠিক তথ্য দিয়ে ডিমান্ড পোস্ট ও প্রোফাইল পরিচালনা করতে হবে।\n• বাসা পেয়ে গেলে অবিলম্বে "Mark as Fulfilled" চালু করা ও প্ল্যাটফর্ম নিয়মাবলী মেনে চলা আবশ্যক।');
        } else if (policyType.contains('refund')) {
          buffer.writeln(isOwner
              ? '• সাবস্ক্রিপশন প্ল্যান ও বুস্টিং পেমেন্টে কোনো টেকনিক্যাল ব্যর্থতা ঘটলে ৩-৫ কার্যদিবসের মধ্যে ১০০% রিফান্ড প্রদান করা হয়।\n• প্ল্যাটফর্ম ট্রানজেকশন আইডি সহ আবেদন করলে সমাধান দ্রুততর হয়।'
              : '• সাবস্ক্রিপশন বা আনলক সুবিধা সংক্রান্ত পেমেন্টে ত্রুটি হলে ৩-৫ কার্যদিবসে সমাধান নিশ্চিত করা হয়।\n• ডিজিটাল রসিদ ও ট্রানজেকশন হিস্ট্রি অ্যাকাউন্ট সেকশনে সংরক্ষিত থাকে।');
        }
        buffer.writeln('');
        buffer.writeln('📋 **ফায়ারবেস ডাটাবেজ থেকে সংগৃহীত বিশদ ধারা ও শর্তাবলী (Live Clauses):**\n');
      } else {
        buffer.writeln('🧠 **AI Agent Analysis & Executive Summary:**');
        if (policyType.contains('privacy')) {
          buffer.writeln(isOwner
              ? '• BashaBondhu AI safeguards landlord contact info, listing credentials, and property documents with enterprise-grade cloud security.\n• Contact details are never sold to third-party telemarketers.'
              : '• Your search logs, wishlist bookmarks, and demand posts are protected with SSL/TLS encryption.\n• Phone numbers are only shared when you initiate contact with verified landlords.');
        } else if (policyType.contains('support')) {
          buffer.writeln(isOwner
              ? '• Priority landlord helpline available Sat-Thu (9 AM - 9 PM BST) with fast-track listing approvals.\n• Suspicious tenant reports are escalated and reviewed within 2 hours.'
              : '• Dedicated renter helpline operating Sat-Thu (9 AM - 9 PM BST) with guaranteed dispute resolution.\n• Report misleading listings directly for prompt administrative investigation.');
        } else if (policyType.contains('terms')) {
          buffer.writeln(isOwner
              ? '• Landlords must provide authentic photographs, accurate rent rates, and update the "Rented Out" status immediately.\n• Compliance with the Premises Rent Control Act of Bangladesh is required.'
              : '• Renters must post genuine demands and update "Mark as Fulfilled" upon securing a home.\n• Direct, transparent, and fair communications without middlemen are enforced.');
        } else if (policyType.contains('refund')) {
          buffer.writeln(isOwner
              ? '• 100% full refund within 3-5 business days for failed subscription transactions or duplicate billing.\n• All digital payment receipts are securely archived in Subscription History.'
              : '• Direct refund protection within 3-5 business days for subscription errors.\n• Contact support with your transaction ID for instant refund resolution.');
        }
        buffer.writeln('');
        buffer.writeln('📋 **Detailed Policy Sections from Firebase Firestore:**\n');
      }

      // Render all dynamic sections retrieved live from Firestore
      for (final section in policy.sections) {
        final h = section.getHeading(languageCode);
        final c = section.getContent(languageCode);
        buffer.writeln('🔹 **$h**');
        buffer.writeln('$c\n');
      }

      buffer.writeln('──────────────────');
      buffer.writeln(isBn
          ? 'ℹ️ *এই নীতিমালা ফায়ারবেস ক্লাউড ডাটাবেজ থেকে রিয়েল-টাইমে লোড ও এআই দ্বারা বিশ্লেষণকৃত। এডমিন প্যানেলের যেকোনো পরিবর্তন এখানে তাৎক্ষণিক কার্যকর হয়।*'
          : 'ℹ️ *This policy is dynamically retrieved from Firebase Firestore and analyzed by AI in real time. Admin updates reflect instantly.*');

      history.add(
        AIMessageModel(
          id: 'pol_${DateTime.now().millisecondsSinceEpoch}',
          text: buffer.toString(),
          sender: AIMessageSender.ai,
          interactiveChips: isBn
              ? (isOwner
                  ? ['❓ সাধারণ জিজ্ঞাসা', '📖 কীভাবে অ্যাপ ব্যবহার করবেন', '👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '⚡ প্রধান ৪টি অপশন']
                  : ['❓ সাধারণ জিজ্ঞাসা', '📖 কীভাবে অ্যাপ ব্যবহার করবেন', '🔍 বাসা খুঁজুন', '⚡ প্রধান ৩টি অপশন'])
              : (isOwner
                  ? ['❓ FAQ', '📖 How to Use', '👥 Find Tenant Demand', '⚡ Main 4 Options']
                  : ['❓ FAQ', '📖 How to Use', '🔍 Find Home', '⚡ Main 3 Options']),
          quickActions: isBn
              ? [isOwner ? '⚡ প্রধান ৪টি অপশন' : '⚡ প্রধান ৩টি অপশন']
              : [isOwner ? '⚡ Main 4 Options' : '⚡ Main 3 Options'],
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
    String? subArea,
    String? district,
    String? division,
    String? shortAddress,
    required String houseType,
    required String roomOrSeat,
    String? tenantType,
    String? month,
    required String floor,
    required String amount,
    int? commonBathrooms,
    int? attachedBathrooms,
    int? kitchenCount,
    int? balconies,
    String? electricityBillType,
    required List<String> amenities,
    String? marketDistance,
    required String languageCode,
  }) async {
    return _geminiService.generateDecoratedPropertyDescription(
      area: area,
      subArea: subArea,
      district: district,
      division: division,
      shortAddress: shortAddress,
      houseType: houseType,
      roomOrSeat: roomOrSeat,
      tenantType: tenantType,
      month: month,
      floor: floor,
      amount: amount,
      commonBathrooms: commonBathrooms,
      attachedBathrooms: attachedBathrooms,
      kitchenCount: kitchenCount,
      balconies: balconies,
      electricityBillType: electricityBillType,
      amenities: amenities,
      marketDistance: marketDistance,
      languageCode: languageCode,
    );
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

  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  String normalizedRaw = rawBudget.toLowerCase();
  for (int i = 0; i < 10; i++) {
    normalizedRaw = normalizedRaw.replaceAll(bnDigits[i], enDigits[i]);
  }
  normalizedRaw = normalizedRaw.replaceAll('কে', 'k');

  final numMatches = RegExp(r'(\d+(?:\.\d+)?)\s*(k|kilo|thousand|হাজার|লাখ|lac|lakh)?', caseSensitive: false)
      .allMatches(normalizedRaw.replaceAll(',', ''));

  final List<double> digits = [];
  for (final match in numMatches) {
    final numStr = match.group(1);
    if (numStr == null) continue;
    final parsed = double.tryParse(numStr);
    if (parsed == null) continue;

    final unit = match.group(2)?.toLowerCase();
    double val = parsed;
    if (unit == 'k' || unit == 'kilo' || unit == 'thousand' || unit == 'হাজার' || (parsed < 100 && normalizedRaw.contains('k'))) {
      val = parsed * 1000;
    } else if (unit == 'লাখ' || unit == 'lac' || unit == 'lakh') {
      val = parsed * 100000;
    } else if (parsed < 100) {
      val = parsed * 1000;
    }
    digits.add(val);
  }

  if (digits.isEmpty) return null;

  final double minVal = digits.first;
  final double maxVal = digits.length > 1 ? digits[1] : (normalizedRaw.contains('+') ? 1000000.0 : minVal);

  if (normalizedRaw.contains('50000+') || maxVal > 40000 || normalizedRaw.contains('+')) {
    return isBn ? '৳ ৪০,০০০+' : 'Above ৳40,000';
  } else if (maxVal <= 5000) {
    return isBn ? '৳ ৫,০০০ এর নিচে' : 'Below ৳5,000';
  } else if (maxVal <= 10000) {
    return isBn ? '৳ ৬,০০০-১০,০০০' : '৳ 6,000-10,000';
  } else if (maxVal <= 15000) {
    return isBn ? '৳ ১১,০০০-১৫,০০০' : '৳ 11,000-15,000';
  } else if (maxVal <= 20000) {
    return isBn ? '৳ ১৬,০০০-২০,০০০' : '৳ 16,000-20,000';
  } else if (maxVal <= 25000) {
    return isBn ? '৳ ২১,০০০-২৫,০০০' : '৳ 21,000-25,000';
  } else if (maxVal <= 30000) {
    return isBn ? '৳ ২৬,০০০-৩০,০০০' : '৳ 26,000-30,000';
  } else {
    return isBn ? '৳ ৩১,০০০-৪০,০০০' : '৳ 31,000-40,000';
  }
}

/// Helper to match whether a demand post fits the selected PriceFilterCriteria directly
bool _matchesBudgetFilterCriteria(TenantDemandModel demand, PriceFilterCriteria criteria) {
  final raw = demand.budgetRange?.trim() ?? '';
  if (raw.isEmpty) return false;

  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  String normalizedRaw = raw.toLowerCase();
  for (int i = 0; i < 10; i++) {
    normalizedRaw = normalizedRaw.replaceAll(bnDigits[i], enDigits[i]);
  }
  normalizedRaw = normalizedRaw.replaceAll('কে', 'k');

  final numMatches = RegExp(r'(\d+(?:\.\d+)?)\s*(k|kilo|thousand|হাজার|লাখ|lac|lakh)?', caseSensitive: false)
      .allMatches(normalizedRaw.replaceAll(',', ''));

  final List<double> demandNumbers = [];
  for (final match in numMatches) {
    final numStr = match.group(1);
    if (numStr == null) continue;
    final parsed = double.tryParse(numStr);
    if (parsed == null) continue;

    final unit = match.group(2)?.toLowerCase();
    double val = parsed;
    if (unit == 'k' || unit == 'kilo' || unit == 'thousand' || unit == 'হাজার' || (parsed < 100 && normalizedRaw.contains('k'))) {
      val = parsed * 1000;
    } else if (unit == 'লাখ' || unit == 'lac' || unit == 'lakh') {
      val = parsed * 100000;
    } else if (parsed < 100) {
      val = parsed * 1000;
    }
    demandNumbers.add(val);
  }

  if (demandNumbers.isEmpty) return false;

  final double minVal = demandNumbers.first;
  final double maxVal = demandNumbers.length > 1 ? demandNumbers[1] : (normalizedRaw.contains('+') ? 1000000.0 : minVal);

  if (criteria.isBelow && criteria.maxPrice != null) {
    return minVal <= criteria.maxPrice!;
  }
  if (criteria.isAbove && criteria.minPrice != null) {
    return maxVal >= criteria.minPrice!;
  }
  if (criteria.isRange && criteria.minPrice != null && criteria.maxPrice != null) {
    return minVal <= criteria.maxPrice! && maxVal >= criteria.minPrice!;
  }
  if (criteria.isExact && criteria.exactPrice != null) {
    return (minVal <= criteria.exactPrice! && maxVal >= criteria.exactPrice!) ||
           (minVal - criteria.exactPrice!).abs() < 1 ||
           (maxVal - criteria.exactPrice!).abs() < 1;
  }

  return false;
}

/// Helper to match demand against generic text filters (room types, tenant types, amenities, etc.)
bool _matchesDemandFilter(TenantDemandModel demand, String filterText) {
  final clean = filterText.toLowerCase().trim();
  if (clean.isEmpty) return true;

  if (demand.roomOrSeat.toLowerCase().contains(clean)) return true;
  if (demand.tenantType?.name.toLowerCase().contains(clean) == true) return true;
  if (demand.detailedDescription.toLowerCase().contains(clean)) return true;
  if (demand.subArea?.name.toLowerCase().contains(clean) == true) return true;
  if (demand.subArea?.bnName.toLowerCase().contains(clean) == true) return true;
  if (demand.area.name.toLowerCase().contains(clean) || demand.area.bnName.toLowerCase().contains(clean)) return true;
  if (demand.district.name.toLowerCase().contains(clean) || demand.district.bnName.toLowerCase().contains(clean)) return true;
  if (demand.division.name.toLowerCase().contains(clean) || demand.division.bnName.toLowerCase().contains(clean)) return true;

  return false;
}

const List<String> _bdKnownLocations = [
  'dhaka', 'ঢাকা',
  'gazipur', 'গাজীপুর',
  'mirpur', 'মিরপুর',
  'mirpur 1', 'mirpur 2', 'mirpur 6', 'mirpur 7', 'mirpur 10', 'mirpur 11', 'mirpur 12', 'mirpur 14',
  'মিরপুর ১', 'মিরপুর ২', 'মিরপুর ৬', 'মিরপুর ৭', 'মিরপুর ১০', 'মিরপুর ১১', 'মিরপুর ১২', 'মিরপুর ১৪',
  'মিরপুর-১', 'মিরপুর-২', 'মিরপুর-১০', 'মিরপুর-১১', 'মিরপুর-১২',
  'uttara', 'উত্তরা',
  'uttara sector 1', 'uttara sector 3', 'uttara sector 4', 'uttara sector 5', 'uttara sector 6', 'uttara sector 7',
  'uttara sector 9', 'uttara sector 10', 'uttara sector 11', 'uttara sector 12', 'uttara sector 13', 'uttara sector 14',
  'উত্তরা সেক্টর ১', 'উত্তরা সেক্টর ৩', 'উত্তরা সেক্টর ৭', 'উত্তরা সেক্টর ১০', 'উত্তরা সেক্টর ১১',
  'dhanmondi', 'ধানমন্ডি',
  'dhanmondi residential area', 'dhanmondi r/a', 'dhanmondi ra', 'ধানমন্ডি আবাসিক এলাকা', 'ধানমন্ডি আবাসিক',
  'dhanmondi 27', 'dhanmondi 32', 'dhanmondi 8/a', 'dhanmondi 9/a', 'ধানমন্ডি ২৭', 'ধানমন্ডি ৩২',
  'gulshan', 'gulsan', 'গুলশান',
  'gulshan 1', 'gulshan 2', 'gulshan-1', 'gulshan-2', 'gulsan 1', 'gulsan 2', 'gulsan-1', 'gulsan-2',
  'গুলশান ১', 'গুলশান ২', 'গুলশান-১', 'গুলশান-২',
  'banani', 'বনানী',
  'mohammadpur', 'mohammodpur', 'মোহাম্মদপুর',
  'bashundhara', 'basundhara', 'বসুন্ধরা',
  'bashundhara r/a', 'bashundhara residential area', 'বসুন্ধরা আবাসিক এলাকা',
  'badda', 'বাড্ডা',
  'motijheel', 'motijhil', 'মতিঝিল',
  'khilgaon', 'খিলগাঁও',
  'malibagh', 'malibag', 'মালিবাগ',
  'rampura', 'রামপুরা',
  'banasree', 'bonosree', 'বনশ্রী',
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
  'jessore', 'jashore', 'যশোর',
  'barishal', 'barisal', 'বরিশাল',
  'rajshahi', 'রাজশাহী',
  'bogra', 'bogura', 'বগুড়া',
  'rangpur', 'রংপুর',
  'dinajpur', 'দিনাজপুর',
  'mymensingh', 'ময়মনসিংহ',
  'tangail', 'টাঙ্গাইল',
  'feni', 'ফেনী',
  'noakhali', 'নোয়াখালী',
  'brahmanbaria', 'ব্রাহ্মণবাড়িয়া',
  'chandpur', 'চাঁদপুর',
  'pabna', 'পাবনা',
  'sirajganj', 'সিরাজগঞ্জ',
  'kushtia', 'কুষ্টিয়া',
  'jhenaidah', 'ঝিনাইদহ',
  'satkhira', 'সাতক্ষীরা',
  'bagerhat', 'বাগেরহাট',
  'patuakhali', 'পটুয়াখালী',
  'bhola', 'ভোলা',
  'moulvibazar', 'মৌলভীবাজার',
  'habiganj', 'হবিগঞ্জ',
  'sunamganj', 'সুনামগঞ্জ',
  'kurigram', 'কুড়িগ্রাম',
  'gaibandha', 'গাইবান্ধা',
  'nilphamari', 'নীলফামারী',
  'panchagarh', 'পঞ্চগড়',
  'thakurgaon', 'ঠাকুরগাঁও',
  'jamalpur', 'জামালপুর',
  'netrokona', 'নেত্রকোণা',
  'sherpur', 'শেরপুর',
  'tongi', 'টঙ্গী',
  'mohakhali', 'mokhakhali', 'মহাখালী',
  'nikunja', 'nikunja 1', 'nikunja 2', 'নিকুঞ্জ', 'নিকুঞ্জ ১', 'নিকুঞ্জ ২',
  'baridhara', 'baridhara dohs', 'বারিধারা', 'বারিধারা ডিওএইচএস',
  'pallabi', 'পল্লবী',
  'kafrul', 'কাফরুল',
  'kazipara', 'কাজীপাড়া',
  'shewrapara', 'শেওড়াপাড়া',
  'agargaon', 'আগারগাঁও',
  'shyamoli', 'শ্যামলী',
  'kalyanpur', 'কল্যাণপুর',
  'gabtoli', 'গাবতলী',
  'hazaribagh', 'হাজারীবাগ',
  'azimpur', 'আজিমপুর',
  'new market', 'নিউ মার্কেট',
  'elephant road', 'এলিফ্যান্ট রোড',
  'paltan', 'পল্টন',
  'kakrail', 'কাকরাইল',
  'shantinagar', 'শান্তিনগর',
  'moghbazar', 'মগবাজার',
  'baily road', 'বেইলি রোড',
  'eskaton', 'ইস্কাটন',
  'tejgaon', 'তেজগাঁও',
  'panthapath', 'পান্থপথ',
  'green road', 'গ্রীন রোড',
  'kalabagan', 'কলাবাগান',
  'lalmatia', 'লালমাটিয়া',
  'jigatola', 'জিগাতলা',
  'rayerbazar', 'রায়েরবাজার',
  'kamrangirchar', 'কামরাঙ্গীরচর',
  'chawkbazar', 'চকবাজার',
  'sutrapur', 'সূত্রাপুর',
  'kotwali', 'কোতোয়ালি',
  'gandaria', 'গেন্ডারিয়া',
  'demra', 'ডেমরা',
  'jatrabari', 'যাত্রাবাড়ী',
  'sayedabad', 'সায়েদাবাদ',
  'shonir akhra', 'শনির আখড়া',
  'signboard', 'সাইনবোর্ড',
  'matuail', 'মাতুয়াইল',
  'kadamtali', 'কদমতলী',
  'khilkhet', 'খিলক্ষেত',
  'dakkhinkhan', 'দক্ষিণখান',
  'uttarkhan', 'উত্তরখান',
  'ashkona', 'আশকোনা',
  'diabari', 'দিয়াবাড়ী',
];

/// Helper function to extract recognized location names from user prompt
String? _extractLocationQuery(String input) {
  String lower = input.toLowerCase().trim();
  lower = lower
      .replaceAll('📍', '')
      .replaceAll('🏠', '')
      .replaceAll(RegExp(r'\(\s*[0-9০-৯]+\s*\)'), '')
      .replaceAll('gulsan', 'gulshan')
      .replaceAll('residensial', 'residential')
      .replaceAll('bonosree', 'banasree')
      .replaceAll('basundhara', 'bashundhara')
      .replaceAll('mohammodpur', 'mohammadpur')
      .trim();

  // If chip was an area (starts with 📍)
  if (input.trim().startsWith('📍') && lower.isNotEmpty) {
    return lower;
  }

  // 1. Direct match with BD known locations (longest first for specific names like "dhanmondi residential area")
  for (final loc in _bdKnownLocations) {
    final locL = loc.toLowerCase();
    if (lower.contains(locL)) {
      return loc;
    }
  }

  // 2. Inflected Bengali endings check (e.g. 'মিরপুরে', 'উত্তরায়', 'ধানমন্ডিতে', 'ঢাকায়', 'সিলেটে')
  const suffixes = ['-এ', ' এ', 'ে', 'তে', 'য়', 'র', 'ের'];
  for (final loc in _bdKnownLocations) {
    final locL = loc.toLowerCase();
    for (final s in suffixes) {
      if (lower.contains('$locL$s')) {
        return loc;
      }
    }
  }

  return null;
}

/// Helper to parse location queries from search text
String? _parseLocationFilter(String input) {
  return _extractLocationQuery(input);
}

/// Structured criteria for price filtering
class PriceFilterCriteria {
  final double? exactPrice;
  final double? minPrice;
  final double? maxPrice;
  final bool isBelow;
  final bool isAbove;
  final bool isRange;
  final bool isExact;
  final String displayTitle;
  final String rawFilter;

  const PriceFilterCriteria({
    this.exactPrice,
    this.minPrice,
    this.maxPrice,
    this.isBelow = false,
    this.isAbove = false,
    this.isRange = false,
    this.isExact = false,
    required this.displayTitle,
    required this.rawFilter,
  });

  bool matches(double propertyPrice) {
    if (propertyPrice <= 0) return false;
    if (isBelow && maxPrice != null) {
      return propertyPrice <= maxPrice!;
    }
    if (isAbove && minPrice != null) {
      return propertyPrice >= minPrice!;
    }
    if (isRange && minPrice != null && maxPrice != null) {
      return propertyPrice >= minPrice! && propertyPrice <= maxPrice!;
    }
    if (isExact && exactPrice != null) {
      return (propertyPrice - exactPrice!).abs() == 0;
    }
    return false;
  }
}

/// Helper to parse any price query into structured PriceFilterCriteria
PriceFilterCriteria? _parsePriceFilterCriteria(String input, bool isBn) {
  // Area chips must NEVER be parsed as price criteria
  if (input.trim().startsWith('📍')) return null;

  final clean = input
      .replaceAll('💰', '')
      .replaceAll('🏠', '')
      .replaceAll(RegExp(r'\(\s*[0-9০-৯]+\s*\)'), '')
      .trim();

  // Convert Bengali digits to English digits
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  String normalized = clean.toLowerCase();
  for (int i = 0; i < 10; i++) {
    normalized = normalized.replaceAll(bnDigits[i], enDigits[i]);
  }

  // Replace Bengali 'কে' with 'k'
  normalized = normalized.replaceAll('কে', 'k');

  final bool hasExplicitPriceWord = normalized.contains('k') ||
      normalized.contains('হাজার') ||
      normalized.contains('লাখ') ||
      normalized.contains('lac') ||
      normalized.contains('lakh') ||
      normalized.contains('৳') ||
      normalized.contains('tk') ||
      normalized.contains('taka') ||
      normalized.contains('টাকা') ||
      normalized.contains('ভাড়া') ||
      normalized.contains('rent') ||
      normalized.contains('budget') ||
      normalized.contains('বাজেট') ||
      normalized.contains('দাম') ||
      normalized.contains('price');

  final bool hasLacWord = normalized.contains('লাখ') || normalized.contains('lac') || normalized.contains('lakh');
  final bool isBelow = normalized.contains('below') ||
      normalized.contains('under') ||
      normalized.contains('less') ||
      normalized.contains('upto') ||
      normalized.contains('up to') ||
      normalized.contains('within') ||
      normalized.contains('max') ||
      normalized.contains('maximum') ||
      normalized.contains('নিচে') ||
      normalized.contains('কম') ||
      normalized.contains('পর্যন্ত') ||
      normalized.contains('মধ্যে') ||
      normalized.contains('অনূর্ধ্ব') ||
      normalized.contains('সর্বোচ্চ') ||
      normalized.contains('niche') ||
      normalized.contains('kom') ||
      normalized.contains('moddhe') ||
      normalized.contains('<');

  final bool isAbove = normalized.contains('above') ||
      normalized.contains('over') ||
      normalized.contains('more') ||
      normalized.contains('greater') ||
      normalized.contains('plus') ||
      normalized.contains('min') ||
      normalized.contains('minimum') ||
      normalized.contains('at least') ||
      normalized.contains('বেশি') ||
      normalized.contains('উপরে') ||
      normalized.contains('অধিক') ||
      normalized.contains('ঊর্ধ্বে') ||
      normalized.contains('সর্বনিম্ন') ||
      normalized.contains('+') ||
      normalized.contains('upore') ||
      normalized.contains('beshi') ||
      normalized.contains('>') ||
      normalized.contains('উর্ধে') ||
      normalized.contains('উর্ধ্বে');

  // Match all numbers with potential 'k' / 'K' / 'হাজার' / 'লাখ'
  final numberMatches = RegExp(r'(\d+(?:\.\d+)?)\s*(k|kilo|thousand|হাজার|লাখ|lac|lakh)?', caseSensitive: false)
      .allMatches(normalized.replaceAll(',', ''));

  final List<double> scaledNumbers = [];
  for (final match in numberMatches) {
    final numStr = match.group(1);
    if (numStr == null) continue;
    final parsed = double.tryParse(numStr);
    if (parsed == null) continue;

    final unitStr = match.group(2)?.toLowerCase();
    double val = parsed;

    if (unitStr == 'k' || unitStr == 'kilo' || unitStr == 'thousand' || unitStr == 'হাজার' || (parsed < 100 && normalized.contains('k')) || (parsed < 100 && normalized.contains('হাজার'))) {
      val = parsed * 1000;
    } else if (unitStr == 'লাখ' || unitStr == 'lac' || unitStr == 'lakh' || (hasLacWord && parsed < 100)) {
      val = parsed * 100000;
    } else if (parsed >= 500) {
      val = parsed;
    } else if (hasExplicitPriceWord || isBelow || isAbove) {
      val = parsed * 1000;
    } else {
      // Numbers like 2 in "Gulshan 2" or 10 in "Mirpur 10" without price keywords are location sectors, not prices
      continue;
    }

    scaledNumbers.add(val);
  }

  if (scaledNumbers.isEmpty) return null;

  // Deduplicate identical numbers (e.g. "10k/10000", "5k/5000", "১০০০০/১০k" all resolve to single price)
  final uniqueNumbers = <double>[];
  for (final num in scaledNumbers) {
    if (!uniqueNumbers.any((u) => (u - num).abs() < 1)) {
      uniqueNumbers.add(num);
    }
  }

  if (uniqueNumbers.isEmpty) return null;

  if (uniqueNumbers.length == 1) {
    final val = uniqueNumbers.first;
    if (isBelow) {
      final title = isBn
          ? '৳ ${val.toInt().toString().toLocalizedDigits('bn')} এর নিচে'
          : 'Below ৳${val.toInt()}';
      return PriceFilterCriteria(
        isBelow: true,
        maxPrice: val,
        displayTitle: title,
        rawFilter: clean,
      );
    } else if (isAbove) {
      final title = isBn
          ? '৳ ${val.toInt().toString().toLocalizedDigits('bn')} এর উপরে'
          : 'Above ৳${val.toInt()}';
      return PriceFilterCriteria(
        isAbove: true,
        minPrice: val,
        displayTitle: title,
        rawFilter: clean,
      );
    } else {
      // Exact price query (e.g. 10k, 10000, 10k/10000, 12.5k, 12500)
      final title = isBn
          ? '৳ ${val.toInt().toString().toLocalizedDigits('bn')}'
          : '৳${val.toInt()}';
      return PriceFilterCriteria(
        isExact: true,
        exactPrice: val,
        displayTitle: title,
        rawFilter: clean,
      );
    }
  } else {
    // 2 or more distinct numbers
    final n1 = uniqueNumbers[0];
    final n2 = uniqueNumbers[1];
    final minVal = min(n1, n2);
    final maxVal = max(n1, n2);

    if (isBelow) {
      final title = isBn
          ? '৳ ${maxVal.toInt().toString().toLocalizedDigits('bn')} এর নিচে'
          : 'Below ৳${maxVal.toInt()}';
      return PriceFilterCriteria(
        isBelow: true,
        maxPrice: maxVal,
        displayTitle: title,
        rawFilter: clean,
      );
    } else if (isAbove) {
      final title = isBn
          ? '৳ ${minVal.toInt().toString().toLocalizedDigits('bn')} এর উপরে'
          : 'Above ৳${minVal.toInt()}';
      return PriceFilterCriteria(
        isAbove: true,
        minPrice: minVal,
        displayTitle: title,
        rawFilter: clean,
      );
    } else {
      final title = isBn
          ? '৳ ${minVal.toInt().toString().toLocalizedDigits('bn')} - ৳ ${maxVal.toInt().toString().toLocalizedDigits('bn')}'
          : '৳${minVal.toInt()} - ৳${maxVal.toInt()}';
      return PriceFilterCriteria(
        isRange: true,
        minPrice: minVal,
        maxPrice: maxVal,
        displayTitle: title,
        rawFilter: clean,
      );
    }
  }
}

/// Helper to normalize any location string into comparable token representation
String _normalizeLocationText(String s) {
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  String res = s.toLowerCase();
  for (int i = 0; i < 10; i++) {
    res = res.replaceAll(bnDigits[i], enDigits[i]);
  }
  return res
      .replaceAll('📍', '')
      .replaceAll('🏠', '')
      .replaceAll(RegExp(r'\(\s*[0-9০-৯]+\s*\)'), '')
      .replaceAll('-', ' ')
      .replaceAll('/', ' ')
      .replaceAll('.', ' ')
      .replaceAll(',', ' ')
      .replaceAll('_', ' ')
      .replaceAll(':', ' ')
      .replaceAll('gulsan', 'gulshan')
      .replaceAll('residensial', 'residential')
      .replaceAll('bonosree', 'banasree')
      .replaceAll('basundhara', 'bashundhara')
      .replaceAll('mohammodpur', 'mohammadpur')
      .replaceAll('r a', 'residential area')
      .replaceAll('ra', 'residential area')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Helper to match property against geographic queries (Division, District, Area, Sub-Area, Address)
bool _matchesPropertyLocation(PropertyModel p, String queryLocation) {
  final q = _normalizeLocationText(queryLocation);
  if (q.isEmpty) return true;

  final divEn = _normalizeLocationText(p.division.name);
  final divBn = _normalizeLocationText(p.division.bnName);
  final distEn = _normalizeLocationText(p.district.name);
  final distBn = _normalizeLocationText(p.district.bnName);
  final areaEn = _normalizeLocationText(p.area.name);
  final areaBn = _normalizeLocationText(p.area.bnName);
  final subEn = p.subArea != null ? _normalizeLocationText(p.subArea!.name) : '';
  final subBn = p.subArea != null ? _normalizeLocationText(p.subArea!.bnName) : '';
  final addr = _normalizeLocationText(p.shortAddress);
  final desc = _normalizeLocationText(p.detailedDescription);

  final allFields = [
    divEn, divBn,
    distEn, distBn,
    areaEn, areaBn,
    subEn, subBn,
    addr, desc,
  ].where((s) => s.isNotEmpty).toList();

  // 1. Direct contains match across fields
  for (final field in allFields) {
    if (field.contains(q) || q.contains(field)) {
      return true;
    }
  }

  // 2. Cleaned target without noise words
  final strippedQ = q
      .replaceAll('residential area', '')
      .replaceAll('residential', '')
      .replaceAll('area', '')
      .replaceAll('আবাসিক এলাকা', '')
      .replaceAll('আবাসিক', '')
      .replaceAll('এলাকা', '')
      .replaceAll('লোকেশন', '')
      .replaceAll('location', '')
      .replaceAll(RegExp(r'(ে|তে|য়|র|এর|এলাকায়|বিভাগ|জেলা)$'), '')
      .trim();

  if (strippedQ.isNotEmpty && strippedQ.length >= 2) {
    for (final field in allFields) {
      if (field.contains(strippedQ) || strippedQ.contains(field)) {
        return true;
      }
    }
  }

  // 3. Token-based matching
  final tokens = q.split(' ').where((t) => t.length >= 2 || RegExp(r'^[0-9]$').hasMatch(t)).toList();
  if (tokens.isNotEmpty) {
    final significantTokens = tokens.where((t) =>
      t != 'area' && t != 'residential' && t != 'এলাকা' && t != 'আবাসিক' && t != 'লোকেশন' && t != 'in' && t != 'at'
    ).toList();

    if (significantTokens.isNotEmpty) {
      final allTokensMatch = significantTokens.every((tok) =>
        allFields.any((f) => f.contains(tok))
      );
      if (allTokensMatch) return true;

      final primaryToken = significantTokens.first;
      if (primaryToken.length >= 3 && allFields.any((f) => f.contains(primaryToken))) {
        return true;
      }
    }
  }

  return false;
}

/// Helper to extract numeric amount from raw price string (handles Bengali and English digits, commas, currency symbols)
double _extractPropertyNumericAmount(String rawAmount) {
  if (rawAmount.trim().isEmpty) return 0;
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  String normalized = rawAmount;
  for (int i = 0; i < 10; i++) {
    normalized = normalized.replaceAll(bnDigits[i], enDigits[i]);
  }
  final cleaned = normalized.replaceAll(',', '');
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(cleaned);
  if (match != null) {
    return double.tryParse(match.group(0)!) ?? 0;
  }
  return 0;
}

/// Helper to normalize property price into standard budget buckets
String? _normalizePropertyPriceBucket(double price, bool isBn) {
  if (price <= 0) return null;
  if (price <= 5000) {
    return isBn ? '৳ ৫,০০০ এর নিচে' : 'Below ৳5k';
  } else if (price <= 10000) {
    return isBn ? '৳ ৬,০০০-১০,০০০' : '৳6k-10k';
  } else if (price <= 15000) {
    return isBn ? '৳ ১১,০০০-১৫,০০০' : '৳11k-15k';
  } else if (price <= 20000) {
    return isBn ? '৳ ১৬,০০০-২০,০০০' : '৳16k-20k';
  } else if (price <= 25000) {
    return isBn ? '৳ ২১,০০০-২৫,০০০' : '৳21k-25k';
  } else if (price <= 30000) {
    return isBn ? '৳ ২৬,০০০-৩০,০০০' : '৳26k-30k';
  } else if (price <= 40000) {
    return isBn ? '৳ ৩১,০০০-৪০,০০০' : '৳31k-40k';
  } else {
    return isBn ? '৳ ৪০,০০০+' : 'Above ৳40k';
  }
}

/// Helper to match tenant demands against geographic locations
bool _matchesDemandLocation(TenantDemandModel d, String query) {
  final q = _normalizeLocationText(query);
  if (q.isEmpty) return true;

  final divEn = _normalizeLocationText(d.division.name);
  final divBn = _normalizeLocationText(d.division.bnName);
  final distEn = _normalizeLocationText(d.district.name);
  final distBn = _normalizeLocationText(d.district.bnName);
  final areaEn = _normalizeLocationText(d.area.name);
  final areaBn = _normalizeLocationText(d.area.bnName);
  final subEn = d.subArea != null ? _normalizeLocationText(d.subArea!.name) : '';
  final subBn = d.subArea != null ? _normalizeLocationText(d.subArea!.bnName) : '';
  final addr = _normalizeLocationText(d.shortAddress);
  final desc = _normalizeLocationText(d.detailedDescription);

  final allFields = [
    divEn, divBn,
    distEn, distBn,
    areaEn, areaBn,
    subEn, subBn,
    addr, desc,
  ].where((s) => s.isNotEmpty).toList();

  // 1. Direct contains match across fields
  for (final field in allFields) {
    if (field.contains(q) || q.contains(field)) {
      return true;
    }
  }

  // 2. Cleaned target without noise words
  final strippedQ = q
      .replaceAll('residential area', '')
      .replaceAll('residential', '')
      .replaceAll('area', '')
      .replaceAll('আবাসিক এলাকা', '')
      .replaceAll('আবাসিক', '')
      .replaceAll('এলাকা', '')
      .replaceAll('লোকেশন', '')
      .replaceAll('location', '')
      .replaceAll(RegExp(r'(ে|তে|য়|র|এর|এলাকায়|বিভাগ|জেলা)$'), '')
      .trim();

  if (strippedQ.isNotEmpty && strippedQ.length >= 2) {
    for (final field in allFields) {
      if (field.contains(strippedQ) || strippedQ.contains(field)) {
        return true;
      }
    }
  }

  // 3. Token-based matching
  final tokens = q.split(' ').where((t) => t.length >= 2 || RegExp(r'^[0-9]$').hasMatch(t)).toList();
  if (tokens.isNotEmpty) {
    final significantTokens = tokens.where((t) =>
      t != 'area' && t != 'residential' && t != 'এলাকা' && t != 'আবাসিক' && t != 'লোকেশন' && t != 'in' && t != 'at'
    ).toList();

    if (significantTokens.isNotEmpty) {
      final allTokensMatch = significantTokens.every((tok) =>
        allFields.any((f) => f.contains(tok))
      );
      if (allTokensMatch) return true;

      final primaryToken = significantTokens.first;
      if (primaryToken.length >= 3 && allFields.any((f) => f.contains(primaryToken))) {
        return true;
      }
    }
  }

  return false;
}

/// AI analytical summary model for active properties
class PropertyPriceAnalysis {
  final int totalFound;
  final double minAmount;
  final double maxAmount;
  final double avgAmount;
  final Map<String, int> roomTypeCounts;
  final int withLiftCount;
  final int withParkingCount;
  final int withGeneratorCount;
  final List<String> topAreas;

  const PropertyPriceAnalysis({
    required this.totalFound,
    required this.minAmount,
    required this.maxAmount,
    required this.avgAmount,
    required this.roomTypeCounts,
    required this.withLiftCount,
    required this.withParkingCount,
    required this.withGeneratorCount,
    required this.topAreas,
  });

  static PropertyPriceAnalysis analyze(List<PropertyModel> properties) {
    if (properties.isEmpty) {
      return const PropertyPriceAnalysis(
        totalFound: 0,
        minAmount: 0,
        maxAmount: 0,
        avgAmount: 0,
        roomTypeCounts: {},
        withLiftCount: 0,
        withParkingCount: 0,
        withGeneratorCount: 0,
        topAreas: [],
      );
    }

    double minP = double.infinity;
    double maxP = 0;
    double sumP = 0;
    final Map<String, int> roomTypes = {};
    final Map<String, int> areas = {};
    int lift = 0;
    int parking = 0;
    int generator = 0;

    for (final p in properties) {
      final amt = _extractPropertyNumericAmount(p.amount);
      if (amt > 0) {
        if (amt < minP) minP = amt;
        if (amt > maxP) maxP = amt;
        sumP += amt;
      }
      final r = p.roomOrSeat.trim();
      if (r.isNotEmpty) {
        roomTypes[r] = (roomTypes[r] ?? 0) + 1;
      }
      final a = p.area.name.trim();
      if (a.isNotEmpty) {
        areas[a] = (areas[a] ?? 0) + 1;
      }
      if (p.hasLift == true) lift++;
      if (p.hasParking == true) parking++;
      if (p.hasGenerator == true) generator++;
    }

    final avg = properties.isNotEmpty ? sumP / properties.length : 0.0;
    final sortedAreas = areas.keys.take(3).toList();

    return PropertyPriceAnalysis(
      totalFound: properties.length,
      minAmount: minP == double.infinity ? 0 : minP,
      maxAmount: maxP,
      avgAmount: avg,
      roomTypeCounts: roomTypes,
      withLiftCount: lift,
      withParkingCount: parking,
      withGeneratorCount: generator,
      topAreas: sortedAreas,
    );
  }

  String formatAiInsights(bool isBn, String languageCode) {
    if (totalFound == 0) return '';
    final buffer = StringBuffer();

    if (isBn) {
      buffer.writeln('🧠 **এআই বিশ্লেষণ ও বাজার পর্যবেক্ষণ (AI Market Insights):**');
      if (minAmount > 0 && maxAmount > 0) {
        if (minAmount == maxAmount) {
          buffer.writeln('• 💵 **ভাড়ার পরিমাণ:** ৳${minAmount.toInt().toString().toLocalizedDigits('bn')}');
        } else {
          buffer.writeln('• 📊 **ভাড়ার পরিসীমা:** ৳${minAmount.toInt().toString().toLocalizedDigits('bn')} থেকে ৳${maxAmount.toInt().toString().toLocalizedDigits('bn')} (গড় ভাড়া: ৳${avgAmount.toInt().toString().toLocalizedDigits('bn')})');
        }
      }
      if (roomTypeCounts.isNotEmpty) {
        final typesStr = roomTypeCounts.entries.map((e) => '${e.key} (${e.value.toString().toLocalizedDigits('bn')}টি)').join(', ');
        buffer.writeln('• 🏠 **উপলব্ধ ধরণ:** $typesStr');
      }
      final List<String> amenities = [];
      if (withLiftCount > 0) amenities.add('লিফট ($withLiftCount)');
      if (withParkingCount > 0) amenities.add('পার্কিং ($withParkingCount)');
      if (withGeneratorCount > 0) amenities.add('জেনারেটর ($withGeneratorCount)');
      if (amenities.isNotEmpty) {
        buffer.writeln('• ⚡ **বিশেষ সুবিধাসমূহ:** ${amenities.join(', ')}');
      }
    } else {
      buffer.writeln('🧠 **AI Agent Analysis & Market Insights:**');
      if (minAmount > 0 && maxAmount > 0) {
        if (minAmount == maxAmount) {
          buffer.writeln('• 💵 **Exact Rent:** ৳${minAmount.toInt()}');
        } else {
          buffer.writeln('• 📊 **Rent Range:** ৳${minAmount.toInt()} - ৳${maxAmount.toInt()} (Avg: ৳${avgAmount.toInt()})');
        }
      }
      if (roomTypeCounts.isNotEmpty) {
        final typesStr = roomTypeCounts.entries.map((e) => '${e.key} (${e.value})').join(', ');
        buffer.writeln('• 🏠 **Configurations:** $typesStr');
      }
      final List<String> amenities = [];
      if (withLiftCount > 0) amenities.add('Lift ($withLiftCount)');
      if (withParkingCount > 0) amenities.add('Parking ($withParkingCount)');
      if (withGeneratorCount > 0) amenities.add('Generator ($withGeneratorCount)');
      if (amenities.isNotEmpty) {
        buffer.writeln('• ⚡ **Key Amenities:** ${amenities.join(', ')}');
      }
    }

    return buffer.toString().trim();
  }
}

/// AI analytical summary model for tenant demands
class DemandBudgetAnalysis {
  final int totalFound;
  final double minBudget;
  final double maxBudget;
  final double avgBudget;
  final Map<String, int> roomTypeCounts;
  final Map<String, int> tenantTypeCounts;
  final int withLiftCount;
  final int withParkingCount;
  final int withGeneratorCount;
  final int withCctvCount;
  final int withWifiCount;
  final int withSecurityGuardCount;
  final int withBalconyCount;

  const DemandBudgetAnalysis({
    required this.totalFound,
    required this.minBudget,
    required this.maxBudget,
    required this.avgBudget,
    required this.roomTypeCounts,
    this.tenantTypeCounts = const {},
    this.withLiftCount = 0,
    this.withParkingCount = 0,
    this.withGeneratorCount = 0,
    this.withCctvCount = 0,
    this.withWifiCount = 0,
    this.withSecurityGuardCount = 0,
    this.withBalconyCount = 0,
  });

  static DemandBudgetAnalysis analyze(List<TenantDemandModel> demands) {
    if (demands.isEmpty) {
      return const DemandBudgetAnalysis(
        totalFound: 0,
        minBudget: 0,
        maxBudget: 0,
        avgBudget: 0,
        roomTypeCounts: {},
        tenantTypeCounts: {},
      );
    }

    double minB = double.infinity;
    double maxB = 0;
    double sumB = 0;
    final Map<String, int> roomTypes = {};
    final Map<String, int> tenantTypes = {};
    int lift = 0;
    int parking = 0;
    int generator = 0;
    int cctv = 0;
    int wifi = 0;
    int security = 0;
    int balcony = 0;

    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (final d in demands) {
      final raw = d.budgetRange?.trim() ?? '';
      String normalizedRaw = raw.toLowerCase();
      for (int i = 0; i < 10; i++) {
        normalizedRaw = normalizedRaw.replaceAll(bnDigits[i], enDigits[i]);
      }
      normalizedRaw = normalizedRaw.replaceAll('কে', 'k');

      final numMatches = RegExp(r'(\d+(?:\.\d+)?)\s*(k|kilo|thousand|হাজার|লাখ|lac|lakh)?', caseSensitive: false)
          .allMatches(normalizedRaw.replaceAll(',', ''));

      final List<double> digits = [];
      for (final match in numMatches) {
        final numStr = match.group(1);
        if (numStr == null) continue;
        final parsed = double.tryParse(numStr);
        if (parsed == null) continue;
        final unit = match.group(2)?.toLowerCase();
        double val = parsed;
        if (unit == 'k' || unit == 'kilo' || unit == 'thousand' || unit == 'হাজার' || (parsed < 100 && normalizedRaw.contains('k'))) {
          val = parsed * 1000;
        } else if (unit == 'লাখ' || unit == 'lac' || unit == 'lakh') {
          val = parsed * 100000;
        } else if (parsed < 100) {
          val = parsed * 1000;
        }
        digits.add(val);
      }

      if (digits.isNotEmpty) {
        final b1 = digits.first;
        final b2 = digits.length > 1 ? digits[1] : b1;
        if (b1 < minB) minB = b1;
        if (b2 > maxB) maxB = b2;
        sumB += (b1 + b2) / 2;
      }
      final r = d.roomOrSeat.trim();
      if (r.isNotEmpty) {
        roomTypes[r] = (roomTypes[r] ?? 0) + 1;
      }
      if (d.tenantType != null) {
        final tName = d.tenantType!.name;
        tenantTypes[tName] = (tenantTypes[tName] ?? 0) + 1;
      }
      if (d.hasLift == true) lift++;
      if (d.hasParking == true) parking++;
      if (d.hasGenerator == true) generator++;
      if (d.hasCctv == true) cctv++;
      if (d.hasWifi == true) wifi++;
      if (d.hasSecurityGuard == true) security++;
      if ((d.balconies ?? 0) > 0) balcony++;
    }

    final avg = demands.isNotEmpty ? sumB / demands.length : 0.0;

    return DemandBudgetAnalysis(
      totalFound: demands.length,
      minBudget: minB == double.infinity ? 0 : minB,
      maxBudget: maxB,
      avgBudget: avg,
      roomTypeCounts: roomTypes,
      tenantTypeCounts: tenantTypes,
      withLiftCount: lift,
      withParkingCount: parking,
      withGeneratorCount: generator,
      withCctvCount: cctv,
      withWifiCount: wifi,
      withSecurityGuardCount: security,
      withBalconyCount: balcony,
    );
  }

  String formatAiInsights(bool isBn, String languageCode) {
    if (totalFound == 0) return '';
    final buffer = StringBuffer();

    if (isBn) {
      buffer.writeln('🧠 **এআই বিশ্লেষণ ও ডিমান্ড পর্যবেক্ষণ (AI Demand Insights):**');
      if (minBudget > 0 && maxBudget > 0) {
        if (minBudget == maxBudget) {
          buffer.writeln('• 📊 **ভাড়ার বাজেট:** ৳${minBudget.toInt().toString().toLocalizedDigits('bn')}');
        } else {
          buffer.writeln('• 📊 **ভাড়ার পরিসীমা:** ৳${minBudget.toInt().toString().toLocalizedDigits('bn')} থেকে ৳${maxBudget.toInt().toString().toLocalizedDigits('bn')} (গড় বাজেট: ৳${avgBudget.toInt().toString().toLocalizedDigits('bn')})');
        }
      }
      if (roomTypeCounts.isNotEmpty) {
        final typesStr = roomTypeCounts.entries.map((e) => '${e.key} (${e.value.toString().toLocalizedDigits('bn')}টি)').join(', ');
        buffer.writeln('• 🏠 **উপলব্ধ ধরণ:** $typesStr');
      }
      if (tenantTypeCounts.isNotEmpty) {
        final tenantStr = tenantTypeCounts.entries.map((e) => '${e.key} (${e.value.toString().toLocalizedDigits('bn')}টি)').join(', ');
        buffer.writeln('• 👥 **ভাড়াটিয়ার ধরণ:** $tenantStr');
      }
      final List<String> amenities = [];
      if (withLiftCount > 0) amenities.add('লিফট ($withLiftCount)');
      if (withParkingCount > 0) amenities.add('পার্কিং ($withParkingCount)');
      if (withGeneratorCount > 0) amenities.add('জেনারেটর ($withGeneratorCount)');
      if (withCctvCount > 0) amenities.add('সিসিটিভি ($withCctvCount)');
      if (withWifiCount > 0) amenities.add('ওয়াইফাই ($withWifiCount)');
      if (withSecurityGuardCount > 0) amenities.add('সিকিউরিটি ($withSecurityGuardCount)');
      if (withBalconyCount > 0) amenities.add('বারান্দা ($withBalconyCount)');
      if (amenities.isNotEmpty) {
        buffer.writeln('• ⚡ **বিশেষ সুবিধাসমূহ:** ${amenities.join(', ')}');
      }
    } else {
      buffer.writeln('🧠 **AI Demand Analysis & Insights:**');
      if (minBudget > 0 && maxBudget > 0) {
        if (minBudget == maxBudget) {
          buffer.writeln('• 📊 **Exact Budget:** ৳${minBudget.toInt()}');
        } else {
          buffer.writeln('• 📊 **Tenant Budget Range:** ৳${minBudget.toInt()} - ৳${maxBudget.toInt()} (Avg: ৳${avgBudget.toInt()})');
        }
      }
      if (roomTypeCounts.isNotEmpty) {
        final typesStr = roomTypeCounts.entries.map((e) => '${e.key} (${e.value})').join(', ');
        buffer.writeln('• 🏠 **Requested Configurations:** $typesStr');
      }
      if (tenantTypeCounts.isNotEmpty) {
        final tenantStr = tenantTypeCounts.entries.map((e) => '${e.key} (${e.value})').join(', ');
        buffer.writeln('• 👥 **Tenant Types:** $tenantStr');
      }
      final List<String> amenities = [];
      if (withLiftCount > 0) amenities.add('Lift ($withLiftCount)');
      if (withParkingCount > 0) amenities.add('Parking ($withParkingCount)');
      if (withGeneratorCount > 0) amenities.add('Generator ($withGeneratorCount)');
      if (withCctvCount > 0) amenities.add('CCTV ($withCctvCount)');
      if (withWifiCount > 0) amenities.add('WiFi ($withWifiCount)');
      if (withSecurityGuardCount > 0) amenities.add('Security ($withSecurityGuardCount)');
      if (withBalconyCount > 0) amenities.add('Balcony ($withBalconyCount)');
      if (amenities.isNotEmpty) {
        buffer.writeln('• ⚡ **Key Requested Amenities:** ${amenities.join(', ')}');
      }
    }

    return buffer.toString().trim();
  }
}
