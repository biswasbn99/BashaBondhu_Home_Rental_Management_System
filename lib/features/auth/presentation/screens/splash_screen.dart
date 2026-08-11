import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/widgets/app_logo.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';
import 'package:flutter/material.dart';


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
    Navigator.pushNamedAndRemoveUntil(context, MainNavHolderScreen.name, (predicate) => false);
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




