import 'package:bashabondhu_home_rental_management_system/features/auth/presentation/widgets/app_logo.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const AppLogo(height: 40, width: 40),
      actions: [
        _buildIconButton(icon: Icons.person, onTap: () {}),
        SizedBox(width: 8),
        _buildIconButton(icon: Icons.call, onTap: () {}),
        SizedBox(width: 8),
        _buildIconButton(icon: Icons.notifications, onTap: () {}),
      ],
         bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFECECEC)),
        ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.withAlpha(40),
        child: Icon(icon, color: Colors.grey, size: 20),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}