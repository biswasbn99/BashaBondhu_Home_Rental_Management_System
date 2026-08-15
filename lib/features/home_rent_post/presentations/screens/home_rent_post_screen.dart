import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeRentPostScreen extends StatefulWidget {
  const HomeRentPostScreen({super.key});

  static const String name = '/home-rent-post';

  @override
  State<HomeRentPostScreen> createState() => _HomeRentPostScreenState();
}

class _HomeRentPostScreenState extends State<HomeRentPostScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: true,
        title: Text(
          l10n.postRentalTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Text(
                'Add your rental details here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<MainNavHolderProvider>(
        builder: (context, navProvider, _) {
          return BottomNavigationBar(
            currentIndex: navProvider.selectedIndex,
            onTap: (index) {
              navProvider.changeIndex(index);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            selectedItemColor: AppColors.themeColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
              BottomNavigationBarItem(icon: const Icon(Icons.search), label: l10n.findHome),
              BottomNavigationBarItem(icon: const Icon(Icons.domain_add), label: l10n.demand),
              BottomNavigationBarItem(icon: const Icon(Icons.favorite), label: l10n.wishlist),
              BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.account),
            ],
          );
        },
      ),
    );
  }
}
