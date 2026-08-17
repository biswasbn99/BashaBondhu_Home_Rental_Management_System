import 'package:bashabondhu_home_rental_management_system/features/admin/presentation/widgets/admin_sidebar.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              title: const Text('Admin Panel'),
              elevation: 1,
            )
          : null,
      drawer: !isDesktop ? const Drawer(child: AdminSidebar()) : null,
      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
