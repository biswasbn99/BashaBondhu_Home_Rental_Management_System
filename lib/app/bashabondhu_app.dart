
import 'package:bashabondhu_home_rental_management_system/app/app_theme.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/locale_provider.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/theme_provider.dart';
import 'package:bashabondhu_home_rental_management_system/app/routes.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/data/providers/admin_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/screens/admin_main_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/splash_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';


import 'package:bashabondhu_home_rental_management_system/features/house_owner/presentation/providers/my_post_provider.dart';

import 'package:bashabondhu_home_rental_management_system/features/wishlist/data/providers/wishlist_provider.dart';

class BashabondhuApp extends StatefulWidget {
  const BashabondhuApp({super.key});

  @override
  State<BashabondhuApp> createState() => _BashabondhuAppState();
}

class _BashabondhuAppState extends State<BashabondhuApp> {

  final LocaleProvider _localeProvider = LocaleProvider();
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _localeProvider.init();
    _themeProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _localeProvider,),
        ChangeNotifierProvider.value(value: _themeProvider,),
        ChangeNotifierProvider(create: (_) => MainNavHolderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MyPostProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, _, _) {
          return Consumer<LocaleProvider>(
            builder: (context, _, _) {
              return MaterialApp(
            debugShowCheckedModeBanner: false,
            title:'Bashabondhu',
            initialRoute: kIsWeb ? AdminMainScreen.name : SplashScreen.name,
              localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateRoute: AppRoutes.onGenerateRoute,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeProvider.currentThemeMode,
            supportedLocales: _localeProvider.supportedLocales,
            locale: _localeProvider.currentLocale,
        );
          },
        );
      },
    ),
  );
}
}