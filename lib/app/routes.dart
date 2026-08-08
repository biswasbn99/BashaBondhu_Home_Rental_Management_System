import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
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
   }
   return MaterialPageRoute(builder: (_)=>widget);
  }
    
}