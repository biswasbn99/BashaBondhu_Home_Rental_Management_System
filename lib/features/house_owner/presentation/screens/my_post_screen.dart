import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../ai_assistant/presentation/widgets/ai_floating_button.dart';
import '../../../auth/data/providers/user_provider.dart';
import '../../../home/data/models/property_model.dart';
import '../../../home/presentation/screens/property_details_screen.dart';
import '../../../shared/data/models/search_filter_model.dart';
import '../../../shared/data/providers/app_settings_provider.dart';
import '../../../shared/presentation/providers/main_nav_holder_provider.dart';
import '../../../shared/presentation/screens/my_profile_screen.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../../shared/presentation/widgets/app_network_image.dart';
import '../../../shared/presentation/widgets/language_action_button.dart';
import '../providers/my_post_provider.dart';
import 'edit_rent_post_screen.dart';

class MyPostScreen extends StatefulWidget {
  const MyPostScreen({super.key});

  static const String name = '/my-post';

  @override
  State<MyPostScreen> createState() => _MyPostScreenState();
}

class _MyPostScreenState extends State<MyPostScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>().user;
      context.read<MyPostProvider>().initOwner(user?.uid ?? '', ownerEmail: user?.email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final myPostProvider = context.watch<MyPostProvider>();
    final posts = myPostProvider.myPosts;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        title: Text(
          l10n.myPost,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: const [
          LanguageActionButton(),
        ],
      ),
      floatingActionButton: const AIFloatingButton(),
      body: myPostProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.themeColor),
            )
          : posts.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: posts.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _MyPostCard(post: post);
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, dynamic l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.themeColor.withValues(alpha: 0.15)
                    : AppColors.themeColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.real_estate_agent_outlined,
                size: 72,
                color: AppColors.themeColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noPostsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBn
                  ? 'আপনি এখনো কোনো বাসাভাড়ার বিজ্ঞাপন পোস্ট করেননি। নতুন পোস্ট তৈরি করতে নিচের বাটনে ক্লিক করুন।'
                  : "You haven't posted any rental advertisements yet. Tap the button below to create a new post.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_home_work_rounded),
              label: Text(l10n.createPostPrompt),
              onPressed: () {
                // Navigate to Post Screen (Index 1 in House Owner tabs)
                context.read<MainNavHolderProvider>().changeIndex(1);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPostCard extends StatelessWidget {
  const _MyPostCard({required this.post});

  final PropertyModel post;

  void _confirmDelete(BuildContext context) {
    final l10n = context.localizations;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.deletePostConfirmTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(l10n.deletePostConfirmSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<MyPostProvider>().deletePost(post.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.postDeletedSuccess),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
  }

  void _confirmToggleRented(BuildContext context, String languageCode) {
    final isBn = languageCode == 'bn';
    final isCurrentlyRented = post.isRentedOut;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isCurrentlyRented ? Icons.replay_rounded : Icons.do_not_disturb_on_rounded,
              color: isCurrentlyRented ? Colors.green : Colors.deepOrange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isCurrentlyRented
                    ? (isBn ? 'পোস্টটি কি পুনরায় চালু করবেন?' : 'Make Post Available?')
                    : (isBn ? 'বাসাটি কি ভাড়া হয়ে গেছে?' : 'Mark as Rented Out?'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isCurrentlyRented
              ? (isBn
                  ? 'এই পোস্টটি পুনরায় সক্রিয় হবে এবং সকল ভাড়াটিয়া ও গেস্ট ব্যবহারকারীদের হোম স্ক্রিনে প্রদর্শিত হবে।'
                  : 'This property will be marked as available and will be visible again on the Home Screen for all tenants and guests.')
              : (isBn
                  ? 'এই পোস্টটি "ভাড়া হয়ে গেছে" হিসেবে চিহ্নিত হবে এবং সকল ভাড়াটিয়া ও গেস্ট ব্যবহারকারীদের হোম স্ক্রিন থেকে সম্পূর্ণ লুকিয়ে রাখা হবে।'
                  : 'This property will be marked as rented out and completely hidden from the Home Screen for all tenants and guests.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? 'বাতিল' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyRented ? Colors.green : Colors.deepOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<MyPostProvider>().toggleRentedStatus(post);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCurrentlyRented
                          ? (isBn ? 'পোস্টটি সফলভাবে পুনরায় চালু হয়েছে!' : 'Property is now available on Home Screen!')
                          : (isBn ? 'পোস্টটি ভাড়া হয়ে গেছে ও হোম স্ক্রিন থেকে হাইড করা হয়েছে।' : 'Property marked as Rented Out and hidden from Home Screen.'),
                    ),
                    backgroundColor: isCurrentlyRented ? Colors.green : Colors.deepOrange,
                  ),
                );
              }
            },
            child: Text(
              isCurrentlyRented
                  ? (isBn ? 'হ্যাঁ, চালু করুন' : 'Yes, Make Available')
                  : (isBn ? 'হ্যাঁ, ভাড়া হয়েছে' : 'Yes, Rented Out'),
            ),
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
    final isBn = languageCode == 'bn';
    final user = context.watch<UserProvider>().user;
    final appSettings = context.watch<AppSettingsProvider>();

    final bool isGatingActive = appSettings.requireVerifiedOwnerForProperties;
    final bool isUserVerified = (user?.isVerified ?? false) || post.isOwnerVerified;
    final bool isHiddenByGating = isGatingActive && !isUserVerified && post.isApproved && post.isAvailable && !post.isRentedOut;
    final bool isNidPending = (user?.isVerificationPending ?? false) || post.isOwnerPending;

    final locationText = [
      if (post.subArea != null) post.subArea!.getLocalizedName(languageCode),
      post.area.getLocalizedName(languageCode),
      post.district.getLocalizedName(languageCode),
    ].join(', ');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image Banner with Overlay Badges ---
          Stack(
            children: [
              AppImageWidget(
                imageSource: post.images.isNotEmpty ? post.images.first : null,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              // Price Badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    '৳ ${post.amount.toLocalizedDigits(languageCode)} / ${l10n.perMonth}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // House Type & Month Tag
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.houseType.getLocalizedLabel(l10n).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.month.getLocalizedMonth(l10n),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (post.tenantType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.tenantType!.getLocalizedLabel(l10n),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Rented Out / Available Status Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: post.isRentedOut
                        ? Colors.redAccent.withValues(alpha: 0.92)
                        : Colors.green.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        post.isRentedOut ? Icons.do_not_disturb_on_rounded : Icons.check_circle_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.isRentedOut
                            ? (languageCode == 'bn' ? 'ভাড়া হয়ে গেছে' : 'Rented Out')
                            : (languageCode == 'bn' ? 'ভাড়া দেওয়া হবে' : 'Available'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // --- Live Approval Status Banner (Pending Review / Rejected) ---
          if (post.isPendingApproval)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.12),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 16, color: isDark ? Colors.amberAccent : Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCode == 'bn'
                          ? '⏳ পর্যালোচনায় রয়েছে: অ্যাডমিন অনুমোদনের পর পোস্টটি সবার জন্য লাইভ হবে।'
                          : '⏳ Under Review: This listing is awaiting admin approval before going live.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (post.isRejected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_rounded, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageCode == 'bn'
                              ? '❌ বিজ্ঞাপনটি প্রত্যাখ্যান করা হয়েছে'
                              : '❌ Listing has been rejected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.redAccent,
                          ),
                        ),
                        if (post.rejectionReason != null && post.rejectionReason!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${languageCode == "bn" ? "কারণ" : "Reason"}: ${post.rejectionReason}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.red[200] : Colors.red[900],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // --- Verification Gating Alert Banner (Hidden from Tenants & Search) ---
          if (isHiddenByGating)
            _buildGatingHiddenBanner(
              context: context,
              isBn: isBn,
              isDark: isDark,
              isNidPending: isNidPending,
            ),

          // --- Body Info ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title / Room Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        post.roomOrSeat.getLocalizedRoomOrSeat(l10n),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (post.floorNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${l10n.floorLabel}: ${post.floorNumber?.toLocalizedDigits(languageCode)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.themeColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Key Facilities Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (post.attachedBathrooms != null && post.attachedBathrooms! > 0)
                      _buildChip(Icons.bathtub_outlined, '${post.attachedBathrooms!.toLocalizedDigits(languageCode)} ${l10n.attachedBathroom}', theme),
                    if (post.balconies != null && post.balconies! > 0)
                      _buildChip(Icons.balcony_outlined, '${post.balconies!.toLocalizedDigits(languageCode)} ${l10n.balcony}', theme),
                    if (post.hasLift == true)
                      _buildChip(Icons.elevator_outlined, l10n.lift, theme),
                    if (post.hasGenerator == true)
                      _buildChip(Icons.bolt_outlined, l10n.generator, theme),
                    if (post.hasWifi == true)
                      _buildChip(Icons.wifi, l10n.wifi, theme),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // --- 1. RENTED OUT TOGGLE BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: post.isRentedOut
                          ? Colors.green.withValues(alpha: isDark ? 0.18 : 0.08)
                          : Colors.deepOrange.withValues(alpha: isDark ? 0.18 : 0.08),
                      foregroundColor: post.isRentedOut
                          ? (isDark ? Colors.greenAccent : Colors.green[800])
                          : (isDark ? Colors.orangeAccent : Colors.deepOrange),
                      side: BorderSide(
                        color: post.isRentedOut ? Colors.green : Colors.deepOrange,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(
                      post.isRentedOut ? Icons.replay_rounded : Icons.do_not_disturb_on_outlined,
                      size: 18,
                    ),
                    label: Text(
                      post.isRentedOut
                          ? (languageCode == 'bn' ? 'পুনরায় চালু করুন (Show Post)' : 'Mark Available (Show Post)')
                          : (languageCode == 'bn' ? 'ভাড়া হয়ে গেছে (Hide Post)' : 'Mark Rented Out (Hide Post)'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    onPressed: () => _confirmToggleRented(context, languageCode),
                  ),
                ),
                const SizedBox(height: 8),

                // --- 2. Action Buttons: View, Edit, Delete ---
                Row(
                  children: [
                    // View Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 17),
                        label: Text(languageCode == 'bn' ? 'দেখুন' : 'View', style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PropertyDetailsScreen(property: post),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Edit Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.mode_edit_outline_rounded, size: 17),
                        label: Text(languageCode == 'bn' ? 'এডিট' : 'Edit', style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditRentPostScreen(property: post),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Delete Button
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.themeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatingHiddenBanner({
    required BuildContext context,
    required bool isBn,
    required bool isDark,
    required bool isNidPending,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1B0A) : const Color(0xFFFFF7ED),
        border: Border(
          bottom: BorderSide(
            color: Colors.deepOrange.withValues(alpha: isDark ? 0.4 : 0.25),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility_off_rounded,
                  size: 16,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBn ? 'আপনার এই বিজ্ঞাপনটি বর্তমানে লুকানো (হাইড) রয়েছে' : 'Your listing is currently hidden',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isBn
                          ? 'বাড়িওয়ালা প্রোপার্টি ফিল্টারিং চালু রয়েছে: শুধুমাত্র ভেরিফাইড বাড়িওয়ালাদের বিজ্ঞাপন ভাড়াটিয়াদের হোম ও সার্চ স্ক্রিনে দৃশ্যমান হয়। আপনার NID অনুমোদন হওয়ামাত্রই বিজ্ঞাপনটি স্বয়ংক্রিয়ভাবে দৃশ্যমান হবে। অনুগ্রহ করে আপনার প্রোফাইল ভেরিফাই করুন।'
                          : 'House Owner Properties Gating is active: Only verified owners\' rental posts appear on Tenant Home & Search. Automatically visible upon NID approval. Please verify your profile.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isNidPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade700, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 13, color: isDark ? Colors.amberAccent : Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Text(
                        isBn ? 'NID ভেরিফিকেশন পর্যালোচনায় রয়েছে' : 'NID Verification Under Review',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                )
              else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.verified_user_outlined, size: 14),
                  label: Text(
                    isBn ? 'প্রোফাইল ভেরিফাই করুন' : 'Verify Profile',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, MyProfileScreen.name);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}