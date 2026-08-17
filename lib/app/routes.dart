import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/admin_main_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/data/models/property_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/home/presentation/screens/property_details_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/screens/home_rent_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/data/models/tenant_demand_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/presentation/screens/show_demand_details_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/house_owner/tenant_demand/presentation/screens/tenant_demand_show_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

class AppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Strict Separation: If on Web, only allow Admin routes.
    // If a mobile route is requested on web, redirect to Admin.
    if (kIsWeb && settings.name != AdminMainScreen.name) {
      return MaterialPageRoute(builder: (_) => const AdminMainScreen());
    }

    late Widget widget;

    switch (settings.name) {
      case SplashScreen.name:
        widget = const SplashScreen();
      case SignUpScreen.name:
        widget = const SignUpScreen();
      case SignInScreen.name:
        widget = const SignInScreen();
      case MainNavHolderScreen.name:
        widget = const MainNavHolderScreen();
      case HomeRentPostScreen.name:
        widget = const HomeRentPostScreen();
      case PropertyDetailsScreen.name:
        final property = settings.arguments as PropertyModel;
        widget = PropertyDetailsScreen(property: property);
      case TenantDemandShowScreen.name:
        widget = const TenantDemandShowScreen();
      case ShowDemandDetailsScreen.name:
        final demand = settings.arguments as TenantDemandModel;
        widget = ShowDemandDetailsScreen(demand: demand);
      
      // Admin Route
      case AdminMainScreen.name:
        widget = const AdminMainScreen();

      default:
        widget = const Scaffold(body: Center(child: Text('Page not found')));
    }
    return MaterialPageRoute(builder: (_) => widget);
  }
}
