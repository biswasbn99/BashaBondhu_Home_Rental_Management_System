import 'package:flutter/material.dart';

class PropertyManagementView extends StatefulWidget {
  const PropertyManagementView({super.key});

  @override
  State<PropertyManagementView> createState() => _PropertyManagementViewState();
}

class _PropertyManagementViewState extends State<PropertyManagementView> {
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
                    'Property Management',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text('Approve, Reject, or Delete House Listings', style: TextStyle(color: Colors.grey)),
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
                header: const Text('All Property Listings', style: TextStyle(fontWeight: FontWeight.bold)),
                columns: const [
                  DataColumn(label: Text('Property ID')),
                  DataColumn(label: Text('Owner')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                source: _PropertyDataSource(context),
                rowsPerPage: 10,
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
          items: ['All', 'Pending', 'Approved', 'Rejected']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (val) => setState(() => _selectedFilter = val!),
        ),
      ),
    );
  }
}

class _PropertyDataSource extends DataTableSource {
  _PropertyDataSource(this.context);
  final BuildContext context;

  final List<Map<String, String>> _properties = List.generate(20, (index) => {
    'id': 'PROP-500${index + 1}',
    'owner': 'Kabir Khan',
    'type': index % 2 == 0 ? 'Flat' : 'Room',
    'location': 'Dhanmondi, Dhaka',
    'status': index % 3 == 0 ? 'Pending' : (index % 4 == 0 ? 'Rejected' : 'Approved'),
  });

  @override
  DataRow? getRow(int index) {
    if (index >= _properties.length) return null;
    final property = _properties[index];
    final status = property['status']!;
    
    Color statusColor = Colors.grey;
    if (status == 'Approved') statusColor = Colors.green;
    if (status == 'Pending') statusColor = Colors.orange;
    if (status == 'Rejected') statusColor = Colors.red;

    return DataRow(cells: [
      DataCell(Text(property['id']!)),
      DataCell(Text(property['owner']!)),
      DataCell(Text(property['type']!)),
      DataCell(Text(property['location']!)),
      DataCell(
        Chip(
          label: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          backgroundColor: statusColor.withValues(alpha: 0.1),
          side: BorderSide.none,
        ),
      ),
      DataCell(
        Row(
          children: [
            IconButton(icon: const Icon(Icons.visibility_outlined, size: 20), onPressed: () {}),
            if (status == 'Pending') ...[
              IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20), onPressed: () {}),
              IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20), onPressed: () {}),
            ],
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20), onPressed: () {}),
          ],
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _properties.length;
  @override
  int get selectedRowCount => 0;
}
