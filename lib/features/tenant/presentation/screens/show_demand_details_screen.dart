import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/app/utils/privacy_helper.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/models/user_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/decorated_section_header.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/data/models/free_tier_policy_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/data/providers/subscription_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/presentation/screens/house_owner_subscription_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';

class ShowDemandDetailsScreen extends StatelessWidget {
  const ShowDemandDetailsScreen({super.key, required this.demand});

  final TenantDemandModel demand;

  static const String name = '/show-demand-details';

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
                    ? 'আপনার বাড়িওয়ালা সাবস্ক্রিপশন প্যাকেজের ভাড়াটিয়া নম্বর আনলক করার কোটা শেষ হয়ে গেছে। আরও নম্বর দেখতে অনুগ্রহ করে প্যাকেজ রিনিউ বা আপগ্রেড করুন।'
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

  Widget _buildDemandSubAreaLockedCard(
    BuildContext context,
    UserModel? user,
    bool isDark,
    bool isBn,
    FreeTierPolicyModel policy,
  ) {
    final canUnlock = user?.canUnlockSubAreaForOwner(policy: policy) ?? false;
    final remaining = user?.remainingOwnerSubAreaUnlocks(policy: policy) ?? 0;
    final languageCode = Localizations.localeOf(context).languageCode;
    final remainingStr = remaining >= 999
        ? (isBn ? 'আনলিমিটেড' : 'Unlimited')
        : remaining.toString().toLocalizedDigits(languageCode);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2210) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, size: 18, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBn ? 'ভাড়াটিয়ার সাব-এরিয়া লোকেশন লক করা' : 'Demand Sub-Area Locked',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  user == null
                      ? (isBn ? 'লগইন করে সাব-এরিয়া আনলক করুন' : 'Log in to unlock sub-area')
                      : (canUnlock
                          ? (isBn
                              ? 'ভাড়াটিয়ার নির্দিষ্ট পাড়া/এলাকা দেখতে আনলক করুন (বাকি: $remainingStr টি)'
                              : 'Unlock to view exact neighborhood ($remainingStr left)')
                          : (isBn
                              ? 'সাব-এরিয়া আনলক লিমিট শেষ। আপগ্রেড করুন।'
                              : 'Sub-area unlock limit reached. Upgrade to unlock.')),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 14),
            label: Text(
              isBn ? 'সাব-এরিয়া আনলক' : 'Unlock Sub-Area',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _handleUnlockSubArea(context, user, policy),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final bool isBn = languageCode == 'bn';
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isGuest = userProvider.isGuest || user == null;
    final isHouseOwner = user?.isHouseOwner ?? false;
    final subProvider = context.watch<SubscriptionProvider>();

    return StreamBuilder<FreeTierPolicyModel>(
      stream: subProvider.streamFreeTierPolicy(),
      builder: (context, policySnap) {
        final policy = policySnap.data ?? FreeTierPolicyModel.defaultPolicy();

        // Check unlock state: If tenant created it, they can view full info; If house owner, check unlock quota / subscription
        final isOwnerOfDemand = user?.uid == demand.tenantId;
        final isUnlocked = isOwnerOfDemand ||
            PrivacyHelper.isDemandUnlocked(
              demandId: demand.id,
              isGuest: isGuest,
              isSubscribed: user?.isSubscribed ?? false,
              unlockedDemandIds: user?.unlockedDemandIds ?? [],
            );
        final isSubAreaUnlocked = isOwnerOfDemand ||
            (user != null && user.isDemandSubAreaUnlocked(demand.id, policy: policy, tenantId: demand.tenantId));

        final String displayMobile = isUnlocked ? demand.userMobile : PrivacyHelper.maskPhoneNumber(demand.userMobile);
        final String displayWhatsApp = isUnlocked ? demand.userWhatsApp : PrivacyHelper.maskPhoneNumber(demand.userWhatsApp);

        return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.viewDetails,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Profile ---
            _buildUserHeader(context, theme, l10n, displayMobile, displayWhatsApp, isUnlocked),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // --- Accommodation Section ---
                  DecoratedSectionHeader(title: l10n.accommodationPromptTitle),
                  const SizedBox(height: 16),
                  _DetailTile(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.month,
                    value: demand.month.getLocalizedMonth(l10n),
                  ),
                  _DetailTile(
                    icon: Icons.home_work_outlined,
                    label: l10n.houseType,
                    value: demand.houseType.getLocalizedLabel(l10n),
                  ),
                  _DetailTile(
                    icon: Icons.bed_outlined,
                    label: l10n.roomOrSeat,
                    value: demand.roomOrSeat.getLocalizedRoomOrSeat(l10n),
                  ),
                  if (demand.floorNumber != null && demand.floorNumber! > 0)
                    _DetailTile(
                      icon: Icons.layers_outlined,
                      label: isBn ? 'ফ্লোর নম্বর' : 'Floor Number',
                      value: '${demand.floorNumber!.toLocalizedDigits(languageCode)} ${isBn ? 'তলা' : 'Floor'}',
                    ),

                  const SizedBox(height: 28),

                  // --- Location Section (Division, District, Area, Sub-Area) ---
                  DecoratedSectionHeader(title: l10n.locationLabel),
                  const SizedBox(height: 16),
                  _DetailTile(
                    icon: Icons.map_outlined,
                    label: l10n.division,
                    value: demand.division.getLocalizedName(languageCode),
                  ),
                  _DetailTile(
                    icon: Icons.location_city_rounded,
                    label: l10n.district,
                    value: demand.district.getLocalizedName(languageCode),
                  ),
                  _DetailTile(
                    icon: Icons.pin_drop_rounded,
                    label: isBn ? 'উপজেলা / থানা' : 'Upazila / Area',
                    value: demand.area.getLocalizedName(languageCode),
                  ),
                  // Sub-Area (Union / Ward / Area posted by tenant)
                  if (demand.subArea != null &&
                      (demand.subArea!.name.trim().isNotEmpty || demand.subArea!.bnName.trim().isNotEmpty)) ...[
                    if (isSubAreaUnlocked)
                      _DetailTile(
                        icon: Icons.holiday_village_outlined,
                        label: isBn ? 'সাব-এরিয়া / ইউনিয়ন' : 'Sub-Area / Union',
                        value: demand.subArea!.getLocalizedName(languageCode),
                        isBoldValue: true,
                      )
                    else
                      _buildDemandSubAreaLockedCard(context, user, theme.brightness == Brightness.dark, isBn, policy),
                  ],
                  if (demand.shortAddress.trim().isNotEmpty) ...[
                    if (isSubAreaUnlocked)
                      _DetailTile(
                        icon: Icons.home_outlined,
                        label: l10n.shortAddress,
                        value: demand.shortAddress,
                      )
                    else if (demand.subArea == null ||
                        (demand.subArea!.name.trim().isEmpty && demand.subArea!.bnName.trim().isEmpty))
                      _buildDemandSubAreaLockedCard(context, user, theme.brightness == Brightness.dark, isBn, policy),
                  ],

                  const SizedBox(height: 28),

                  // --- Budget Section ---
                  DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
                  const SizedBox(height: 16),
                  _DetailTile(
                    icon: Icons.payments_outlined,
                    label: l10n.budgetLabel,
                    value: demand.budgetRange != null
                        ? '৳ ${(demand.budgetRange!).toLocalizedDigits(languageCode)}'
                        : '৳ -',
                    valueColor: AppColors.themeColor,
                    isBoldValue: true,
                  ),

                  const SizedBox(height: 28),

                  // --- Required Facilities & Notice Status ---
                  DecoratedSectionHeader(title: l10n.facilitiesLabel),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (demand.tenantType != null)
                        _facilityBadge(
                          icon: Icons.people_outline_rounded,
                          label: demand.tenantType!.getLocalizedLabel(l10n),
                        ),
                      if (demand.attachedBathrooms != null && demand.attachedBathrooms! > 0)
                        _facilityBadge(
                          icon: Icons.bathtub_outlined,
                          label: '${demand.attachedBathrooms!.toLocalizedDigits(languageCode)} ${l10n.attachedBathroom}',
                        ),
                      if (demand.bathrooms != null && demand.bathrooms! > 0)
                        _facilityBadge(
                          icon: Icons.shower_outlined,
                          label: '${demand.bathrooms!.toLocalizedDigits(languageCode)} ${l10n.commonBathroom}',
                        ),
                      if (demand.kitchenCount != null && demand.kitchenCount! > 0)
                        _facilityBadge(
                          icon: Icons.kitchen_outlined,
                          label: '${demand.kitchenCount!.toLocalizedDigits(languageCode)} ${isBn ? 'রান্নাঘর' : 'Kitchen'}',
                        ),
                      if (demand.balconies != null && demand.balconies! > 0)
                        _facilityBadge(
                          icon: Icons.balcony_outlined,
                          label: '${demand.balconies!.toLocalizedDigits(languageCode)} ${l10n.balcony}',
                        ),
                      if (demand.hasLift == true)
                        _facilityBadge(
                          icon: Icons.elevator_outlined,
                          label: l10n.lift,
                        ),
                      if (demand.hasParking == true)
                        _facilityBadge(
                          icon: Icons.local_parking_rounded,
                          label: l10n.parking,
                        ),
                      if (demand.hasGenerator == true)
                        _facilityBadge(
                          icon: Icons.bolt_outlined,
                          label: l10n.generator,
                        ),
                      if (demand.hasWifi == true)
                        _facilityBadge(
                          icon: Icons.wifi_rounded,
                          label: l10n.wifi,
                        ),
                      if (demand.hasCctv == true)
                        _facilityBadge(
                          icon: Icons.videocam_outlined,
                          label: l10n.cctv,
                        ),
                      if (demand.hasSecurityGuard == true)
                        _facilityBadge(
                          icon: Icons.security_rounded,
                          label: l10n.securityGuard,
                        ),
                      if (demand.hasGivenNotice != null)
                        _facilityBadge(
                          icon: Icons.campaign_outlined,
                          label: isBn
                              ? (demand.hasGivenNotice! ? 'বর্তমান বাসায় নোটিশ দেওয়া হয়েছে' : 'নোটিশ দেওয়া হয়নি')
                              : (demand.hasGivenNotice! ? 'Notice Given' : 'Notice Not Given'),
                          color: demand.hasGivenNotice! ? Colors.teal : Colors.blueGrey,
                        ),
                      if (demand.marketDistance != null && demand.marketDistance!.trim().isNotEmpty)
                        _facilityBadge(
                          icon: Icons.directions_walk_rounded,
                          label: demand.marketDistance!,
                        ),
                      if (demand.electricityBillType != null && demand.electricityBillType!.trim().isNotEmpty)
                        _facilityBadge(
                          icon: Icons.electric_bolt_outlined,
                          label: demand.electricityBillType!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // --- Description ---
                  if (demand.detailedDescription.isNotEmpty) ...[
                    DecoratedSectionHeader(title: l10n.descriptionLabel),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        demand.detailedDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // --- Action Buttons ---
                  _buildContactActions(context, l10n, isUnlocked, user, isGuest, isHouseOwner, policy),
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

  Widget _buildUserHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String displayMobile,
    String displayWhatsApp,
    bool isUnlocked,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
            child: Text(
              demand.userName.isNotEmpty ? demand.userName[0].toUpperCase() : 'T',
              style: const TextStyle(
                color: AppColors.themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      demand.userName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        languageCode == 'bn' ? 'ভাড়াটিয়া' : 'Tenant',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildTenantVerificationBadge(
                      demand.tenantVerificationStatus,
                      languageCode,
                      theme.brightness == Brightness.dark,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      displayMobile,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isUnlocked ? (theme.brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700]) : Colors.amber.shade800,
                        fontWeight: isUnlocked ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                    ],
                  ],
                ),
                if (demand.userWhatsApp.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.chat_outlined, size: 14, color: Color(0xFF25D366)),
                      const SizedBox(width: 4),
                      Text(
                        '${languageCode == "bn" ? "হোয়াটসঅ্যাপ" : "WhatsApp"}: $displayWhatsApp',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? const Color(0xFF16A34A) : Colors.amber.shade800,
                          fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  languageCode == 'bn'
                      ? 'পোস্ট করেছেন: ${_formatDate(demand.postDate, languageCode)}'
                      : 'Posted: ${_formatDate(demand.postDate, languageCode)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _facilityBadge({
    required IconData icon,
    required String label,
    Color color = AppColors.themeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActions(
    BuildContext context,
    AppLocalizations l10n,
    bool isUnlocked,
    UserModel? user,
    bool isGuest,
    bool isHouseOwner, [
    FreeTierPolicyModel? policy,
  ]) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (!isUnlocked) {
      if (isGuest) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, SignInScreen.name),
            icon: const Icon(Icons.login_rounded, color: Colors.white),
            label: Text(l10n.loginToUnlockTenantContact, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        );
      }

      final canUnlock = user?.canUnlockContactForPolicy(policy: policy) ?? false;
      if (canUnlock) {
        final isSub = user?.isSubscribed ?? false;
        final count = user?.remainingContactUnlocksForPolicy(policy: policy) ?? 0;
        final countStr = count >= 999999
            ? (languageCode == 'bn' ? 'আনলিমিটেড' : 'Unlimited')
            : count.toString().toLocalizedDigits(languageCode);
        final totalCount = policy?.ownerUnlockNumbers ?? 2;
        final totalStr = totalCount == -1
            ? (languageCode == 'bn' ? 'আনলিমিটেড' : 'Unlimited')
            : totalCount.toString().toLocalizedDigits(languageCode);
        final btnText = isSub
            ? (languageCode == 'bn'
                ? 'প্যাকেজ কোটায় ভাড়াটিয়ার নম্বর আনলক ($countStr বাকি)'
                : 'Unlock Tenant Contact ($countStr Left)')
            : l10n.unlockInfoAndNumberWithQuotaOwner(countStr, totalStr);

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleUnlock(context, user, policy),
            icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
            label: Text(
              btnText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name),
            icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
            label: Text(
              l10n.unlockWithHouseOwnerPackage,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        );
      }
    }

    // Unlocked: Call & WhatsApp buttons
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _launchCaller(demand.userMobile),
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            label: Text(
              l10n.callNow,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              shadowColor: AppColors.themeColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        if (demand.userWhatsApp.isNotEmpty) ...[
          const SizedBox(width: 15),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              onPressed: () => _launchWhatsApp(demand.userWhatsApp),
              icon: const Icon(Icons.chat_outlined, color: Colors.white, size: 26),
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
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

  Widget _buildTenantVerificationBadge(String status, String languageCode, bool isDark) {
    final isBn = languageCode == 'bn';
    final normalized = status.toLowerCase();

    if (normalized == 'verified') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              isBn ? 'ভেরিফাইড' : 'Verified',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    } else if (normalized == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.5) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 12, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              isBn ? 'পেন্ডিং' : 'Pending',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFCBD5E1), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gpp_bad_outlined, size: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              isBn ? 'আনভেরিফাইড' : 'Unverified',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
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

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBoldValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBoldValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.themeColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
