import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/subscription_model.dart';
import '../screens/payment_gateway_screen.dart';
import '../screens/sslcommerz_webview_screen.dart';

class PaymentMethodBottomSheet {
  static void show({
    required BuildContext context,
    required SubscriptionPlanModel plan,
    required UserModel user,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Plan Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'পেমেন্ট মেথড নির্বাচন করুন' : 'Select Payment Method',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isBn ? (plan.titleBn.isNotEmpty ? plan.titleBn : plan.titleEn) : (plan.titleEn.isNotEmpty ? plan.titleEn : plan.titleBn)} • ${isBn ? "৳${plan.effectivePrice.toInt().toString().toLocalizedDigits('bn')}" : "৳${plan.effectivePrice.toInt()}"} (${isBn ? (plan.durationBn.isNotEmpty ? plan.durationBn : "${plan.durationDays.toString().toLocalizedDigits('bn')} দিন") : (plan.durationEn.isNotEmpty ? plan.durationEn : "${plan.durationDays} Days")})',
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isBn ? '৳${plan.effectivePrice.toInt().toString().toLocalizedDigits('bn')}' : '৳${plan.effectivePrice.toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.themeColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Option 1: SSLCOMMERZ Sandbox Gateway (Official)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SSLCommerzWebviewScreen(
                      plan: plan,
                      user: user,
                      isSandbox: true,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                        : [const Color(0xFFF1F5F9), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.payment_rounded, color: Color(0xFF6366F1), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'SSLCOMMERZ Gateway',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SANDBOX',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isBn
                                ? 'bKash, Nagad, Rocket, Visa, Mastercard, DBBL ও অন্যান্য'
                                : 'bKash, Nagad, Rocket, Visa, Mastercard, DBBL & more',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Direct bKash Personal (01746300498)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentGatewayScreen(
                      plan: plan,
                      user: user,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1526) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2136E).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2136E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE2136E), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Direct bKash (01746300498)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isBn
                                ? 'বিকাশ নম্বর ➔ ওটিপি (OTP) ➔ পিন দিয়ে সরাসরি পরিশোধ'
                                : 'Pay directly via bKash Number ➔ OTP ➔ PIN',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

