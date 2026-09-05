import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../admin/data/services/admin_firestore_service.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../shared/presentation/providers/main_nav_holder_provider.dart';
import '../../../shared/presentation/screens/main_nav_holder_screen.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';

class AccountSuspendedScreen extends StatefulWidget {
  const AccountSuspendedScreen({super.key});

  static const String name = '/account-suspended';

  @override
  State<AccountSuspendedScreen> createState() => _AccountSuspendedScreenState();
}

class _AccountSuspendedScreenState extends State<AccountSuspendedScreen> {
  final _appealFormKey = GlobalKey<FormState>();
  final _appealNoteController = TextEditingController();
  final _appealContactController = TextEditingController();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  bool _isSubmitting = false;
  bool _showAppealForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      if (user != null) {
        if (_appealContactController.text.isEmpty) {
          _appealContactController.text = user.mobile.isNotEmpty ? user.mobile : user.email;
        }
      }
    });
  }

  @override
  void dispose() {
    _appealNoteController.dispose();
    _appealContactController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal(String uid, bool isBn) async {
    if (!_appealFormKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _adminService.submitUserAppeal(
        uid,
        note: _appealNoteController.text.trim(),
        contact: _appealContactController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _showAppealForm = false;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn
                  ? 'আপনার আনব্লক আবেদন সফলভাবে জমা দেওয়া হয়েছে! অ্যাডমিন পর্যালোচনা করবেন।'
                  : 'Your reclaim appeal has been submitted! Admin will review shortly.',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBn
                  ? 'আবেদন জমা দিতে ব্যর্থ হয়েছে: $e'
                  : 'Failed to submit appeal: $e',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _launchUrlHelper(Uri uri) async {
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

  void _callHelpline(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    _launchUrlHelper(Uri(scheme: 'tel', path: cleanPhone));
  }

  void _chatWhatsApp(String phone, String userEmail, bool isBn) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = isBn
        ? 'আসসালামু আলাইকুম বাসাবন্ধু হেল্পডেস্ক। আমার একাউন্ট ($userEmail) সাময়িকভাবে স্থগিত রয়েছে। আনব্লক করতে সহায়তা প্রয়োজন।'
        : 'Hello BashaBondhu Support, my account ($userEmail) is currently suspended. I request assistance for unblocking.';
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
    _launchUrlHelper(uri);
  }

  void _emailSupport(String email, String userEmail, String userName, bool isBn) {
    final subject = isBn
        ? 'বাসাবন্ধু একাউন্ট আনব্লক আবেদন - $userName ($userEmail)'
        : 'BashaBondhu Account Reclaim Request - $userName ($userEmail)';
    final body = isBn
        ? 'আসসালামু আলাইকুম অ্যাডমিন টিম,\n\nআমার নাম: $userName\nইমেইল: $userEmail\n\nআমার একাউন্ট স্থগিত করা হয়েছে। আমি নিম্নোক্ত কারণে একাউন্ট পুনর্বহালের জন্য অনুরোধ করছি:\n\n[এখানে আপনার কারণ ও বিস্তারিত লিখুন]\n\nধন্যবাদ,\n$userName'
        : 'Dear Admin Team,\n\nName: $userName\nEmail: $userEmail\n\nMy account has been suspended. I request you to review and reinstate my account for the following reason:\n\n[Please enter your explanation here]\n\nRegards,\n$userName';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );
    _launchUrlHelper(uri);
  }

  void _showLogoutDialog(BuildContext context, bool isBn) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F201D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              isBn ? 'লগআউট নিশ্চিত করুন' : 'Confirm Sign Out',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          isBn
              ? 'আপনি কি এই একাউন্ট থেকে লগআউট করতে চান?'
              : 'Are you sure you want to sign out from this account?',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await AuthService().signOut();
              if (context.mounted) {
                context.read<UserProvider>().clearUser();
                context.read<MainNavHolderProvider>().resetIndex();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  MainNavHolderScreen.name,
                  (route) => false,
                );
              }
            },
            child: Text(isBn ? 'লগআউট' : 'Sign Out', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final isBn = localeProvider.currentLocale.languageCode == 'bn';
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    // Palette definitions
    final bg = isDark ? const Color(0xFF0A1513) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0F201D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final String name = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : "${user?.firstName ?? ''} ${user?.lastName ?? ''}".trim();
    final String email = user?.email ?? '';
    final String userType = user?.userType == 'House Owner'
        ? (isBn ? 'বাড়িওয়ালা' : 'House Owner')
        : (isBn ? 'ভাড়াটিয়া' : 'Tenant');
    final String reason = user?.blockReason.isNotEmpty == true
        ? user!.blockReason
        : (isBn ? 'নীতিমালা লঙ্ঘন বা সন্দেহজনক কার্যকলাপের কারণে' : 'Policy violation or suspicious activity');
    final String appealStatus = user?.appealStatus ?? 'none';

    return StreamBuilder<Map<String, dynamic>>(
      stream: _adminService.streamSettings(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data ?? {};
        final helpline = settings['helpline'] as String? ?? '+880 1700-000000';
        final whatsapp = settings['whatsappNumber'] as String? ?? '+8801700000000';
        final supportEmail = settings['supportEmail'] as String? ?? 'support@bashabondhu.com';

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: cardBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            centerTitle: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isBn ? 'একাউন্ট সাসপেন্ডেড' : 'Account Suspended',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              const LanguageActionButton(),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                tooltip: isBn ? 'লগআউট' : 'Sign Out',
                onPressed: () => _showLogoutDialog(context, isBn),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- 1. Suspension Warning Banner ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF3F1010), const Color(0xFF220707)]
                            : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: isDark ? 0.4 : 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.redAccent, width: 2),
                          ),
                          child: const Icon(Icons.block_flipped, color: Colors.redAccent, size: 34),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isBn ? 'আপনার একাউন্টটি সাময়িকভাবে স্থগিত করা হয়েছে' : 'Your Account Has Been Suspended',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFECDD3) : const Color(0xFF9F1239),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isBn
                              ? 'নিরাপত্তা ও কমিউনিটি নির্দেশিকা রক্ষার স্বার্থে অ্যাডমিন টিম আপনার একাউন্টের কার্যকারিতা সাময়িকভাবে বন্ধ রেখেছে।'
                              : 'To protect safety and enforce platform guidelines, the admin team has temporarily restricted your account activities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // --- 2. User & Reason Summary Card ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
                              child: Text(
                                user?.initials ?? 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.themeColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isNotEmpty ? name : 'User',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: titleColor),
                                  ),
                                  Text(
                                    '$email • $userType',
                                    style: TextStyle(fontSize: 11.5, color: subtitleColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 14),

                        // Reason Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBn ? 'স্থগিতের কারণ (Reason):' : 'Suspension Reason:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: subtitleColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.amber.shade300 : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // --- 3. Appeal / Reclaim Section ---
                  _buildAppealSection(context, user?.uid ?? '', appealStatus, user?.appealFeedback ?? '', isBn, isDark, cardBg, borderColor, titleColor, subtitleColor),
                  const SizedBox(height: 18),

                  // --- 4. Direct Support Touchpoints ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'সরাসরি কাস্টমার সাপোর্টে যোগাযোগ করুন' : 'Direct Support Channels',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: titleColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBn
                              ? 'জরুরি সহায়তার জন্য আমাদের হেল্পলাইন বা হোয়াটসঅ্যাপে সরাসরি যোগাযোগ করুন।'
                              : 'For urgent assistance, reach out directly to our support desk.',
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons Grid
                        Row(
                          children: [
                            // Helpline Call Button
                            Expanded(
                              child: InkWell(
                                onTap: () => _callHelpline(helpline),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.themeColor.withValues(alpha: isDark ? 0.2 : 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.themeColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.call_rounded, color: AppColors.themeColor, size: 22),
                                      const SizedBox(height: 6),
                                      Text(
                                        isBn ? 'কল করুন' : 'Call Helpline',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // WhatsApp Chat Button
                            Expanded(
                              child: InkWell(
                                onTap: () => _chatWhatsApp(whatsapp, email, isBn),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.2 : 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
                                      const SizedBox(height: 6),
                                      Text(
                                        isBn ? 'হোয়াটসঅ্যাপ' : 'WhatsApp',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF25D366)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Email Support Button
                            Expanded(
                              child: InkWell(
                                onTap: () => _emailSupport(supportEmail, email, name, isBn),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.mail_rounded, color: Color(0xFF0284C7), size: 22),
                                      const SizedBox(height: 6),
                                      Text(
                                        isBn ? 'ইমেইল করুন' : 'Email Support',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 5. Sign Out Footer Button ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        isBn ? 'অন্য একাউন্টে লগইন করুন (লগআউট)' : 'Sign Out / Switch Account',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: () => _showLogoutDialog(context, isBn),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppealSection(
    BuildContext context,
    String uid,
    String status,
    String feedback,
    bool isBn,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    if (status == 'pending') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1C06) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn ? 'আনব্লক আবেদন পর্যালোচনায় রয়েছে (Under Review)' : 'Reclaim Appeal Under Review',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isBn
                  ? 'আপনার আবেদনটি আমাদের অ্যাডমিন প্যানেলে গৃহীত হয়েছে। খুব শীঘ্রই তথ্য যাচাই করে আপনার একাউন্টটি পুনরায় সচল করা হবে।'
                  : 'Your unblock appeal is currently being reviewed by administration. You will be notified as soon as a decision is made.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: isDark ? Colors.amber.shade200 : const Color(0xFF78350F),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'rejected' && !_showAppealForm) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF290808) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isBn ? 'পূর্ববর্তী আবেদন অনুমোদিত হয়নি' : 'Previous Appeal Not Approved',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? const Color(0xFFFECDD3) : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
            if (feedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E0808) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'অ্যাডমিন মন্তব্য: ' : 'Admin Note: ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    Expanded(
                      child: Text(
                        feedback,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  isBn ? 'সঠিক তথ্য দিয়ে পুনরায় আবেদন করুন' : 'Submit New Reclaim Appeal',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => setState(() => _showAppealForm = true),
              ),
            ),
          ],
        ),
      );
    }

    // Default: Appeal Form
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Form(
        key: _appealFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mark_email_read_rounded, color: AppColors.themeColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBn ? 'একাউন্ট আনব্লক / রিক্লেইম আবেদন' : 'Submit Reclaim / Unblock Appeal',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: titleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isBn
                  ? 'আপনার একাউন্টটি ভুলবশত স্থগিত হয়ে থাকলে বা সংশোধিত তথ্য থাকলে নিচের ফর্মে কারণ উল্লেখ করে জমা দিন।'
                  : 'If your account was suspended in error or you have resolved the issue, submit an appeal for admin review.',
              style: TextStyle(fontSize: 12, height: 1.4, color: subtitleColor),
            ),
            const SizedBox(height: 14),

            // Explanation note field
            Text(
              isBn ? 'পুনর্বহালের কারণ ও বিস্তারিত ব্যাখ্যা *' : 'Reason / Explanation for Unblock *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: titleColor),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _appealNoteController,
              maxLines: 3,
              style: TextStyle(fontSize: 13, color: titleColor),
              decoration: InputDecoration(
                hintText: isBn
                    ? 'যেমন: আমি নিয়ম অনুযায়ী সব তথ্য ঠিক করেছি, অনুগ্রহ করে আমার একাউন্টটি সচল করুন...'
                    : 'Explain why your account should be reinstated...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 8) {
                  return isBn ? 'অনুগ্রহ করে অন্তত ৮ অক্ষরের ব্যাখ্যা লিখুন' : 'Please provide at least 8 characters explanation';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Contact field
            Text(
              isBn ? 'যোগাযোগের মোবাইল নম্বর বা ইমেইল *' : 'Contact Phone or Email *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: titleColor),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _appealContactController,
              style: TextStyle(fontSize: 13, color: titleColor),
              decoration: InputDecoration(
                hintText: isBn ? 'আপনার মোবাইল নম্বর বা ইমেইল' : 'Your phone or email address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return isBn ? 'অনুগ্রহ করে যোগাযোগের নম্বর/ইমেইল দিন' : 'Please provide contact information';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSubmitting
                      ? (isBn ? 'জমা দেওয়া হচ্ছে...' : 'Submitting Appeal...')
                      : (isBn ? 'আবেদন জমা দিন' : 'Submit Unblock Appeal'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                onPressed: _isSubmitting ? null : () => _submitAppeal(uid, isBn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
