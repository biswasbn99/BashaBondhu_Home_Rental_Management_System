import 'package:bashabondhu_home_rental_management_system/app/asset_paths.dart';
import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/auth/data/providers/user_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/providers/main_nav_holder_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/screens/main_nav_holder_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.width = 120, this.height = 120});
  final double width;
  final double height;

  static const String name = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _moveToNextScreen();
  }

  Future<void> _moveToNextScreen() async {
    final userProvider = context.read<UserProvider>();
    final navProvider = context.read<MainNavHolderProvider>();

    // Synchronize minimum splash display time with local cache & auth resolution
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      userProvider.ensureInitialized(),
    ]);

    if (!mounted) return;

    // Reset navigation tab index safely
    navProvider.resetIndex();

    Navigator.pushNamedAndRemoveUntil(
      context,
      MainNavHolderScreen.name,
      (predicate) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.localizations;
    return Scaffold(
      body: Center(
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
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('${localizations.version} 1.0.0'),
            ],
          ),
        ),
      ),
    );
  }
}
