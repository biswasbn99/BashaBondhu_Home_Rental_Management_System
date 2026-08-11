import 'package:bashabondhu_home_rental_management_system/features/account/presentation/screens/account_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/find_home/presentation/screens/find_home_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';

import '../providers/main_nav_holder_provider.dart';

class MainNavHolderScreen extends StatefulWidget {
  const MainNavHolderScreen({super.key});

  static const String name = '/main-nav-holder';

  @override
  State<MainNavHolderScreen> createState() => _MainNavHolderScreenState();
}

class _MainNavHolderScreenState extends State<MainNavHolderScreen> {
  final List<Widget> _screens = [
    HomeScreen(),
   FindHomeScreen(),
    HomeScreen(),
    HomeScreen(),
    AccountScreen(email: 'user@example.com'),
  ];

  @override
  Widget build(BuildContext context) {
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
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Find a Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.domain_add),
                label: 'Carts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Wishlist',
              ),
               BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        );
      }
    );
  }
}