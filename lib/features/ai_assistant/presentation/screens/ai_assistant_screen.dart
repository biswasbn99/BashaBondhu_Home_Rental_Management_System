import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../../features/auth/data/models/user_model.dart';
import '../../../../features/auth/data/providers/user_provider.dart';
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

  void _handleSend(String text, UserModel user, String languageCode) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    context.read<AIAssistantProvider>().handleUserInput(
          text: text,
          user: user,
          languageCode: languageCode,
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
            // Voice Wave Listening Indicator
            if (aiProvider.isListening) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withValues(alpha: 0.15),
                      Colors.orangeAccent.withValues(alpha: 0.15),
                    ],
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        aiProvider.spokenText.isNotEmpty
                            ? '🎙️ "${aiProvider.spokenText}"'
                            : (isBn ? '🎙️ শুনছি... মুখে বাংলায় বা ইংরেজিতে বলুন' : '🎙️ Listening... Speak now'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent, size: 22),
                      onPressed: () => aiProvider.stopListening(),
                    ),
                  ],
                ),
              ),
            ],

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
                          aiProvider.showHouseOwner4Options(user, languageCode);
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

            // Input Bar & Voice Mic
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
                  // Voice Mic Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (aiProvider.isListening) {
                          aiProvider.stopListening();
                        } else {
                          aiProvider.startListening(languageCode, (finalText) {
                            _handleSend(finalText, user, languageCode);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: aiProvider.isListening
                              ? Colors.redAccent
                              : AppColors.themeColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          aiProvider.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: aiProvider.isListening ? Colors.white : AppColors.themeColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

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
                          hintText: isBn
                              ? 'প্রশ্ন লিখুন বা বলুন (যেমন: মিরপুরে ২ বেড বাসা)'
                              : 'Ask anything or type requirements...',
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
  }
}
