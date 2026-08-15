import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/home_rent_post/presentations/screens/home_rent_post_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
class AppRoutes{
  static Route<dynamic>? onGenerateRoute(RouteSettings settings){
   late Widget widget;

   switch(settings.name){
    case SplashScreen.name:
    widget=SplashScreen();
    case SignUpScreen.name:
    widget=SignUpScreen();
    case SignInScreen.name:
    widget=SignInScreen();
    case MainNavHolderScreen.name:
    widget=MainNavHolderScreen();
    case HomeRentPostScreen.name:
    widget=HomeRentPostScreen();
   }
   return MaterialPageRoute(builder: (_)=>widget);
  }
    
}