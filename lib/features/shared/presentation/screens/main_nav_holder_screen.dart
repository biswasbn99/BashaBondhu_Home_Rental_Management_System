import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/account/presentation/screens/account_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/demand_home/presentation/screens/demand_home_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/find_home/presentation/screens/find_home_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/presentation/screens/home_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/main_nav_holder_provider.dart';

class MainNavHolderScreen extends StatefulWidget {
  const MainNavHolderScreen({super.key});

  static const String name = '/main-nav-holder';

  @override
  State<MainNavHolderScreen> createState() => _MainNavHolderScreenState();
}

class _MainNavHolderScreenState extends State<MainNavHolderScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const FindHomeScreen(),
    const DemandHomeScreen(),
    const WishlistScreen(),
    const AccountScreen(email: 'user@example.com'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Consumer<MainNavHolderProvider>(
      builder: (context, mainNavHolderProvider, _) {
        return Scaffold(
          body: _screens[mainNavHolderProvider.selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: mainNavHolderProvider.selectedIndex,
            onTap: mainNavHolderProvider.changeIndex,
            selectedItemColor: AppColors.themeColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
              BottomNavigationBarItem(
                icon: const Icon(Icons.search),
                label: l10n.findHome,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.domain_add),
                label: l10n.demand,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.favorite),
                label: l10n.wishlist,
              ),
               BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: l10n.account,
              ),
            ],
          ),
        );
      }
    );
  }
}
