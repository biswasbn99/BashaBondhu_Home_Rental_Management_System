import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:flutter/material.dart';

class AppNavLayout extends StatelessWidget {
  const AppNavLayout({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.screens,
    required this.navItems,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<Widget> screens;
  final List<BottomNavigationBarItem> navItems;

  @override
  Widget build(BuildContext context) {
    // Safety check: ensure selectedIndex is within bounds
    final int safeIndex = (selectedIndex >= 0 && selectedIndex < navItems.length) ? selectedIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: onTap,
        selectedItemColor: AppColors.themeColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
