import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:flutter/material.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text('Welcome back, Admin. Here is what is happening today.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _StatCard(title: 'Total Users', value: '1,250', icon: Icons.people_rounded, color: Colors.blue),
              _StatCard(title: 'Properties', value: '450', icon: Icons.home_rounded, color: AppColors.themeColor),
              _StatCard(title: 'Pending Apps', value: '25', icon: Icons.pending_actions_rounded, color: Colors.orange),
              _StatCard(title: 'Total Reports', value: '12', icon: Icons.report_rounded, color: Colors.red),
            ],
          ),
          
          const SizedBox(height: 40),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSection(theme, 'Recent Property Submissions', [
                  _buildListItem('New Flat in Dhanmondi', '2 hours ago', 'Pending'),
                  _buildListItem('Bachelor Room in Mirpur', '5 hours ago', 'Pending'),
                  _buildListItem('Luxury Villa in Gulshan', 'Yesterday', 'Approved'),
                ]),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildSection(theme, 'Pending Verifications', [
                  _buildListItem('Rahim Uddin', 'Owner', 'Verify'),
                  _buildListItem('Karim Ahmed', 'Tenant', 'Verify'),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListItem(String title, String subtitle, String action) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: TextButton(onPressed: () {}, child: Text(action)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}
