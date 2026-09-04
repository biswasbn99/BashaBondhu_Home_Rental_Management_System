import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../../data/models/subscription_model.dart';
import '../../data/providers/subscription_provider.dart';

class SubscriptionHistoryScreen extends StatelessWidget {
  const SubscriptionHistoryScreen({
    super.key,
    this.user,
  });

  final UserModel? user;

  static const String name = '/subscription-history';

  void _showReceiptDialog(BuildContext context, SubscriptionTransactionModel tx, bool isDark) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final rawDateStr = '${tx.purchasedAt.day}/${tx.purchasedAt.month}/${tx.purchasedAt.year} • ${tx.purchasedAt.hour}:${tx.purchasedAt.minute.toString().padLeft(2, '0')}';
    final rawExpiryStr = '${tx.expiresAt.day}/${tx.expiresAt.month}/${tx.expiresAt.year}';
    final dateStr = isBn ? rawDateStr.toLocalizedDigits('bn') : rawDateStr;
    final expiryStr = isBn ? rawExpiryStr.toLocalizedDigits('bn') : rawExpiryStr;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo & Title
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFE2136E), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                isBn ? 'বিকাশ ডিজিটাল পেমেন্ট রসিদ' : 'bKash Digital Payment Receipt',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              const Text(
                'BashaBondhu Payment Gateway',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              _buildDialogRow(isBn ? 'রিসিভার একাউন্ট:' : 'Receiver Account:', '01746300498'),
              const SizedBox(height: 8),
              _buildDialogRow(isBn ? 'প্রেরক নম্বর:' : 'Sender Phone:', tx.senderPhone),
              const SizedBox(height: 8),
              _buildDialogRow(isBn ? 'পেমেন্ট মেথড:' : 'Payment Method:', tx.paymentMethod),
              const SizedBox(height: 8),
              _buildDialogRow(isBn ? 'প্যাকেজ:' : 'Plan Name:', tx.planTitle),
              const SizedBox(height: 8),
              _buildDialogRow(isBn ? 'পরিশোধিত অর্থ:' : 'Amount Paid:', isBn ? '৳ ${tx.amountPaid.toInt().toString().toLocalizedDigits('bn')}' : '৳ ${tx.amountPaid.toInt()}'),
              const SizedBox(height: 8),
              _buildDialogRow(isBn ? 'লেনদেন আইডি:' : 'Trx ID:', tx.transactionId),
              const SizedBox(height: 8),
              _buildDialogRow(isBn ? 'পেমেন্টের সময়:' : 'Payment Date:', dateStr),
              const SizedBox(height: 8),
              _buildDialogRow(isBn ? 'মেয়াদ উত্তীর্ণ:' : 'Expires At:', expiryStr),
              const SizedBox(height: 8),
              _buildDialogRow(
                isBn ? 'পেমেন্ট স্ট্যাটাস:' : 'Status:',
                tx.status.toUpperCase(),
                valueColor: tx.status.toLowerCase() == 'active' || tx.status.toLowerCase() == 'completed' ? Colors.green : Colors.orange,
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isBn ? 'বন্ধ করুন' : 'Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final userProvider = context.watch<UserProvider>();
    final currentUser = user ?? userProvider.user;
    final subProvider = context.watch<SubscriptionProvider>();

    if (currentUser == null) {
      return Scaffold(
        appBar: MainAppBar(
          automaticallyImplyLeading: true,
          actions: const [
            LanguageActionButton(),
          ],
        ),
        body: Center(child: Text(isBn ? 'অনুগ্রহ করে প্রথমে লগইন করুন' : 'Please log in first')),
      );
    }

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.subscriptionHistory,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: const [
          LanguageActionButton(),
        ],
      ),
      body: StreamBuilder<List<SubscriptionTransactionModel>>(
        stream: subProvider.streamUserTransactions(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: AppColors.themeColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isBn ? 'কোনো সাবস্ক্রিপশন রেকর্ড পাওয়া যায়নি' : 'No subscription records found',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isBn
                          ? 'আপনি কোনো প্যাকেজ অ্যাক্টিভ করলে তার সম্পূর্ণ লেনদেন ও মেয়াদের তথ্য এখানে দেখতে পারবেন।'
                          : 'When you activate a package, all transaction records and validity details will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = list[index];
              final isExpired = item.expiresAt.isBefore(DateTime.now());
              final rawPurchase = '${item.purchasedAt.day}/${item.purchasedAt.month}/${item.purchasedAt.year} • ${item.purchasedAt.hour}:${item.purchasedAt.minute.toString().padLeft(2, '0')}';
              final rawExpiry = '${item.expiresAt.day}/${item.expiresAt.month}/${item.expiresAt.year}';
              final formattedPurchase = isBn ? rawPurchase.toLocalizedDigits('bn') : rawPurchase;
              final formattedExpiry = isBn ? rawExpiry.toLocalizedDigits('bn') : rawExpiry;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2624) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF263936) : const Color(0xFFE2EBE9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Plan title & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.planTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Colors.grey.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isExpired ? (isBn ? 'মেয়াদোত্তীর্ণ' : 'Expired') : (isBn ? 'সক্রিয়' : 'Active'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.grey[600] : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Amount & Payment Method
                    Row(
                      children: [
                        Text(
                          isBn ? '৳${item.amountPaid.toInt().toString().toLocalizedDigits('bn')}' : '৳${item.amountPaid.toInt()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.themeColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2136E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'bKash',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE2136E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // TrxID and Sender Phone
                    _buildRow('bKash TrxID:', item.transactionId, isHighlight: true),
                    const SizedBox(height: 4),
                    _buildRow(isBn ? 'প্রেরক নম্বর:' : 'Sender Phone:', item.senderPhone),
                    const SizedBox(height: 4),
                    _buildRow(isBn ? 'ক্রয়ের তারিখ ও সময়:' : 'Purchase Date:', formattedPurchase),
                    const SizedBox(height: 4),
                    _buildRow(isBn ? 'মেয়াদ শেষ:' : 'Expires At:', formattedExpiry),

                    const SizedBox(height: 12),

                    // View Digital Receipt Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showReceiptDialog(context, item, isDark),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE2136E),
                          side: const BorderSide(color: Color(0xFFE2136E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.receipt_rounded, size: 16),
                        label: Text(isBn ? 'ডিজিটাল রসিদ দেখুন' : 'View Digital Receipt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFFE2136E) : null,
          ),
        ),
      ],
    );
  }
}
