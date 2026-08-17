import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/data/models/property_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/presentation/widgets/property_card.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/district_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/division_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/post_icon.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String name = '/home';

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final theme = Theme.of(context);

    // Dummy Data for demonstration
    final List<PropertyModel> properties = [
      PropertyModel(
        id: '13043',
        images: ['https://images.pexels.com/photos/106399/pexels-photo-106399.jpeg'],
        month: 'September',
        houseType: HouseType.flat,
        roomOrSeat: '4 Bed',
        contactName: 'Kabir Khan',
        amount: '45000',
        userMobile: '01700000000',
        userWhatsApp: '01700000000',
        division: DivisionModel(id: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        district: DistrictModel(id: '1', divisionId: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        area: UpazilaModel(id: '1', districtId: '1', name: 'Bashundhara', bnName: 'বসুন্ধরা'),
        shortAddress: 'Block D, Road 5, Bashundhara RA',
        detailedDescription: 'Luxury 4 bedroom flat with modern fittings. Available from next month.',
        commonBathrooms: 2,
        attachedBathrooms: 2,
        hasWifi: true,
        hasLift: true,
        hasParking: true,
        postDate: DateTime.now(),
      ),
      PropertyModel(
        id: '13042',
        images: ['https://images.pexels.com/photos/323780/pexels-photo-323780.jpeg'],
        month: 'October',
        houseType: HouseType.room,
        roomOrSeat: '1 Room',
        contactName: 'Junaid Hossain',
        amount: '12000',
        userMobile: '01800000000',
        userWhatsApp: '01800000000',
        division: DivisionModel(id: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        district: DistrictModel(id: '1', divisionId: '1', name: 'Dhaka', bnName: 'ঢাকা'),
        area: UpazilaModel(id: '2', districtId: '1', name: 'Gulshan', bnName: 'গুলশান'),
        shortAddress: 'Gulshan 1, Near Circle',
        detailedDescription: 'Single room for bachelors. Semi-furnished.',
        kitchenCount: 1,
        hasWifi: true,
        postDate: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: const MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        actions: [
          FreePostButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildBanners(context),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.newest,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: Text(l10n.any, style: const TextStyle(color: AppColors.themeColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...properties.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PropertyCard(property: p),
          )),
        ],
      ),
    );
  }

  Widget _buildBanners(BuildContext context) {
    final l10n = context.localizations;
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _BannerItem(
            color: const Color(0xFFFDEDE3),
            title: l10n.bannerTitle,
            subtitle: l10n.bannerSubtitle,
            icon: Icons.support_agent,
            textColor: Colors.deepOrange,
          ),
          const SizedBox(width: 12),
          _BannerItem(
            color: AppColors.themeColor.withValues(alpha: 0.1),
            title: l10n.postFree,
            subtitle: l10n.postSubtitle,
            icon: Icons.add_home_work_outlined,
            textColor: AppColors.themeColor,
          ),
        ],
      ),
    );
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.textColor,
  });

  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: textColor, size: 30),
        ],
      ),
    );
  }
}
