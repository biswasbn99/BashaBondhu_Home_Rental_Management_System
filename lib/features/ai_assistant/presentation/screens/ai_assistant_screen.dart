import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/auth/data/providers/user_provider.dart';
import '../../../../features/subscription/data/models/free_tier_policy_model.dart';
import '../../../../features/subscription/data/providers/subscription_provider.dart';
import '../../../../features/subscription/presentation/screens/house_owner_subscription_screen.dart';
import '../../../../features/subscription/presentation/screens/tenant_subscription_screen.dart';
import '../providers/ai_assistant_provider.dart';
import '../widgets/ai_message_bubble.dart';

class AIAssistantScreen extends StatefulWidget {
  static const String name = '/ai-assistant';

  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FreeTierPolicyModel _currentPolicy = FreeTierPolicyModel.defaultPolicy();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      final lang = context.read<LocaleProvider>().currentLocale.languageCode;
      if (user != null) {
        context.read<AIAssistantProvider>().initializeForUser(user, lang);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showUpgradePlanPrompt(BuildContext context, UserModel user, bool isBn, int configuredLimit) {
    final isSub = user.isSubscribed;
    final limitStr = configuredLimit == -1
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : configuredLimit.toString().toLocalizedDigits(isBn ? 'bn' : 'en');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Colors.deepOrange, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isBn ? 'এআই লিমিট শেষ! প্ল্যান আপগ্রেড করুন' : 'AI Limit Reached! Upgrade Plan',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isSub
              ? (isBn
                  ? '⚠️ আপনার সাবস্ক্রিপশন প্যাকেজের এআই সহকারী ব্যবহারের কোটা শেষ হয়ে গেছে। নিরবচ্ছিন্ন এআই সহায়তা ও সকল অপশন ব্যবহারের জন্য অনুগ্রহ করে প্যাকেজ আপগ্রেড বা রিনিউ করুন।'
                  : '⚠️ You have reached the AI Assistant query limit for your subscription package. Please upgrade or renew your plan to continue using all AI features and options.')
              : (configuredLimit <= 0
                  ? (isBn
                      ? '⚠️ ফ্রি অ্যাকাউন্টে এআই সহকারী সুবিধা বন্ধ রয়েছে। এআই সহকারীর সকল অপশন ও সহায়তা পেতে অনুগ্রহ করে সাবস্ক্রিপশন প্যাকেজ গ্রহণ করুন।'
                      : '⚠️ AI Assistant is not available on the free tier. Please subscribe to a package to access all AI features.')
                  : (isBn
                      ? '⚠️ ফ্রি অ্যাকাউন্টে এআই সহকারী ব্যবহারের নির্ধারিত $limitStrটি ব্যবহারের লিমিট শেষ হয়ে গেছে। এআই সহকারীর সকল অপশন ও সুবিধা ব্যবহার করতে অনুগ্রহ করে একটি সাবস্ক্রিপশন প্ল্যান গ্রহণ বা আপগ্রেড করুন।'
                      : '⚠️ You have used all $limitStr of your free AI queries. Please upgrade to a subscription plan to continue using all AI features and options.')),
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'পরে' : 'Maybe Later'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.rocket_launch_rounded, size: 16),
            label: Text(
              isBn ? '💳 প্ল্যান আপগ্রেড করুন' : '💳 Upgrade Plan',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (user.isHouseOwner) {
                Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
              } else {
                Navigator.pushNamed(context, TenantSubscriptionScreen.name);
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleSend(String text, UserModel user, String languageCode) {
    final trimmed = text.trim();
    final isBn = languageCode == 'bn';
    final int configuredLimit = user.isSubscribed
        ? (user.activeSubscriptionPlans.isNotEmpty
            ? user.activeSubscriptionPlans.first.aiAssistantLimit
            : user.subscriptionMaxAiQueries)
        : (user.isHouseOwner ? _currentPolicy.ownerAiAssistant : _currentPolicy.tenantAiAssistant);

    final isPackagesReq = trimmed == '💳 সাবস্ক্রিপশন প্যাকেজ' ||
        trimmed == '💳 Subscription Packages' ||
        trimmed == '⭐ সাবস্ক্রিপশন প্যাকেজ' ||
        trimmed == '⭐ Subscription Packages' ||
        trimmed == '💳 প্যাকেজ' ||
        trimmed == '💳 Packages' ||
        trimmed == 'সাবস্ক্রিপশন প্যাকেজ' ||
        trimmed == 'Subscription Packages';

    if (isPackagesReq) {
      if (user.isHouseOwner) {
        Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
      } else {
        Navigator.pushNamed(context, TenantSubscriptionScreen.name);
      }
      return;
    }

    final bool canUse = user.canUseAiAssistantForRole(policy: _currentPolicy);
    if (!user.isAdmin && !canUse) {
      _showUpgradePlanPrompt(context, user, isBn, configuredLimit);
      return;
    }

    if (trimmed.isEmpty) return;
    _textController.clear();

    final lower = trimmed.toLowerCase();
    final isNav = lower.contains('package') ||
        lower.contains('সাবস্ক্রিপশন') ||
        lower.contains('প্যাকেজ') ||
        lower.contains('subscription') ||
        lower.contains('history') ||
        lower.contains('হিস্ট্রি') ||
        lower.contains('অপশন') ||
        lower.contains('option');

    context.read<AIAssistantProvider>().handleUserInput(
          text: trimmed,
          user: user,
          languageCode: languageCode,
          policy: _currentPolicy,
          onAiQueryConsumed: () {
            if (!user.isAdmin && !isNav) {
              context.read<SubscriptionProvider>().incrementAiQueryCount(context, user);
            }
          },
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final userProvider = context.watch<UserProvider>();
    final aiProvider = context.watch<AIAssistantProvider>();
    final subProvider = context.watch<SubscriptionProvider>();

    final user = userProvider.user ??
        UserModel(
          uid: 'sample_tenant',
          email: 'tenant@bashabondhu.com',
          firstName: 'Tenant',
          lastName: 'User',
          userType: 'Tenant',
          mobile: '01712345678',
          city: 'Dhaka',
        );

    final languageCode = localeProvider.currentLocale.languageCode;
    final isBn = languageCode == 'bn';
    final messages = aiProvider.messages;

    final isOwner = user.isHouseOwner;
    final isAdmin = user.isAdmin;

    return StreamBuilder<FreeTierPolicyModel>(
      stream: subProvider.streamFreeTierPolicy(),
      builder: (context, policySnap) {
        final policy = policySnap.data ?? FreeTierPolicyModel.defaultPolicy();
        _currentPolicy = policy;
        final bool canUseAi = user.canUseAiAssistantForRole(policy: policy);
        final int configuredLimit = user.isSubscribed
            ? (user.activeSubscriptionPlans.isNotEmpty
                ? user.activeSubscriptionPlans.first.aiAssistantLimit
                : user.subscriptionMaxAiQueries)
            : (user.isHouseOwner ? policy.ownerAiAssistant : policy.tenantAiAssistant);

        return Scaffold(
          appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00A896), AppColors.themeColor],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'বাসাবন্ধু এআই সহকারী' : 'BashaBondhu AI Assistant',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAdmin
                            ? (isBn ? 'অ্যাডমিন মোড • অনলাইন' : 'Admin Mode • Online')
                            : isOwner
                                ? (isBn ? 'বাড়িওয়ালা সহকারী • অনলাইন' : 'Owner Assistant • Online')
                                : (isBn ? 'ভাড়াটিয়া সহকারী • অনলাইন' : 'Tenant Assistant • Online'),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switch Button (বাং / EN)
          TextButton.icon(
            onPressed: () {
              final newLang = isBn ? 'en' : 'bn';
              localeProvider.changeLocale(Locale(newLang));
              aiProvider.initializeForUser(user, newLang);
            },
            icon: const Icon(Icons.translate_rounded, size: 16),
            label: Text(
              isBn ? 'English' : 'বাংলা',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          // Clear chat button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: isBn ? 'চ্যাট ক্লিয়ার করুন' : 'Clear Chat',
            onPressed: () {
              aiProvider.clearChat(user.uid, user, languageCode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AI Quota Status Bar
            _buildQuotaStatusBar(
              context: context,
              user: user,
              policy: policy,
              isDark: isDark,
              isBn: isBn,
              languageCode: languageCode,
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return AIMessageBubble(
                    message: msg,
                    user: user,
                    languageCode: languageCode,
                    onChipTapped: (chipText) {
                      _handleSend(chipText, user, languageCode);
                    },
                  );
                },
              ),
            ),

            // AI Generating Dots
            if (aiProvider.isGenerating) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.themeColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? 'এআই উত্তর তৈরি করছে...' : 'BashaBondhu AI is thinking...',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],

            // Persistent 4 Options Bar for House Owner
            if (isOwner) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162120) : const Color(0xFFEBF7F5),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF243432) : const Color(0xFFE2E9E7),
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                        label: Text(
                          isBn ? '⚡ প্রধান ৪টি অপশন' : '⚡ Main 4 Options',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () {
                          if (!user.isAdmin && !canUseAi) {
                            _showUpgradePlanPrompt(context, user, isBn, configuredLimit);
                            return;
                          }
                          aiProvider.showHouseOwner4Options(user, languageCode, policy);
                          _scrollToBottom();
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.themeColor),
                        label: Text(
                          isBn ? '👥 ভাড়াটিয়া ডিমান্ড' : '👥 Tenant Demands',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'ভাড়াটিয়াদের ডিমান্ড' : 'Find Tenant Demands', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.amber),
                        label: Text(
                          isBn ? '💡 প্রস্তাবিত ভাড়ার রেঞ্জ' : '💡 Suggest Price Range',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'প্রস্তাবিত ভাড়ার রেঞ্জ' : 'Suggest Price Range', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.card_membership_rounded, size: 14, color: Colors.orange),
                        label: Text(
                          isBn ? '💳 প্যাকেজ' : '💳 Packages',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাবস্ক্রিপশন প্যাকেজ' : 'Subscription Packages', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.history_rounded, size: 14, color: Colors.teal),
                        label: Text(
                          isBn ? '📄 হিস্ট্রি' : '📄 History',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাবস্ক্রিপশন হিস্ট্রি' : 'Subscription History', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.privacy_tip_outlined, size: 14, color: Colors.blueAccent),
                        label: Text(
                          isBn ? '🛡️ প্রাইভেসি পলিসি' : '🛡️ Privacy Policy',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'প্রাইভেসি পলিসি বলো' : 'Tell me Privacy Policy', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.support_agent_rounded, size: 14, color: Colors.purple),
                        label: Text(
                          isBn ? '🤝 সাপোর্ট পলিসি' : '🤝 Support Policy',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাপোর্ট পলিসি বলো' : 'Tell me Support Policy', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.gavel_rounded, size: 14, color: Colors.indigo),
                        label: Text(
                          isBn ? '📜 শর্তাবলী' : '📜 Terms & Conditions',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'শর্তাবলী বলো' : 'Tell me Terms & Conditions', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.currency_exchange_rounded, size: 14, color: Colors.deepOrange),
                        label: Text(
                          isBn ? '💳 রিফান্ড পলিসি' : '💳 Refund Policy',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'রিফান্ড পলিসি বলো' : 'Tell me Refund Policy', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.help_outline_rounded, size: 14, color: Colors.cyan),
                        label: Text(
                          isBn ? '❓ সাধারণ জিজ্ঞাসা' : '❓ FAQ',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাধারণ জিজ্ঞাসা' : 'FAQ', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.menu_book_rounded, size: 14, color: Colors.teal),
                        label: Text(
                          isBn ? '📖 কীভাবে অ্যাপ ব্যবহার করবেন' : '📖 How to Use',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'বাড়িওয়ালা হিসেবে কীভাবে অ্যাপ ব্যবহার করব?' : 'How to use this app as a house owner?', user, languageCode),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Persistent 3 Options Bar for Tenant
            if (!isOwner && !isAdmin) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162120) : const Color(0xFFEBF7F5),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF243432) : const Color(0xFFE2E9E7),
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
                        label: Text(
                          isBn ? '⚡ প্রধান ৩টি অপশন' : '⚡ Main 3 Options',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: AppColors.themeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () {
                          if (!user.isAdmin && !canUseAi) {
                            _showUpgradePlanPrompt(context, user, isBn, configuredLimit);
                            return;
                          }
                          aiProvider.showTenant3Options(user, languageCode, policy);
                          _scrollToBottom();
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.search_rounded, size: 14, color: AppColors.themeColor),
                        label: Text(
                          isBn ? '🔍 বাসা খুঁজুন' : '🔍 Find Home',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'বাসা খুঁজুন' : 'Find Home', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.card_membership_rounded, size: 14, color: Colors.orange),
                        label: Text(
                          isBn ? '💳 প্যাকেজ' : '💳 Packages',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাবস্ক্রিপশন প্যাকেজ' : 'Subscription Packages', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.history_rounded, size: 14, color: Colors.teal),
                        label: Text(
                          isBn ? '📄 হিস্ট্রি' : '📄 History',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাবস্ক্রিপশন হিস্ট্রি' : 'Subscription History', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.privacy_tip_outlined, size: 14, color: Colors.blueAccent),
                        label: Text(
                          isBn ? '🛡️ প্রাইভেসি পলিসি' : '🛡️ Privacy Policy',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'প্রাইভেসি পলিসি বলো' : 'Tell me Privacy Policy', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.support_agent_rounded, size: 14, color: Colors.purple),
                        label: Text(
                          isBn ? '🤝 সাপোর্ট পলিসি' : '🤝 Support Policy',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাপোর্ট পলিসি বলো' : 'Tell me Support Policy', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.gavel_rounded, size: 14, color: Colors.indigo),
                        label: Text(
                          isBn ? '📜 শর্তাবলী' : '📜 Terms & Conditions',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'শর্তাবলী বলো' : 'Tell me Terms & Conditions', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.currency_exchange_rounded, size: 14, color: Colors.deepOrange),
                        label: Text(
                          isBn ? '💳 রিফান্ড পলিসি' : '💳 Refund Policy',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'রিফান্ড পলিসি বলো' : 'Tell me Refund Policy', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.help_outline_rounded, size: 14, color: Colors.cyan),
                        label: Text(
                          isBn ? '❓ সাধারণ জিজ্ঞাসা' : '❓ FAQ',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'সাধারণ জিজ্ঞাসা' : 'FAQ', user, languageCode),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.menu_book_rounded, size: 14, color: Colors.teal),
                        label: Text(
                          isBn ? '📖 কীভাবে অ্যাপ ব্যবহার করবেন' : '📖 How to Use',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        onPressed: () => _handleSend(isBn ? 'ভাড়াটিয়া হিসেবে কীভাবে অ্যাপ ব্যবহার করব?' : 'How to use this app as a tenant?', user, languageCode),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D1C) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF243432) : const Color(0xFFE2E9E7),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Text Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2C2A) : const Color(0xFFF3F7F6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C3E3B) : const Color(0xFFE2E9E7),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(fontSize: 13.5),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) => _handleSend(val, user, languageCode),
                        decoration: InputDecoration(
                          hintText: !isAdmin && !canUseAi
                              ? (isBn
                                  ? '⚠️ এআই কোটা শেষ! নতুন প্রশ্ন করতে প্ল্যান আপগ্রেড করুন'
                                  : '⚠️ AI quota reached! Upgrade plan to continue')
                              : (!isAdmin
                                  ? (isBn
                                      ? 'এলাকা বা ভাড়ার রেঞ্জ লিখুন (যেমন: মিরপুর বা ১০-১৫ হাজার)'
                                      : 'Write area or price range (e.g. Mirpur or 10k-15k)')
                                  : (isBn
                                      ? 'প্রশ্ন বা রিকোয়ারমেন্ট লিখুন (যেমন: মিরপুরে ২ বেড বাসা)'
                                      : 'Ask anything or type requirements...')),
                          hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleSend(_textController.text, user, languageCode),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.themeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
}

  Widget _buildQuotaStatusBar({
    required BuildContext context,
    required UserModel user,
    required FreeTierPolicyModel policy,
    required bool isDark,
    required bool isBn,
    required String languageCode,
  }) {
    if (user.isAdmin) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        child: Row(
          children: [
            const Icon(Icons.shield_rounded, size: 15, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              isBn ? 'অ্যাডমিন অ্যাকাউন্ট: সীমাহীন এআই সহকারী এক্সেস' : 'Admin Account: Unlimited AI Assistant Access',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ],
        ),
      );
    }

    final isSub = user.isSubscribed;
    final canUse = user.canUseAiAssistantForRole(policy: policy);
    final remaining = user.remainingAiQueriesForRole(policy: policy);
    final isUnlimited = remaining >= 999;
    final remainingStr = remaining.toString().toLocalizedDigits(languageCode);

    final int configuredLimit = isSub
        ? (user.activeSubscriptionPlans.isNotEmpty
            ? user.activeSubscriptionPlans.first.aiAssistantLimit
            : user.subscriptionMaxAiQueries)
        : (user.isHouseOwner ? policy.ownerAiAssistant : policy.tenantAiAssistant);
    final limitStr = configuredLimit == -1
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : configuredLimit.toString().toLocalizedDigits(languageCode);

    final Color bg = !canUse
        ? (isDark ? const Color(0xFF351A1A) : const Color(0xFFFEF2F2))
        : (isSub
            ? (isDark ? const Color(0xFF132A26) : const Color(0xFFF0FDFA))
            : (isDark ? const Color(0xFF2E2413) : const Color(0xFFFFFBEB)));
    final Color borderCol = !canUse
        ? Colors.redAccent.withValues(alpha: 0.35)
        : (isSub
            ? const Color(0xFF0D9488).withValues(alpha: 0.35)
            : Colors.amber.shade700.withValues(alpha: 0.35));
    final Color textCol = !canUse
        ? Colors.redAccent
        : (isSub ? const Color(0xFF0D9488) : (isDark ? Colors.amber.shade300 : Colors.amber.shade900));

    String statusTitle;
    if (!canUse) {
      statusTitle = isBn
          ? (isSub
              ? '⚠️ প্যাকেজের এআই কোটা শেষ! আপগ্রেড করুন'
              : (configuredLimit <= 0
                  ? '⚠️ ফ্রি অ্যাকাউন্টে এআই বন্ধ। প্ল্যান নিন'
                  : '⚠️ ফ্রি এআই কোটা শেষ! ($limitStrটির সব ব্যবহৃত)'))
          : (isSub
              ? '⚠️ Plan AI quota exhausted! Upgrade'
              : (configuredLimit <= 0
                  ? '⚠️ AI disabled for free tier. Subscribe'
                  : '⚠️ Free AI quota exhausted ($limitStr used)'));
    } else if (isUnlimited) {
      statusTitle = isBn
          ? (isSub
              ? '⭐ প্রিমিয়াম: আনলিমিটেড এআই এক্সেস'
              : '🆓 ফ্রি অ্যাকাউন্ট: আনলিমিটেড এআই সুবিধা')
          : (isSub
              ? '⭐ Premium: Unlimited AI Queries'
              : '🆓 Free Tier: Unlimited AI Queries');
    } else {
      statusTitle = isBn
          ? (isSub
              ? '⭐ প্রিমিয়াম এআই: বাকি $remainingStrটি (মোট $limitStrটি)'
              : '🆓 ফ্রি এআই কোটা: বাকি $remainingStrটি (মোট $limitStrটি)')
          : (isSub
              ? '⭐ Premium AI: $remainingStr left of $limitStr'
              : '🆓 Free AI Quota: $remainingStr left of $limitStr');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: borderCol, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            !canUse
                ? Icons.lock_outline_rounded
                : (isSub ? Icons.verified_rounded : Icons.auto_awesome_rounded),
            size: 16,
            color: textCol,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textCol,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (user.isHouseOwner) {
                Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
              } else {
                Navigator.pushNamed(context, TenantSubscriptionScreen.name);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !canUse ? Colors.redAccent : (isSub ? const Color(0xFF0D9488) : Colors.deepOrange),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    !canUse ? Icons.rocket_launch_rounded : Icons.star_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isBn
                        ? (!canUse ? 'আপগ্রেড' : (isSub ? 'প্ল্যান' : 'আপগ্রেড'))
                        : (!canUse ? 'Upgrade' : (isSub ? 'Plans' : 'Upgrade')),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
