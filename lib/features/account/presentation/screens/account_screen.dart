import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bashabondhu_home_rental_management_system/features/account/presentation/widgets/guest_account_view.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/presentation/screens/house_owner_account_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/app_bar.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/post_icon.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/tenant_account_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
    this.email = '',
    this.avatarUrl,
    this.isProfileComplete = false,
  });

  final String email;
  final String? avatarUrl;
  final bool isProfileComplete;

  static const String name = '/account';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final bool isGuest = userProvider.isGuest || user == null;

    return Scaffold(
      appBar: MainAppBar(
        automaticallyImplyLeading: false,
        titleSpacing: isGuest ? 12 : 20,
        actions: isGuest
            ? [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FreePostButton(),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: isGuest
              ? const GuestAccountView()
              : user.isHouseOwner
                  ? HouseOwnerAccountScreen(user: user)
                  : TenantAccountScreen(user: user),
        ),
      ),
    );
  }
}
