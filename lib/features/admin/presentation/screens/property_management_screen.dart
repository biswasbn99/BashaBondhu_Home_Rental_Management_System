import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../home/data/models/property_model.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/services/admin_firestore_service.dart';

class PropertyManagementView extends StatefulWidget {
  const PropertyManagementView({super.key});

  @override
  State<PropertyManagementView> createState() => _PropertyManagementViewState();
}

class _PropertyManagementViewState extends State<PropertyManagementView> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final adminProvider = context.watch<AdminProvider>();
    final isBn = adminProvider.isBangla;

    return StreamBuilder<List<PropertyModel>>(
      stream: _adminService.streamAllProperties(),
      builder: (context, snapshot) {
        final allProperties = snapshot.data ?? [];

        // Apply Search & Filter
        final filteredProperties = allProperties.where((p) {
          final query = _searchQuery.toLowerCase();
          final address = p.shortAddress.toLowerCase();
          final owner = p.ownerEmail.toLowerCase();
          final type = p.houseType.name.toLowerCase();
          final area = p.area.name.toLowerCase();
          final district = p.district.name.toLowerCase();

          final matchesSearch = query.isEmpty ||
              address.contains(query) ||
              owner.contains(query) ||
              type.contains(query) ||
              area.contains(query) ||
              district.contains(query);

          if (!matchesSearch) return false;

          switch (_selectedFilter) {
            case 'Pending':
              return !p.isAvailable;
            case 'Approved':
              return p.isAvailable;
            default:
              return true;
          }
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                isBn ? 'বাসাভাড়া বিজ্ঞাপন ম্যানেজমেন্ট' : 'Property Management',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.themeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isBn
                    ? 'সকল বাসাভাড়া বিজ্ঞাপন অনুমোদন, প্রত্যাখ্যান ও ডিলিট করুন (${filteredProperties.length} টি বিজ্ঞাপন)'
                    : 'Approve, Reject, or Delete House Listings (${filteredProperties.length} listings)',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : const Color(0xFF7A8A88)),
              ),
              const SizedBox(height: 20),

              // Search & Filter Bar with Responsive LayoutBuilder
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2625) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 550) {
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: isBn
                                    ? 'লোকেশন, ইমেইল বা ধরন দিয়ে খুঁজুন...'
                                    : 'Search by Address, Owner Email, Type...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _buildFilterDropdown(isBn, isDark),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: isBn
                                  ? 'লোকেশন, ইমেইল বা ধরন দিয়ে খুঁজুন...'
                                  : 'Search by Address, Owner Email, Type...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: _buildFilterDropdown(isBn, isDark),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Properties DataTable
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2625) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: filteredProperties.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.home_work_outlined, size: 44, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(
                                isBn ? 'কোনো বিজ্ঞাপন পাওয়া যায়নি' : 'No properties found matching query',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          columns: [
                            DataColumn(label: Text(isBn ? 'বাসার তথ্য' : 'Property', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'ধরন' : 'Type', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'ভাড়া' : 'Rent', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'এলাকা / জেলা' : 'Location', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'স্ট্যাটাস' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(isBn ? 'অ্যাকশন' : 'Actions', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredProperties.map((property) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: property.images.isNotEmpty
                                              ? _buildImage(property.images.first, 40, 40)
                                              : Container(color: Colors.grey[300], child: const Icon(Icons.home, size: 18)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              property.shortAddress.isNotEmpty ? property.shortAddress : property.houseType.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                            ),
                                            Text(
                                              property.ownerEmail,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.themeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      property.houseType.name.toUpperCase(),
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                                    ),
                                  ),
                                ),
                                DataCell(Text("${property.amount} ৳", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.themeColor))),
                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 130),
                                    child: Text(
                                      "${property.area.name}, ${property.district.name}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11.5),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (property.isAvailable ? Colors.green : Colors.redAccent).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      property.isAvailable ? (isBn ? 'অনুমোদিত' : 'Approved') : (isBn ? 'পেন্ডিং' : 'Pending'),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: property.isAvailable ? Colors.green : Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18, color: Colors.blueAccent),
                                        tooltip: isBn ? 'ডিটেইলস দেখুন' : 'View Details',
                                        onPressed: () => _showPropertyDetailsModal(context, property, isBn),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Colors.green),
                                        tooltip: isBn ? 'অনুমোদন করুন' : 'Approve',
                                        onPressed: () async {
                                          await _adminService.updatePropertyApproval(property.id, 'approved');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(isBn ? 'বিজ্ঞাপন অনুমোদিত হয়েছে!' : 'Property Approved!'), backgroundColor: Colors.green),
                                            );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.orange),
                                        tooltip: isBn ? 'প্রত্যাখ্যান করুন' : 'Reject',
                                        onPressed: () => _showRejectDialog(context, property.id, isBn),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                        tooltip: isBn ? 'মুছে ফেলুন' : 'Delete Property',
                                        onPressed: () => _showDeleteDialog(context, property.id, isBn),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown(bool isBn, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C1B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          items: [
            DropdownMenuItem(value: 'All', child: Text(isBn ? 'সকল বিজ্ঞাপন (All)' : 'All Listings')),
            DropdownMenuItem(value: 'Approved', child: Text(isBn ? 'অনুমোদিত (Approved)' : 'Approved')),
            DropdownMenuItem(value: 'Pending', child: Text(isBn ? 'পেন্ডিং (Pending)' : 'Pending')),
          ],
          onChanged: (val) => setState(() => _selectedFilter = val!),
        ),
      ),
    );
  }

  void _showPropertyDetailsModal(BuildContext context, PropertyModel property, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        isBn ? 'বাসাভাড়ার বিস্তারিত তথ্য' : 'Property Full Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                if (property.images.isNotEmpty) ...[
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: property.images.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(property.images[idx], 200, 160),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  property.shortAddress.isNotEmpty ? property.shortAddress : property.houseType.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "${property.amount} ৳ / মাস • ${property.month}",
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                ),
                const SizedBox(height: 14),
                _buildInfoRow(isBn ? 'বাড়িওয়ালার ইমেইল' : 'Owner Email', property.ownerEmail),
                _buildInfoRow(isBn ? 'যোগাযোগের নাম' : 'Contact Name', property.contactName),
                _buildInfoRow(isBn ? 'মোবাইল নম্বর' : 'Phone', property.userMobile.isNotEmpty ? property.userMobile : 'N/A'),
                _buildInfoRow(isBn ? 'লোকেশন' : 'Location', "${property.area.name}, ${property.district.name}, ${property.division.name}"),
                _buildInfoRow(isBn ? 'রুম / সিট' : 'Room/Seat', property.roomOrSeat),
                _buildInfoRow(isBn ? 'ফ্লোর' : 'Floor Number', property.floorNumber?.toString() ?? 'N/A'),
                _buildInfoRow(isBn ? 'বাথরুম' : 'Bathrooms', property.commonBathrooms?.toString() ?? 'N/A'),
                _buildInfoRow(isBn ? 'বিদ্যুৎ বিল' : 'Electricity', property.electricityBillType ?? 'N/A'),
                if (property.detailedDescription.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(isBn ? 'বিবরণ:' : 'Description:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(property.detailedDescription, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String propertyId, bool isBn) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'বিজ্ঞাপন প্রত্যাখ্যানের কারণ' : 'Reject Property Listing'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText: isBn ? 'প্রত্যাখ্যানের কারণ লিখুন' : 'Enter rejection reason',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.updatePropertyApproval(propertyId, 'rejected', reason: reasonController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'বিজ্ঞাপনটি প্রত্যাখ্যান করা হয়েছে।' : 'Property rejected.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String propertyId, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'বিজ্ঞাপন মুছে ফেলুন' : 'Delete Property Listing'),
        content: Text(isBn ? 'আপনি কি নিশ্চিত যে এই বিজ্ঞাপনটি স্থায়ীভাবে ডিলিট করতে চান?' : 'Are you sure you want to delete this property?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _adminService.deleteProperty(propertyId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'বিজ্ঞাপন মুছে ফেলা হয়েছে।' : 'Property deleted.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'ডিলিট' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String src, double width, double height) {
    if (src.isEmpty) {
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
    if (src.startsWith('data:image') || src.startsWith('/9j/') || src.startsWith('iVBOR') || src.length > 255) {
      try {
        final base64Str = src.contains(',') ? src.split(',').last : src;
        return Image.memory(base64Decode(base64Str.trim()), width: width, height: height, fit: BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 20);
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(src, width: width, height: height, fit: BoxFit.cover);
    } else {
      try {
        if (!kIsWeb && File(src).existsSync()) {
          return Image.file(File(src), width: width, height: height, fit: BoxFit.cover);
        }
      } catch (_) {}
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
  }
}
