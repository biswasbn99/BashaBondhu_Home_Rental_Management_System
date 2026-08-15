import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class DemandHomeScreen extends StatefulWidget {
  const DemandHomeScreen({super.key});

  @override
  State<DemandHomeScreen> createState() => _DemandHomeScreenState();
}

class _DemandHomeScreenState extends State<DemandHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
      ),
    );
  }
}