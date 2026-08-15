import 'package:bashabondhu_home_rental_management_system/app/asset_paths.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key,this.width=120, this.height=120});
   final double width;
  final double height;

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

  Future<void> _moveToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        MainNavHolderScreen.name,
        (predicate) => false,
      );
    }
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
              const Spacer(),
              LottieBuilder.asset(
                AssetPaths.splashImage,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.scaleDown,
              ),
              const Spacer(),
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




