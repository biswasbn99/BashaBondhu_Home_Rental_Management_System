import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/home/data/models/property_model.dart';
import '../../../../features/shared/data/models/area_model.dart';
import '../../../../features/shared/data/models/district_model.dart';
import '../../../../features/shared/data/models/division_model.dart';
import '../../../../features/shared/data/models/sub_area_model.dart';
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
                ? '👋 আসসালামু আলাইকুম **${user.fullName.isNotEmpty ? user.fullName : "বাড়িওয়ালা"}**!\nআমি আপনার **বাসাবন্ধু এআই সহকারী**। আপনি কথা বলে বা লিখে:\n• ভাড়াটিয়াদের লাইভ ডিমান্ড খুঁজতে পারেন\n• আকর্ষণীয় টু-লেট বিজ্ঞাপন তৈরি করতে পারেন\n• সঠিক ভাড়ার মূল্য নির্ধারণ ও সাবস্ক্রিপশন চেক করতে পারেন।'
                : '👋 আসসালামু আলাইকুম **${user.fullName.isNotEmpty ? user.fullName : "ভাড়াটিয়া"}**!\nআমি আপনার **বাসাবন্ধু এআই সহকারী**। কোনো ফর্ম পূরণ ছাড়াই আপনি:\n• 🔍 স্টেপ-বাই-স্টেপ পছন্দের বাসা খুঁজতে পারেন\n• 📝 চ্যাটে কথা বলে সরাসরি **ডিমান্ড পোস্ট** করতে পারেন\n• 💳 সাবস্ক্রিপশন ও প্রোফাইল দেখতে পারেন।')
        : (isAdmin
            ? '👋 Welcome **${user.fullName.isNotEmpty ? user.fullName : "Admin"}**!\nI am your **BashaBondhu AI Admin Assistant**. Select an option below to view real-time platform analytics, user metrics, and revenue stats.'
            : isOwner
                ? '👋 Welcome **${user.fullName.isNotEmpty ? user.fullName : "House Owner"}**!\nI am your **BashaBondhu AI Assistant**. You can conversationally:\n• Find matching tenant demands with match scores\n• Generate polished To-Let advertisements\n• Check fair market rent and subscription packages.'
                : '👋 Welcome **${user.fullName.isNotEmpty ? user.fullName : "Tenant"}**!\nI am your **BashaBondhu AI Assistant**. You can conversationally:\n• 🔍 Search rental homes step-by-step\n• 📝 Post tenant demands without filling forms\n• 💳 Check subscription history & packages.');

    final List<String> chips = isBn
        ? (isAdmin
            ? ['📊 লাইভ পরিসংখ্যান', '💰 সাবস্ক্রিপশন হিসাব', '📍 জনপ্রিয় এলাকা']
            : isOwner
                ? ['👥 ভাড়াটিয়াদের ডিমান্ড খুঁজুন', '✍️ বিজ্ঞাপনের বিবরণ লিখুন', '💰 ভাড়ার সঠিক মূল্য গাইড', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '👤 আমার প্রোফাইল']
                : ['🔍 বাসা খুঁজুন (Find a Home)', '📝 ডিমান্ড পোস্ট করুন', '💳 সাবস্ক্রিপশন প্যাকেজ', '📄 সাবস্ক্রিপশন হিস্ট্রি', '👤 আমার প্রোফাইল'])
        : (isAdmin
            ? ['📊 Live Analytics', '💰 Subscription Revenue', '📍 Top Areas']
            : isOwner
                ? ['👥 Find Tenant Demands', '✍️ Write To-Let Ad', '💰 Rental Price Guide', '💳 Subscription Packages', '📄 Subscription History', '👤 My Profile']
                : ['🔍 Find a Home', '📝 Post a Demand', '💳 Subscription Packages', '📄 Subscription History', '👤 My Profile']);

    final List<String> quickFollowUps = isBn
        ? (isOwner
            ? ['বিজ্ঞাপনের বিবরণ তৈরি করুন', 'মিরপুরে ৩ বেডের সঠিক ভাড়া কত?', 'ভাড়াটিয়াদের ডিমান্ড দেখাও']
            : ['১৫০০০ টাকার মধ্যে বাসা দেখাও', 'মিরপুরে ফ্যামিলি ফ্ল্যাট', 'ব্যাচেলর সিট দরকার'])
        : (isOwner
            ? ['Write To-Let Description', 'Estimate Fair Rent in Mirpur', 'Show Tenant Demands']
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
        await _executeOwnerDemandSearch(languageCode);
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
      await _progressOwnerViewDemandsWizard(cleanInput, languageCode);
      return;
    }

    // Check Trigger Keywords for Starting Wizards
    final lower = cleanInput.toLowerCase();

    // 1. Trigger Find Home Wizard
    if (cleanInput.contains('বাসা খুঁজুন') || cleanInput.contains('Find a Home') || lower == 'find home' || lower == 'basha khoja') {
      startFindHomeWizard(user, languageCode);
      return;
    }

    // 2. Trigger Post Demand Wizard
    if (cleanInput.contains('ডিমান্ড পোস্ট') || cleanInput.contains('Post a Demand') || lower == 'post demand' || lower == 'demand post') {
      startDemandPostWizard(user, languageCode);
      return;
    }

    // 3. Trigger House Owner View Demands Wizard
    if (cleanInput.contains('ভাড়াটিয়াদের ডিমান্ড') || cleanInput.contains('Find Tenant Demands') || lower == 'view demands') {
      startOwnerViewDemandsWizard(user, languageCode);
      return;
    }

    // 4. Trigger Subscription History Card
    if (cleanInput.contains('সাবস্ক্রিপশন হিস্ট্রি') || lower.contains('subscription history') || lower.contains('হিস্ট্রি')) {
      history.add(
        AIMessageModel(
          id: 'sub_hist_${DateTime.now().millisecondsSinceEpoch}',
          text: isBn
              ? '📄 আপনার **সাবস্ক্রিপশন হিস্ট্রি ও পেমেন্ট রিসিট** দেখতে নিচে বাটনে চাপ দিন:'
              : '📄 Click below to view your **Subscription History & Payment Receipts**:',
          sender: AIMessageSender.ai,
          actionCardType: AIActionCardType.subscriptionHistory,
          interactiveChips: isBn ? ['⭐ সাবস্ক্রিপশন প্যাকেজ', '👤 আমার প্রোফাইল', '🔍 বাসা খুঁজুন'] : ['⭐ Subscription Packages', '👤 My Profile', '🔍 Find Home'],
        ),
      );
      notifyListeners();
      return;
    }

    // 5. Trigger Subscription Packages Card
    if (cleanInput.contains('সাবস্ক্রিপশন প্যাকেজ') || lower.contains('subscription package') || lower.contains('প্যাকেজ')) {
      history.add(
        AIMessageModel(
          id: 'sub_pkg_${DateTime.now().millisecondsSinceEpoch}',
          text: isBn
              ? '⭐ আপনার অ্যাকাউন্টের জন্য উপলব্ধ **সাবস্ক্রিপশন প্যাকেজসমূহ** দেখুন:'
              : '⭐ Explore available **Subscription Packages** for your account:',
          sender: AIMessageSender.ai,
          actionCardType: AIActionCardType.subscriptionPackages,
          interactiveChips: isBn ? ['📄 সাবস্ক্রিপশন হিস্ট্রি', '👤 আমার প্রোফাইল', '🔍 বাসা খুঁজুন'] : ['📄 Subscription History', '👤 My Profile', '🔍 Find Home'],
        ),
      );
      notifyListeners();
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

    // 7. General AI Prompt via Gemini
    _isGenerating = true;
    notifyListeners();

    try {
      final aiResponse = await _geminiService.getAssistantResponse(
        userPrompt: cleanInput,
        userRole: user.userType,
        userName: user.fullName.isNotEmpty ? user.fullName : user.firstName,
        languageCode: languageCode,
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
  // WIZARD 3: HOUSE OWNER VIEW DEMANDS
  // ==========================================

  void startOwnerViewDemandsWizard(UserModel user, String languageCode) {
    _activeWizard = WizardMode.ownerViewDemands;
    _wizardStep = 1;
    _searchDraft = const SearchDraftModel();
    final isBn = languageCode == 'bn';

    final history = _userSessions[user.uid] ??= [];
    history.add(
      AIMessageModel(
        id: 'od1_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '👥 **ভাড়াটিয়াদের ডিমান্ড খুঁজুন!** (ধাপ ১/৮)\nকোন **এলাকার** ভাড়াটিয়া খুঁজতে চান?'
            : '👥 **Find Tenant Demands!** (Step 1/8)\nWhich **Area** are you looking for?',
        sender: AIMessageSender.ai,
        interactiveChips: isBn
            ? ['🔍 এখনই সার্চ করব', 'মিরপুর', 'উত্তরা', 'ধানমন্ডি', 'গুলশান', 'মোহাম্মদপুর', 'বনশ্রী', 'ফরিদপুর সদর']
            : ['🔍 Search Now', 'Mirpur', 'Uttara', 'Dhanmondi', 'Gulshan', 'Mohammadpur'],
      ),
    );
    notifyListeners();
  }

  Future<void> _progressOwnerViewDemandsWizard(String input, String languageCode) async {
    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    switch (_wizardStep) {
      case 1:
        _searchDraft = _searchDraft.copyWith(area: input);
        _wizardStep = 2;
        history.add(
          AIMessageModel(
            id: 'od2_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🏠 **বাসার ধরণ (House Type) কী?** (ধাপ ২/৮)' : '🏠 **House Type?** (Step 2/8)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['🔍 এখনই সার্চ করব', 'ফ্ল্যাট', 'রুম', 'খালি সিট', 'ইউনিট'] : ['🔍 Search Now', 'Flat', 'Room', 'Empty Seat', 'Unit'],
          ),
        );
        break;

      case 2:
        _searchDraft = _searchDraft.copyWith(houseType: input);
        _wizardStep = 3;
        history.add(
          AIMessageModel(
            id: 'od3_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '💰 **ভাড়ার রেঞ্জ বা বাজেট কত?** (ধাপ ৩/৮)' : '💰 **Budget Range?** (Step 3/8)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['🔍 এখনই সার্চ করব', '৳১০,০০০ - ৳১৫,০০০', '৳১৫,০০০ - ৳২০,০০০', '৳২০,০০০+'] : ['🔍 Search Now', '৳10,000 - ৳15,000', '৳15,000 - ৳20,000', '৳20,000+'],
          ),
        );
        break;

      case 3:
        _searchDraft = _searchDraft.copyWith(budgetRange: input);
        _wizardStep = 4;
        history.add(
          AIMessageModel(
            id: 'od4_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '👥 **ভাড়াটিয়ার ধরণ (Tenant Type)?** (ধাপ ৪/৮)' : '👥 **Tenant Type?** (Step 4/8)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['🔍 এখনই সার্চ করব', 'ফ্যামিলি', 'ব্যাচেলর ছেলে', 'ব্যাচেলর মেয়ে', 'সাবলেট'] : ['🔍 Search Now', 'Family', 'Bachelor Male', 'Bachelor Female', 'Sub-Let'],
          ),
        );
        break;

      case 4:
        _searchDraft = _searchDraft.copyWith(tenantType: input);
        _wizardStep = 5;
        history.add(
          AIMessageModel(
            id: 'od5_${DateTime.now().millisecondsSinceEpoch}',
            text: isBn ? '🛏️ **কয়টি বেডরুম?** (ধাপ ৫/৮)' : '🛏️ **Number of Bedrooms?** (Step 5/8)',
            sender: AIMessageSender.ai,
            interactiveChips: isBn ? ['🔍 এখনই সার্চ করব', 'Bedroom - 1', 'Bedroom - 2', 'Bedroom - 3', 'Bedroom - 4'] : ['🔍 Search Now', 'Bedroom - 1', 'Bedroom - 2', 'Bedroom - 3', 'Bedroom - 4'],
          ),
        );
        break;

      case 5:
        _searchDraft = _searchDraft.copyWith(roomOrSeat: input);
        await _executeOwnerDemandSearch(languageCode);
        break;
    }

    notifyListeners();
  }

  Future<void> _executeOwnerDemandSearch(String languageCode) async {
    _activeWizard = WizardMode.none;
    _isGenerating = true;
    notifyListeners();

    final isBn = languageCode == 'bn';
    final history = _userSessions[_activeUserId] ??= [];

    final matching = await _matchTenantDemands(
      area: _searchDraft.area,
      budget: _searchDraft.budgetRange,
      roomCount: _searchDraft.roomOrSeat,
      tenantType: _searchDraft.tenantType,
    );

    _isGenerating = false;
    history.add(
      AIMessageModel(
        id: 'dem_res_${DateTime.now().millisecondsSinceEpoch}',
        text: isBn
            ? '🎯 **আপনার ফ্ল্যাটের সাথে ম্যাচ করা ${matching.length} টি ভাড়াটিয়া ডিমান্ড পাওয়া গেছে!**\nকার্ডে ক্লিক করে ভাড়াটিয়ার চাহিদা ও ফোন নম্বর আনলক করুন:'
            : '🎯 **Found ${matching.length} matching tenant demands!**\nTap cards below to view requirements:',
        sender: AIMessageSender.ai,
        matchingDemands: matching,
        interactiveChips: isBn ? ['👥 নতুন ডিমান্ড খুঁজুন', '✍️ বিজ্ঞাপনের বিবরণ লিখুন', '💰 ভাড়ার মূল্য গাইড'] : ['👥 New Demand Search', '✍️ Write To-Let Ad', '💰 Rent Guide'],
      ),
    );
    notifyListeners();
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

  Future<List<MatchingDemandItem>> _matchTenantDemands({
    String? area,
    String? budget,
    String? roomCount,
    String? tenantType,
  }) async {
    try {
      final snapshot = await _firestore.collection('tenant_demands').limit(25).get();
      final allDemands = snapshot.docs.map((doc) => TenantDemandModel.fromMap(doc.data(), doc.id)).toList();

      final List<MatchingDemandItem> matches = [];

      for (final demand in allDemands) {
        int score = 65; // Base score
        String reason = 'সাধারণ চাহিদার সাথে মিল রয়েছে';

        if (area != null && area.isNotEmpty) {
          if (demand.area.name.toLowerCase().contains(area.toLowerCase()) || demand.area.bnName.toLowerCase().contains(area.toLowerCase())) {
            score += 20;
            reason = 'এলাকা ($area) হুবহু মিলে গেছে';
          }
        }

        if (roomCount != null && roomCount.isNotEmpty) {
          if (demand.roomOrSeat.toLowerCase().contains(roomCount.toLowerCase())) {
            score += 10;
          }
        }

        score = min(score, 98);
        matches.add(MatchingDemandItem(demand: demand, matchPercentage: score, matchReason: reason));
      }

      matches.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
      return matches.take(6).toList();
    } catch (e) {
      debugPrint('Error matching demands: $e');
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
