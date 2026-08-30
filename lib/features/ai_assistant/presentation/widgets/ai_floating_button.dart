import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/app_colors.dart';
import '../../../../features/auth/data/providers/user_provider.dart';
import '../../../../features/auth/presentation/widgets/auth_prompt_dialog.dart';
import '../screens/ai_assistant_screen.dart';

class AIFloatingButton extends StatelessWidget {
  const AIFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isBn = languageCode == 'bn';
    final userProvider = context.watch<UserProvider>();
    final isGuest = userProvider.isGuest || userProvider.user == null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (isGuest) {
              AuthPromptDialog.show(
                context,
                requiredRole: 'Tenant',
                customMessage: isBn
                    ? 'বাসাবন্ধু এআই সহকারী ব্যবহার করতে অনুগ্রহ করে আপনার ভাড়াটিয়া বা বাড়িওয়ালা একাউন্টে লগইন করুন।'
                    : 'Please log in to your Tenant or House Owner account to use BashaBondhu AI Assistant.',
              );
            } else {
              Navigator.pushNamed(context, AIAssistantScreen.name);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00A896), AppColors.themeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  isBn ? 'বাসাবন্ধু এআই' : 'BashaBondhu AI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
