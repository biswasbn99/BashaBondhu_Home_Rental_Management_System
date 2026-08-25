import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/admin_main_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/data/models/property_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/presentation/screens/property_details_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/screens/home_rent_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/presentation/screens/edit_rent_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/presentation/screens/house_owner_dashboard_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/presentation/screens/my_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/my_profile_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/edit_demand_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/my_demand_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/show_demand_details_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/tenant_dashboard_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/tenant/presentation/screens/tenant_demand_show_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

class AppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Strict Separation: If on Web, only allow Admin routes.
    if (kIsWeb && settings.name != AdminMainScreen.name) {
      return MaterialPageRoute(builder: (_) => const AdminMainScreen());
    }

    final Map<String, dynamic>? args = settings.arguments is Map<String, dynamic>
        ? settings.arguments as Map<String, dynamic>
        : null;

    final Widget widget = switch (settings.name) {
      SplashScreen.name => const SplashScreen(),
      SignUpScreen.name => SignUpScreen(
          preSelectedUserType: args?['preSelectedUserType'] as String?,
          lockUserType: args?['lockUserType'] as bool? ?? false,
        ),
      SignInScreen.name => SignInScreen(
          preSelectedUserType: args?['preSelectedUserType'] as String?,
          lockUserType: args?['lockUserType'] as bool? ?? false,
        ),
      MainNavHolderScreen.name => const MainNavHolderScreen(),
      HomeRentPostScreen.name => const HomeRentPostScreen(),
      PropertyDetailsScreen.name => PropertyDetailsScreen(property: settings.arguments as PropertyModel),
      TenantDemandShowScreen.name => const TenantDemandShowScreen(),
      ShowDemandDetailsScreen.name => ShowDemandDetailsScreen(demand: settings.arguments as TenantDemandModel),
      MyPostScreen.name => const MyPostScreen(),
      EditRentPostScreen.name => EditRentPostScreen(property: settings.arguments as PropertyModel),
      MyDemandScreen.name => const MyDemandScreen(),
      EditDemandScreen.name => EditDemandScreen(demand: settings.arguments as TenantDemandModel),
      MyProfileScreen.name => const MyProfileScreen(),
      HouseOwnerDashboardScreen.name => const HouseOwnerDashboardScreen(),
      TenantDashboardScreen.name => const TenantDashboardScreen(),
      AdminMainScreen.name => const AdminMainScreen(),
      _ => const Scaffold(body: Center(child: Text('Page not found'))),
    };

    return MaterialPageRoute(builder: (_) => widget);
  }
}
