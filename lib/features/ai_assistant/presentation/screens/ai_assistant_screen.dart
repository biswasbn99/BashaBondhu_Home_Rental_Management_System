import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../features/auth/data/providers/user_provider.dart';
import '../../../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../../../features/shared/presentation/widgets/app_bar.dart';
import '../providers/ai_assistant_provider.dart';
import '../widgets/ai_message_bubble.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  static const String name = '/ai-assistant';

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      final languageCode = Localizations.localeOf(context).languageCode;
      if (user != null) {
        context.read<AIAssistantProvider>().initializeForUser(user, languageCode);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final user = context.read<UserProvider>().user;
    final languageCode = Localizations.localeOf(context).languageCode;
    if (user == null) return;

    _textController.clear();
    context.read<AIAssistantProvider>().sendMessage(
      text: clean,
      user: user,
      languageCode: languageCode,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final aiProvider = context.watch<AIAssistantProvider>();

    // 🔒 GUEST ACCESS GUARD
    if (user == null || userProvider.isGuest) {
      return Scaffold(
        appBar: MainAppBar(
          title: Text(isBn ? 'বাসাবন্ধু এআই' : 'BashaBondhu AI'),
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 56, color: AppColors.themeColor),
                ),
                const SizedBox(height: 20),
                Text(
                  isBn ? 'লগইন আবশ্যক' : 'Login Required',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isBn
                      ? 'বাসাবন্ধু এআই সহকারী ব্যবহার করতে অনুগ্রহ করে আপনার একাউন্টে লগইন করুন।'
                      : 'BashaBondhu AI Assistant is available for registered users. Please log in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, SignInScreen.name),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(isBn ? 'লগইন করুন' : 'Sign In'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAdmin = user.isAdmin;
    final isOwner = user.isHouseOwner;

    final roleLabel = isAdmin
        ? (isBn ? 'অ্যাডমিন সহকারী' : 'Admin Assistant')
        : isOwner
            ? (isBn ? 'বাড়িওয়ালা সহকারী' : 'House Owner Assistant')
            : (isBn ? 'ভাড়াটিয়া সহকারী' : 'Tenant Assistant');

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.themeColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isBn ? 'বাসাবন্ধু এআই' : 'BashaBondhu AI',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isBn ? 'চ্যাট মুছে ফেলুন' : 'Clear Chat',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              aiProvider.clearChat(user, languageCode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isBn ? 'চ্যাট রিসেট করা হয়েছে' : 'Chat cleared'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Message Stream List ---
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: aiProvider.messages.length,
                itemBuilder: (context, index) {
                  final msg = aiProvider.messages[index];
                  return AIMessageBubble(
                    message: msg,
                    isDark: isDark,
                    languageCode: languageCode,
                  );
                },
              ),
            ),

            // --- Voice Recording Live Wave Banner ---
            if (aiProvider.isListening)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiProvider.spokenText.isNotEmpty
                            ? aiProvider.spokenText
                            : (isBn ? 'কথা শুনছি... মুখে বলুন' : 'Listening... speak now'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop_circle_rounded, color: Colors.red, size: 22),
                      onPressed: () => aiProvider.stopListening(),
                    ),
                  ],
                ),
              ),

            // --- Quick Suggestion Action Chips ---
            if (aiProvider.currentSuggestions.isNotEmpty && !aiProvider.isGenerating)
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: aiProvider.currentSuggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final suggestion = aiProvider.currentSuggestions[index];
                    return ActionChip(
                      label: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.tealAccent[100] : AppColors.themeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: isDark
                          ? AppColors.themeColor.withValues(alpha: 0.15)
                          : AppColors.themeColor.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: AppColors.themeColor.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _handleSend(suggestion),
                    );
                  },
                ),
              ),

            // --- Bottom Input Bar ---
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2827) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Microphone Speech-to-Text Button
                  IconButton(
                    icon: Icon(
                      aiProvider.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: aiProvider.isListening ? Colors.red : AppColors.themeColor,
                    ),
                    onPressed: () {
                      if (aiProvider.isListening) {
                        aiProvider.stopListening();
                      } else {
                        aiProvider.startListening(
                          languageCode: languageCode,
                          onFinalText: (text) {
                            _handleSend(text);
                          },
                        );
                      }
                    },
                  ),

                  // Text Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _handleSend,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isAdmin
                              ? (isBn ? 'পরিসংখ্যান বা তথ্য জানতে লিখুন...' : 'Ask about stats, users, revenue...')
                              : isOwner
                                  ? (isBn ? 'বিজ্ঞাপন, ভাড়া বা ভাড়াটিয়া খুঁজতে লিখুন...' : 'Ask about ads, rent, tenants...')
                                  : (isBn ? 'কোথায় কেমন বাসা খুঁজছেন বা ডিমান্ড...' : 'Search home, budget or demand...'),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _handleSend(_textController.text),
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
