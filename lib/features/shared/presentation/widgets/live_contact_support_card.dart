import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../data/providers/app_settings_provider.dart';

class LiveContactSupportCard extends StatelessWidget {
  const LiveContactSupportCard({super.key});

  Future<void> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch $uri: $e');
    }
  }

  void _callPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isNotEmpty) {
      _launch(Uri(scheme: 'tel', path: clean));
    }
  }

  void _openWhatsApp(String phone, bool isBn) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isNotEmpty) {
      final msg = isBn
          ? 'আসসালামু আলাইকুম বাসাবন্ধু হেল্পডেস্ক। আমার একটি জিজ্ঞাসা / সহায়তা প্রয়োজন।'
          : 'Hello BashaBondhu Support, I need assistance.';
      final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(msg)}');
      _launch(uri);
    }
  }

  void _sendEmail(String email, bool isBn) {
    if (email.isNotEmpty) {
      final subject = isBn ? 'বাসাবন্ধু গ্রাহক সেবা সহায়তা' : 'BashaBondhu Customer Support Request';
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': subject},
      );
      _launch(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<AppSettingsProvider>();
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    final helpline = settings.helpline.isNotEmpty ? settings.helpline : '+880 1700-000000';
    final whatsapp = settings.whatsappNumber.isNotEmpty ? settings.whatsappNumber : '+8801700000000';
    final email = settings.supportEmail.isNotEmpty ? settings.supportEmail : 'support@bashabondhu.com';
    final officeAddress = settings.officeAddress.isNotEmpty ? settings.officeAddress : 'House 12, Road 5, Dhanmondi, Dhaka - 1205';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF132824), const Color(0xFF0C1B18)]
              : [const Color(0xFFE8F7F2), const Color(0xFFD6F0E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.themeColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.themeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'সরাসরি হেল্পলাইন ও কাস্টমার কেয়ার' : 'Direct Helpline & Customer Care',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBn
                          ? 'যেকোনো জিজ্ঞাসা বা সহযোগিতায় আমরা পাশে আছি'
                          : 'Official assistance for all your rental queries',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Phone Button
              ActionChip(
                avatar: const Icon(Icons.phone_rounded, size: 15, color: Colors.white),
                label: Text(
                  helpline,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: AppColors.themeColor,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => _callPhone(helpline),
              ),

              // WhatsApp Button
              ActionChip(
                avatar: const Icon(Icons.chat_rounded, size: 15, color: Colors.white),
                label: Text(
                  isBn ? 'হোয়াটসঅ্যাপ' : 'WhatsApp',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: const Color(0xFF25D366),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => _openWhatsApp(whatsapp, isBn),
              ),

              // Email Button
              ActionChip(
                avatar: Icon(
                  Icons.email_outlined,
                  size: 15,
                  color: isDark ? Colors.grey[200] : const Color(0xFF2D3748),
                ),
                label: Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[200] : const Color(0xFF2D3748),
                  ),
                ),
                backgroundColor: isDark ? Colors.grey[800]! : Colors.white,
                side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => _sendEmail(email, isBn),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Office Address Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFFEA580C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBn ? 'অফিস ঠিকানা:' : 'Office Address:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        officeAddress,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[200] : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
