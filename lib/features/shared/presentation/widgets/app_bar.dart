import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/widgets/app_logo.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/basha_bondhu_title.dart';
import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    this.automaticallyImplyLeading = true,
    this.titleSpacing = 16,
    this.actions,
    this.title,
  });

  final bool automaticallyImplyLeading;
  final double titleSpacing;
  final List<Widget>? actions;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: titleSpacing,
      actions: actions,
      centerTitle: false,
      title: title ?? const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(height: 28, width: 28),
            SizedBox(width: 6),
            BashaBondhuTitle(fontSize: 20),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 0.8,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.25)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: isDark ? 2 : 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
