
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/post_icon.dart';
import 'package:flutter/material.dart';

import '../widgets/home_app_bar.dart';
import '../widgets/home_section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
     appBar: const MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        actions: [
          FreePostButton(),
        ],
      ),
      body: Padding(
        padding: .symmetric(horizontal: 16),
        child: Column(
          children: [
          const SizedBox(height: 12),
            HomeSectionHeader(
              title: 'Category',
              onTapSeeAll: () {},
            )
          ],
        ),
      ),
    );
  }
}