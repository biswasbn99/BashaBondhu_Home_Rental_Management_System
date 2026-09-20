import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/app/utils/privacy_helper.dart';
import 'package:bashabondhu_home_rental_management_system/features/ai_assistant/presentation/widgets/ai_floating_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/services/tenant_demand_firestore_service.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/language_action_button.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/post_icon.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/data/models/free_tier_policy_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/data/providers/subscription_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/presentation/screens/house_owner_subscription_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/show_demand_details_screen.dart';

class TenantDemandShowScreen extends StatefulWidget {
  const TenantDemandShowScreen({super.key});

  static const String name = '/tenant-demand-show';

  @override
  State<TenantDemandShowScreen> createState() => _TenantDemandShowScreenState();
}

class _TenantDemandShowScreenState extends State<TenantDemandShowScreen> {
  final TenantDemandFirestoreService _firestoreService = TenantDemandFirestoreService();
  late final Stream<List<TenantDemandModel>> _demandsStream;

  @override
  void initState() {
    super.initState();
    _demandsStream = _firestoreService.streamAllDemands();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final bool isGuest = userProvider.isGuest;
    final bool isOwner = userProvider.user?.userType == 'House Owner';

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        titleSpacing: (isGuest || isOwner) ? 12 : 20,
        actions: [
          if (isGuest)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: FreePostButton(),
            ),
          const LanguageActionButton(),
        ],
      ),
      floatingActionButton: const AIFloatingButton(),
      body: StreamBuilder<List<TenantDemandModel>>(
        stream: _demandsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            );
          }

          final demands = snapshot.data ?? [];

          if (demands.isEmpty) {
            return _buildEmptyState(context, l10n, theme);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: demands.length,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _DemandCard(demand: demands[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic l10n, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_late_outlined,
                size: 64,
                color: AppColors.themeColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noDemandsFoundTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noDemandsFoundSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandCard extends StatelessWidget {
  const _DemandCard({required this.demand});

  final TenantDemandModel demand;

  void _handleUnlock(BuildContext context, UserModel? user, [FreeTierPolicyModel? policy]) {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final l10n = context.localizations;
    final languageCode = Localizations.localeOf(context).languageCode;

    if (!user.canUnlockContactForPolicy(policy: policy)) {
      final ownerLimit = (policy?.ownerUnlockNumbers ?? 2).toString().toLocalizedDigits(languageCode);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBn ? 'ভাড়াটিয়ার নম্বর আনলক সীমা শেষ' : 'Tenant Unlock Limit Reached',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            user.isSubscribed
                ? (isBn
                    ? 'আপনার বাড়িওয়ালা সাবস্ক্রিপশন প্যাকেজের ভাড়াটিয়া নম্বর আনলক করার কোটা শেষ হয়ে গেছে। আরও নম্বর দেখতে প্যাকেজ রিনিউ বা আপগ্রেড করুন।'
                    : 'Your package tenant contact unlock quota has been exhausted. Please renew or upgrade your plan.')
                : (isBn
                    ? 'আপনার ফ্রি $ownerLimitটি ভাড়াটিয়ার নম্বর আনলক শেষ হয়ে গেছে। ভাড়াটিয়াদের সম্পূর্ণ ফোন ও হোয়াটসঅ্যাপ নম্বর দেখতে বাড়িওয়ালা সাপোর্ট প্যাকেজ গ্রহণ করুন।'
                    : 'You have used your $ownerLimit free tenant contact unlocks. Please subscribe to unlock more tenant contacts.'),
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isBn ? 'পরে' : 'Maybe Later'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
              },
              child: Text(isBn ? 'প্যাকেজ দেখুন' : 'View Packages'),
            ),
          ],
        ),
      );
      return;
    }

    final remaining = user.remainingContactUnlocksForPolicy(policy: policy);
    final remainingStr = remaining >= 999999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);
    final totalLimit = policy?.ownerUnlockNumbers ?? 2;
    final totalLimitStr = totalLimit == -1
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : totalLimit.toString().toLocalizedDigits(languageCode);

    final dialogContent = user.isSubscribed
        ? (isBn
            ? 'আপনি কি ১টি ক্রেডিট ব্যবহার করে এই ভাড়াটিয়ার সম্পূর্ণ ফোন ও হোয়াটসঅ্যাপ নম্বর আনলক করতে চান?\n\n(আপনার প্যাকেজে আনলক বাকি: $remainingStr)'
            : 'Do you want to use 1 package credit to unlock this tenant\'s phone & WhatsApp numbers?\n\n(Package unlocks remaining: $remainingStr)')
        : l10n.unlockDemandDialogContent(remainingStr, totalLimitStr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: AppColors.themeColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.unlockDemandDialogTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
            ),
          ],
        ),
        content: Text(
          dialogContent,
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.no),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final subProvider = context.read<SubscriptionProvider>();
              final ok = await subProvider.unlockDemand(context, user, demand.id);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.unlockDemandSuccessMessage),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(l10n.yesUnlock),
          ),
        ],
      ),
    );
  }

  void _handleUnlockSubArea(BuildContext context, UserModel? user, FreeTierPolicyModel policy) {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final languageCode = Localizations.localeOf(context).languageCode;
    final canUnlock = user.canUnlockSubAreaForOwner(policy: policy);

    if (!canUnlock) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBn ? 'সাব-এরিয়া আনলক সীমা শেষ' : 'Sub-Area Unlock Limit Reached',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            user.isSubscribed
                ? (isBn
                    ? 'আপনার বাড়িওয়ালা প্যাকেজের সাব-এরিয়া লোকেশন আনলক করার কোটা শেষ হয়ে গেছে। আরও দেখতে প্যাকেজ রিনিউ বা আপগ্রেড করুন।'
                    : 'Your owner package sub-area unlock quota has been exhausted. Please renew or upgrade your plan.')
                : (isBn
                    ? (policy.ownerSubAreaUnlocks <= 0
                        ? 'ফ্রি অ্যাকাউন্টে সাব-এরিয়া লোকেশন সুবিধা অন্তর্ভুক্ত নেই। ভাড়াটিয়ার চাহিদার সাব-এরিয়া ও ঠিকানা দেখতে বাড়িওয়ালা সাবস্ক্রিপশন প্যাকেজ গ্রহণ করুন।'
                        : 'আপনার ফ্রি ${policy.ownerSubAreaUnlocks}টি সাব-এরিয়া আনলক শেষ হয়ে গেছে। আরও দেখতে বাড়িওয়ালা সাবস্ক্রিপশন প্যাকেজ গ্রহণ করুন।')
                    : 'You have exhausted your free demand sub-area unlocks. Please subscribe to unlock more demand locations.'),
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isBn ? 'পরে' : 'Maybe Later'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
              },
              child: Text(isBn ? 'প্যাকেজ দেখুন' : 'View Packages'),
            ),
          ],
        ),
      );
      return;
    }

    final remaining = user.remainingOwnerSubAreaUnlocks(policy: policy);
    final remainingStr = remaining >= 999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);

    final dialogContent = user.isSubscribed
        ? (isBn
            ? 'আপনি কি ১টি ক্রেডিট ব্যবহার করে এই ভাড়ার চাহিদার সাব-এরিয়া লোকেশন ও ঠিকানা আনলক করতে চান?\n\n(আপনার প্যাকেজে সাব-এরিয়া আনলক বাকি: $remainingStr টি)'
            : 'Do you want to use 1 package credit to unlock this tenant demand\'s sub-area location?\n\n(Package sub-area unlocks remaining: $remainingStr)')
        : (isBn
            ? 'আপনি কি ১টি ফ্রি ক্রেডিট ব্যবহার করে এই ভাড়ার চাহিদার সাব-এরিয়া লোকেশন আনলক করতে চান?\n\n(আপনার ফ্রি সাব-এরিয়া আনলক বাকি: $remainingStr টি)'
            : 'Do you want to use 1 free credit to unlock this tenant demand\'s sub-area location?\n\n(Free sub-area unlocks remaining: $remainingStr)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.location_city_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBn ? 'সাব-এরিয়া লোকেশন আনলক করুন' : 'Unlock Demand Sub-Area',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
              ),
            ),
          ],
        ),
        content: Text(
          dialogContent,
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'না' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
            onPressed: () async {
              Navigator.pop(ctx);
              final subProvider = context.read<SubscriptionProvider>();
              final ok = await subProvider.unlockDemandSubArea(context, user, demand.id);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBn
                          ? 'ভাড়ার চাহিদার সাব-এরিয়া লোকেশন সফলভাবে আনলক হয়েছে!'
                          : 'Demand sub-area unlocked successfully!',
                    ),
                    backgroundColor: const Color(0xFFD97706),
                  ),
                );
              }
            },
            child: Text(isBn ? 'হ্যাঁ, আনলক করুন' : 'Yes, Unlock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isGuest = userProvider.isGuest || user == null;
    final policy = context.watch<SubscriptionProvider>().currentPolicy ?? FreeTierPolicyModel.defaultPolicy();

    final isOwnerOfDemand = user?.uid == demand.tenantId;
    final isUnlocked = isOwnerOfDemand ||
        PrivacyHelper.isDemandUnlocked(
          demandId: demand.id,
          isGuest: isGuest,
          isSubscribed: user?.isSubscribed ?? false,
          unlockedDemandIds: user?.unlockedDemandIds ?? [],
        );

    final subAreaName = demand.subArea?.getLocalizedName(languageCode) ?? '';
    final areaName = demand.area.getLocalizedName(languageCode);
    final districtName = demand.district.getLocalizedName(languageCode);

    final bool isSubAreaUnlocked = isOwnerOfDemand ||
        (user != null && user.isDemandSubAreaUnlocked(demand.id, policy: policy, tenantId: demand.tenantId));

    final locationText = PrivacyHelper.formatLocationWithPrivacy(
      subAreaName: subAreaName,
      areaName: areaName,
      districtName: districtName,
      isUnlocked: isSubAreaUnlocked,
      isGuest: isGuest,
      languageCode: languageCode,
    );

    final String displayMobile = isUnlocked ? demand.userMobile : PrivacyHelper.maskPhoneNumber(demand.userMobile);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
                  child: Text(
                    demand.userName.isNotEmpty ? demand.userName[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      color: AppColors.themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            demand.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              languageCode == 'bn' ? 'ভাড়াটিয়া' : 'Tenant',
                              style: const TextStyle(
                                color: AppColors.themeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildTenantVerificationBadge(demand.tenantVerificationStatus, languageCode, isDark),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(demand.postDate, languageCode),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Budget
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      demand.budgetRange != null
                          ? '৳ ${(demand.budgetRange!).toLocalizedDigits(languageCode)}'
                          : '৳ -',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.themeColor,
                      ),
                    ),
                    Text(
                      demand.month.getLocalizedMonth(l10n),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Main Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // House Type & Room
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${demand.houseType.getLocalizedLabel(l10n)} • ${demand.roomOrSeat.getLocalizedRoomOrSeat(l10n)}',
                        style: const TextStyle(
                          color: AppColors.themeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (demand.tenantType != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          demand.tenantType!.getLocalizedLabel(l10n),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.themeColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (!isSubAreaUnlocked && subAreaName.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _handleUnlockSubArea(context, user, policy),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD97706), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_open_rounded, size: 11, color: Color(0xFFD97706)),
                              const SizedBox(width: 3),
                              Text(
                                languageCode == 'bn' ? 'সাব-এরিয়া আনলক' : 'Unlock Sub-Area',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Contact Row (Masked if locked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        displayMobile,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.bold,
                          color: isUnlocked ? theme.colorScheme.onSurfaceVariant : Colors.amber.shade800,
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade700, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, size: 10, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                l10n.locked,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (demand.userWhatsApp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.chat_outlined, size: 14, color: Color(0xFF25D366)),
                      const SizedBox(width: 6),
                      Text(
                        '${languageCode == "bn" ? "হোয়াটসঅ্যাপ" : "WhatsApp"}: ${isUnlocked ? demand.userWhatsApp : PrivacyHelper.maskPhoneNumber(demand.userWhatsApp)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? const Color(0xFF16A34A) : Colors.amber.shade800,
                          fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.bold,
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock_rounded, size: 10, color: Colors.amber),
                      ],
                    ],
                  ),
                ],

                if (demand.detailedDescription.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    demand.detailedDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contact Actions Bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900]!.withValues(alpha: 0.5) : Colors.grey[50]!,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (!isUnlocked) ...[
                  Builder(
                    builder: (context) {
                      final bool canUnlock = !isGuest && user.canUnlockContactForPolicy(policy: policy);
                      return Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: (!isGuest && !canUnlock)
                                ? Colors.deepOrange
                                : Colors.amber.shade800,
                            side: BorderSide(
                              color: (!isGuest && !canUnlock)
                                  ? Colors.deepOrange
                                  : Colors.amber.shade700,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _handleUnlock(context, user, policy),
                          icon: Icon(
                            (!isGuest && !canUnlock)
                                ? Icons.workspace_premium_rounded
                                : Icons.lock_open_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isGuest
                                ? l10n.loginToUnlockInfo
                                : (!canUnlock
                                    ? (languageCode == 'bn' ? 'প্যাকেজ আপগ্রেড করুন' : 'Upgrade Plan')
                                    : (user.isSubscribed
                                        ? (languageCode == 'bn'
                                            ? 'প্যাকেজে আনলক (${user.remainingContactUnlocksForPolicy(policy: policy) >= 999999 ? "আনলিমিটেড" : user.remainingContactUnlocksForPolicy(policy: policy).toString().toLocalizedDigits("bn")})'
                                            : 'Unlock with Plan (${user.remainingContactUnlocksForPolicy(policy: policy) >= 999999 ? "Unlimited" : user.remainingContactUnlocksForPolicy(policy: policy)})')
                                        : l10n.unlockInfoAndNumberWithQuotaOwner(
                                            user.remainingContactUnlocksForPolicy(policy: policy).toString().toLocalizedDigits(languageCode),
                                            (policy.ownerUnlockNumbers == -1)
                                                ? (languageCode == 'bn' ? 'আনলিমিটেড' : 'Unlimited')
                                                : policy.ownerUnlockNumbers.toString().toLocalizedDigits(languageCode),
                                          ))),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // Call Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.themeColor,
                        side: const BorderSide(color: AppColors.themeColor),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _launchCaller(demand.userMobile),
                      icon: const Icon(Icons.call_rounded, size: 16),
                      label: Text(l10n.callNow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (demand.userWhatsApp.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    // WhatsApp Button
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(8),
                      ),
                      onPressed: () => _launchWhatsApp(demand.userWhatsApp),
                      icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                    ),
                  ],
                ],
                const SizedBox(width: 8),
                // View Details Button
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ShowDemandDetailsScreen.name,
                        arguments: demand,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(l10n.viewDetails, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantVerificationBadge(String status, String languageCode, bool isDark) {
    final isBn = languageCode == 'bn';
    final normalized = status.toLowerCase();

    if (normalized == 'verified') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF10B981)),
            const SizedBox(width: 3),
            Text(
              isBn ? 'ভেরিফাইড' : 'Verified',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    } else if (normalized == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 11, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(
              isBn ? 'পেন্ডিং' : 'Pending',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gpp_bad_outlined, size: 11, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            const SizedBox(width: 3),
            Text(
              isBn ? 'আনভেরিফাইড' : 'Unverified',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchCaller(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date, String languageCode) {
    final diff = DateTime.now().difference(date);
    final isBn = languageCode == 'bn';
    if (diff.inMinutes < 60) {
      return isBn
          ? '${diff.inMinutes.toString().toLocalizedDigits("bn")} মিনিট আগে'
          : '${diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return isBn
          ? '${diff.inHours.toString().toLocalizedDigits("bn")} ঘন্টা আগে'
          : '${diff.inHours} hours ago';
    } else {
      return isBn
          ? '${diff.inDays.toString().toLocalizedDigits("bn")} দিন আগে'
          : '${diff.inDays} days ago';
    }
  }
}
