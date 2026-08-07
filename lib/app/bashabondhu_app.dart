
import 'package:bashabondhu_home_rental_management_system/app/app_theme.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/locale_provider.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/theme_provider.dart';
import 'package:bashabondhu_home_rental_management_system/app/routes.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/splash_screen.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';


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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, _, _) {
          return Consumer<LocaleProvider>(
            builder: (context, _, _) {
              return MaterialApp(
            debugShowCheckedModeBanner: false,
            title:'Bashabondhu',
            initialRoute: SplashScreen.name,
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