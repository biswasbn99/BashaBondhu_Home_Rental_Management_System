import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../shared/presentation/screens/my_profile_screen.dart';

class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    super.key,
    this.user,
    this.onTap,
  });

  final UserModel? user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.localizations;
    final isDark = theme.brightness == Brightness.dark;

    final String name = user != null
        ? user!.fullName.isNotEmpty ? user!.fullName : "${user!.firstName} ${user!.lastName}".trim()
        : l10n.guestUser;
    final String email = user != null ? user!.email : 'guest@bashabondhu.com';
    final String initials = user?.initials ?? 'GU';
    final bool isOwner = user?.userType == 'House Owner';
    final bool isTenant = user?.userType == 'Tenant';

    final int completion = user?.profileCompletionPercentage ?? 0;
    final bool isComplete = user?.isProfileComplete ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ??
            () {
              if (user != null) {
                Navigator.pushNamed(context, MyProfileScreen.name);
              }
            },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.themeColor.withValues(alpha: isDark ? 0.15 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // --- Avatar (Image or Gradient Initials) ---
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (user?.profileImageUrl.isEmpty ?? true)
                      ? LinearGradient(
                          colors: isOwner
                              ? [const Color(0xFF00A896), const Color(0xFF028090)]
                              : isTenant
                                  ? [const Color(0xFF028090), const Color(0xFF00A896)]
                                  : [Colors.grey.shade400, Colors.grey.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (isOwner || isTenant ? AppColors.themeColor : Colors.grey)
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (user?.profileImageUrl.isNotEmpty ?? false)
                      ? _buildProfileImage(user!.profileImageUrl)
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // --- User Details ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role Badge & Completion Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isOwner
                                    ? AppColors.themeColor
                                    : isTenant
                                        ? const Color(0xFF028090)
                                        : Colors.grey)
                                .withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOwner
                                    ? Icons.home_work_rounded
                                    : isTenant
                                        ? Icons.person_rounded
                                        : Icons.explore_outlined,
                                size: 12,
                                color: isOwner
                                    ? AppColors.themeColor
                                    : isTenant
                                        ? const Color(0xFF028090)
                                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user != null ? user!.userType.toUpperCase() : l10n.guestUser.toUpperCase(),
                                style: TextStyle(
                                  color: isOwner
                                      ? AppColors.themeColor
                                      : isTenant
                                          ? const Color(0xFF028090)
                                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isComplete ? Colors.green : Colors.amber.shade800).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isComplete ? '100% ${l10n.complete}' : '$completion% ${l10n.incomplete}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isComplete ? Colors.green : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Name
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Email / Phone
                    Text(
                      user?.mobile.isNotEmpty == true ? user!.mobile : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    if (user != null && user!.city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.themeColor),
                          const SizedBox(width: 2),
                          Text(
                            user!.city,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final Map<String, Uint8List> _base64Cache = {};

  Widget _buildProfileImage(String src) {
    if (src.isEmpty) {
      return const Center(child: Icon(Icons.person, size: 32, color: Colors.white));
    }
    if (src.startsWith('data:image') || src.startsWith('/9j/') || src.startsWith('iVBOR') || src.length > 255) {
      try {
        final Uint8List bytes = _base64Cache.putIfAbsent(src, () {
          final base64Str = src.contains(',') ? src.split(',').last : src;
          return base64Decode(base64Str.trim());
        });
        return Image.memory(
          bytes,
          width: 66,
          height: 66,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 24)),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image_rounded, size: 24));
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: 66,
        height: 66,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 24)),
      );
    } else {
      try {
        if (src.length <= 255 && !kIsWeb && File(src).existsSync()) {
          return Image.file(
            File(src),
            width: 66,
            height: 66,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_rounded, size: 24)),
          );
        }
      } catch (_) {}
      return const Center(child: Icon(Icons.person, size: 32, color: Colors.white));
    }
  }
}
