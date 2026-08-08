import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/locale_provider.dart';
import 'package:bashabondhu_home_rental_management_system/app/providers/theme_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String name='/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _moveToNextScreen();
  }

  Future<void> _moveToNextScreen() async{
    await Future.delayed(Duration(seconds: 2));
    Navigator.pushNamedAndRemoveUntil(context, SignUpScreen.name, (predicate)=>false);
  }
  @override
  Widget build(BuildContext context) {

     final localizations = context.localizations;
    return Scaffold(
      body:Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Spacer(),
              AppLogo(),
              LocaleChangerDropdown(),
               ThemeChangerDropdown(),
              Spacer(),
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${localizations.version} 1.0.0'),
            ]
          ),
        ),
      )
    );
  }
}

class LocaleChangerDropdown extends StatelessWidget {
  const LocaleChangerDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return DropdownButton<Locale>(
          value: localeProvider.currentLocale,
          items: localeProvider.supportedLocales.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e.languageCode.toUpperCase()),
            );
          }).toList(),
          onChanged: (Locale? newLocale) {
            if (newLocale != null) {
              localeProvider.changeLocale(newLocale);
            }
          },
        );
      },
    );
  }
}



class ThemeChangerDropdown extends StatelessWidget {
  const ThemeChangerDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return DropdownButton<ThemeMode>(
          value: themeProvider.currentThemeMode,
          items: themeProvider.themeModes.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e.toString().split('.').last.toUpperCase()),
            );
          }).toList(),
          onChanged: (ThemeMode? newThemeMode) {
            if (newThemeMode != null) {
              themeProvider.changeThemeMode(newThemeMode);
         }
          },
        );
      },
    );
  }
}