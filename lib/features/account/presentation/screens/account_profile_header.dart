import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';

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
        ? "${user!.firstName} ${user!.lastName}".trim()
        : l10n.guestUser;
    final String email = user != null ? user!.email : 'guest@bashabondhu.com';
    final String initials = _getInitials();
    final bool isOwner = user?.userType == 'House Owner';
    final bool isTenant = user?.userType == 'Tenant';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _showProfileDialog(context, name, email),
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
              // --- Gradient Avatar ---
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isOwner
                        ? [const Color(0xFF00A896), const Color(0xFF028090)]
                        : isTenant
                            ? [const Color(0xFF028090), const Color(0xFF00A896)]
                            : [Colors.grey.shade400, Colors.grey.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOwner || isTenant ? AppColors.themeColor : Colors.grey)
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
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
              const SizedBox(width: 16),

              // --- User Details ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role Badge
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
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
                            size: 13,
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
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

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

                    // Email or city
                    Text(
                      email,
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

  void _showProfileDialog(BuildContext context, String name, String email) {
    if (user == null) return;
    final l10n = context.localizations;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.themeColor.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: AppColors.themeColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user!.userType,
                            style: const TextStyle(
                              color: AppColors.themeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              _dialogRow(Icons.email_outlined, 'Email', email),
              if (user!.mobile.isNotEmpty)
                _dialogRow(Icons.phone_outlined, l10n.mobile, user!.mobile),
              if (user!.city.isNotEmpty)
                _dialogRow(Icons.location_city_outlined, l10n.city, user!.city),
              _dialogRow(Icons.badge_outlined, l10n.userRole, user!.userType),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ঠিক আছে'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.themeColor),
          const SizedBox(width: 12),
          Text('$title:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13.5, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    if (user == null) return "GU";
    String first = user!.firstName.isNotEmpty ? user!.firstName[0] : "";
    String last = user!.lastName.isNotEmpty ? user!.lastName[0] : "";
    return (first + last).toUpperCase();
  }
}
