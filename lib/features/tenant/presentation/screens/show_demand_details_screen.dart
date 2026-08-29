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
import 'package:bashabondhu_home_rental_management_system/features/subscription/data/providers/subscription_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/subscription/presentation/screens/house_owner_subscription_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';

class ShowDemandDetailsScreen extends StatelessWidget {
  const ShowDemandDetailsScreen({super.key, required this.demand});

  final TenantDemandModel demand;

  static const String name = '/show-demand-details';

  void _handleUnlock(BuildContext context, UserModel? user) {
    if (user == null) {
      Navigator.pushNamed(context, SignInScreen.name);
      return;
    }

    if (user.freeDemandUnlocksRemaining <= 0 && !user.isSubscribed) {
      Navigator.pushNamed(context, HouseOwnerSubscriptionScreen.name);
      return;
    }

    final l10n = context.localizations;
    final languageCode = Localizations.localeOf(context).languageCode;

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
          l10n.unlockDemandDialogContent(user.freeDemandUnlocksRemaining.toLocalizedDigits(languageCode)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isGuest = userProvider.isGuest || user == null;
    final isHouseOwner = user?.isHouseOwner ?? false;

    // Check unlock state: If tenant created it, they can view full info; If house owner, check unlock quota / subscription
    final isOwnerOfDemand = user?.uid == demand.tenantId;
    final isUnlocked = isOwnerOfDemand ||
        PrivacyHelper.isDemandUnlocked(
          demandId: demand.id,
          isGuest: isGuest,
          isSubscribed: user?.isSubscribed ?? false,
          unlockedDemandIds: user?.unlockedDemandIds ?? [],
        );

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

                  const SizedBox(height: 28),

                  // --- Location Section ---
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
                    label: l10n.upazila,
                    value: demand.area.getLocalizedName(languageCode),
                  ),
                  if (demand.shortAddress.isNotEmpty && isUnlocked)
                    _DetailTile(
                      icon: Icons.home_outlined,
                      label: l10n.shortAddress,
                      value: demand.shortAddress,
                    ),

                  const SizedBox(height: 28),

                  // --- Budget Section ---
                  DecoratedSectionHeader(title: l10n.budgetTenantPromptTitle),
                  const SizedBox(height: 16),
                  _DetailTile(
                    icon: Icons.payments_outlined,
                    label: l10n.budgetLabel,
                    value: '৳ ${demand.budgetRange ?? "-"}',
                    valueColor: AppColors.themeColor,
                    isBoldValue: true,
                  ),

                  const SizedBox(height: 28),

                  // --- Required Facilities ---
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
                          label: '${demand.attachedBathrooms} ${l10n.attachedBathroom}',
                        ),
                      if (demand.bathrooms != null && demand.bathrooms! > 0)
                        _facilityBadge(
                          icon: Icons.shower_outlined,
                          label: '${demand.bathrooms} ${l10n.commonBathroom}',
                        ),
                      if (demand.balconies != null && demand.balconies! > 0)
                        _facilityBadge(
                          icon: Icons.balcony_outlined,
                          label: '${demand.balconies} ${l10n.balcony}',
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
                  _buildContactActions(context, l10n, isUnlocked, user, isGuest, isHouseOwner),
                ],
              ),
            ),
          ],
        ),
      ),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        demand.userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "ভাড়াটিয়া",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        color: isUnlocked ? Colors.grey[700] : Colors.amber.shade800,
                        fontWeight: isUnlocked ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_rounded, size: 12, color: Colors.amber),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "পোস্ট করেছেন: ${_formatDate(demand.postDate)}",
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
    bool isHouseOwner,
  ) {
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

      final remaining = user?.freeDemandUnlocksRemaining ?? 0;
      if (remaining > 0) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleUnlock(context, user),
            icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
            label: Text(
              l10n.unlockInfoAndNumberWithQuotaOwner(remaining.toLocalizedDigits(languageCode)),
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

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘন্টা আগে';
    } else {
      return '${diff.inDays} দিন আগে';
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
