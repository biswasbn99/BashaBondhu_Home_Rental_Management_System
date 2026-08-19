import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/screens/account_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/demand_home/presentation/screens/demand_home_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/find_home/presentation/screens/find_home_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/presentation/screens/home_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/screens/home_rent_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/presentation/screens/tenant_demand_show_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_nav_layout.dart';
import 'package:bashabondhu_home_rental_management_system/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainNavHolderScreen extends StatelessWidget {
  const MainNavHolderScreen({super.key});

  static const String name = '/main-nav-holder';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final userProvider = context.watch<UserProvider>();
    final navProvider = context.watch<MainNavHolderProvider>();

    final bool isOwner = userProvider.user?.userType == 'House Owner';

    // Role-based Screens
    final List<Widget> screens = isOwner
        ? [
            const TenantDemandShowScreen(),
            const HomeRentPostScreen(),
            AccountScreen(email: userProvider.user?.email ?? ''),
          ]
        : [
            const HomeScreen(),
            const FindHomeScreen(),
            const DemandHomeScreen(),
            const WishlistScreen(),
            AccountScreen(email: userProvider.user?.email ?? 'guest@example.com'),
          ];

    // Role-based Navigation Items
    final List<BottomNavigationBarItem> navItems = isOwner
        ? [
            BottomNavigationBarItem(icon: const Icon(Icons.domain_add), label: l10n.demand),
            BottomNavigationBarItem(icon: const Icon(Icons.add_home_work), label: l10n.postFree),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.account),
          ]
        : [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
            BottomNavigationBarItem(icon: const Icon(Icons.search), label: l10n.findHome),
            BottomNavigationBarItem(icon: const Icon(Icons.domain_add), label: l10n.demand),
            BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: l10n.wishlist),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.account),
          ];

    // --- Index Safety Logic ---
    // If the index is out of bounds for the current role (e.g. was 4, now is 3 items), reset to 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navProvider.selectedIndex >= navItems.length) {
        navProvider.resetIndex();
      }
    });

    return AppNavLayout(
      selectedIndex: navProvider.selectedIndex,
      onTap: navProvider.changeIndex,
      screens: screens,
      navItems: navItems,
    );
  }
}
