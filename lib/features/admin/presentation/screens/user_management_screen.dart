import 'package:flutter/material.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text('Manage Owners, Tenants, and Verifications', style: TextStyle(color: Colors.grey)),
                ],
              ),
              _buildFilterDropdown(),
            ],
          ),
          const SizedBox(height: 32),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Theme(
              data: theme.copyWith(cardColor: theme.colorScheme.surface, dividerColor: Colors.transparent),
              child: PaginatedDataTable(
                header: const Text('All Registered Users', style: TextStyle(fontWeight: FontWeight.bold)),
                columns: const [
                  DataColumn(label: Text('User ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Verification')),
                  DataColumn(label: Text('Actions')),
                ],
                source: _UserDataSource(context),
                rowsPerPage: 10,
                showFirstLastButtons: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          items: ['All', 'Owners', 'Tenants', 'Verified', 'Pending']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (val) => setState(() => _selectedFilter = val!),
        ),
      ),
    );
  }
}

class _UserDataSource extends DataTableSource {
  _UserDataSource(this.context);
  final BuildContext context;

  final List<Map<String, String>> _users = List.generate(25, (index) => {
    'id': 'USR-100${index + 1}',
    'name': index % 2 == 0 ? 'Rahim Uddin' : 'Sabbir Ahmed',
    'role': index % 3 == 0 ? 'Owner' : 'Tenant',
    'status': index % 5 == 0 ? 'Blocked' : 'Active',
    'verification': index % 4 == 0 ? 'Verified' : 'Pending',
  });

  @override
  DataRow? getRow(int index) {
    if (index >= _users.length) return null;
    final user = _users[index];
    final isBlocked = user['status'] == 'Blocked';
    final isVerified = user['verification'] == 'Verified';

    return DataRow(cells: [
      DataCell(Text(user['id']!)),
      DataCell(Text(user['name']!)),
      DataCell(Text(user['role']!)),
      DataCell(
        Chip(
          label: Text(user['status']!, style: TextStyle(color: isBlocked ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: (isBlocked ? Colors.red : Colors.green).withValues(alpha: 0.1),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
        ),
      ),
      DataCell(
        Icon(
          isVerified ? Icons.verified_user_rounded : Icons.pending_rounded,
          color: isVerified ? Colors.blue : Colors.orange,
          size: 20,
        ),
      ),
      DataCell(
        Row(
          children: [
            IconButton(icon: const Icon(Icons.visibility_outlined, size: 20), onPressed: () {}),
            IconButton(
              icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 20, color: isBlocked ? Colors.green : Colors.red),
              onPressed: () {},
            ),
          ],
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _users.length;
  @override
  int get selectedRowCount => 0;
}
