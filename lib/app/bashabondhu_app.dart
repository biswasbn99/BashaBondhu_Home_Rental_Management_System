
import 'package:bashabondhu_home_rental_management_system/app/app_theme.dart';
import 'package:bashabondhu_home_rental_management_system/app/routes.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class BashabondhuApp extends StatelessWidget {
  const BashabondhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title:'Bashabondhu',
      initialRoute: SplashScreen.name,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light
    );
  }
}