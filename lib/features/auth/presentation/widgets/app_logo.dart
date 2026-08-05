
import 'package:bashabondhu_home_rental_management_system/app/asset_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width=120, this.height=120});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AssetPaths.logoSvg,
      width: width,
      height: height,
      fit: BoxFit.scaleDown,
    );
  }
}