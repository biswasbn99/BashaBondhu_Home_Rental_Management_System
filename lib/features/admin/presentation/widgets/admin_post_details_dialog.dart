import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../home/data/models/property_model.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';
import '../../data/services/admin_firestore_service.dart';

class AdminPostDetailsDialog {
  /// Shows the Property Full Details Popup with horizontal multiple images scrolling
  /// (left to right / right to left) and full screen image zoom in/out.
  static void showPropertyDetails(
    BuildContext context,
    PropertyModel property, {
    bool? isBn,
    bool? isDark,
    VoidCallback? onStatusChanged,
  }) {
    final l10n = context.localizations;
    final bn = isBn ?? (l10n.localeName == 'bn');
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final languageCode = bn ? 'bn' : 'en';

    final modalBg = dark ? const Color(0xFF0F201D) : Colors.white;
    final borderColor = dark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final adminService = AdminFirestoreService();

    final status = property.approvalStatus;
    Color statusColor;
    String statusLabel;
    if (status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusLabel = bn ? 'অনুমোদিত' : 'APPROVED';
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusLabel = bn ? 'প্রত্যাখ্যাত' : 'REJECTED';
    } else {
      statusColor = Colors.amber.shade800;
      statusLabel = bn ? 'পেন্ডিং / পর্যালোচনায়' : 'PENDING';
    }

    final rentText = bn
        ? "${property.amount.toString().toLocalizedDigits(languageCode)} ৳ / মাস • ${property.month.getLocalizedMonth(l10n)}"
        : "৳ ${property.amount} / Month • ${property.month.getLocalizedMonth(l10n)}";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: modalBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row (Title & Close Button) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withValues(alpha: dark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.home_work_rounded, color: AppColors.themeColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        bn ? 'বাসাভাড়ার বিস্তারিত তথ্য' : 'Property Full Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: titleColor),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: subtitleColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              Divider(color: borderColor, height: 20),

              // --- Content Body ---
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Multiple Images Row Wise (Left to Right / Right to Left) ---
                      if (property.images.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.photo_library_rounded, size: 15, color: AppColors.themeColor),
                                const SizedBox(width: 6),
                                Text(
                                  bn
                                      ? "ছবিসমূহ (${property.images.length.toString().toLocalizedDigits(languageCode)} টি ছবি)"
                                      : "Property Photos (${property.images.length} images)",
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: titleColor),
                                ),
                              ],
                            ),
                            Text(
                              bn ? '🔍 ট্যাপ করে জুম করুন' : '🔍 Tap image to zoom',
                              style: TextStyle(fontSize: 11, color: subtitleColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 165,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: property.images.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              return InkWell(
                                onTap: () => _showFullScreenImageViewer(
                                  context,
                                  property.images,
                                  idx,
                                  isBn: bn,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: borderColor),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: _buildImage(property.images[idx], 220, 165),
                                      ),
                                    ),
                                    // Image Number Badge
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.image, size: 11, color: Colors.white),
                                            const SizedBox(width: 4),
                                            Text(
                                              bn
                                                  ? "${(idx + 1).toString().toLocalizedDigits(languageCode)}/${property.images.length.toString().toLocalizedDigits(languageCode)}"
                                                  : "${idx + 1}/${property.images.length}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Zoom Icon Hint
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Title & Price
                      Text(
                        property.shortAddress.isNotEmpty
                            ? property.shortAddress
                            : property.houseType.getLocalizedLabel(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rentText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                      ),
                      const SizedBox(height: 14),

                      // Information Rows
                      _buildInfoRow(bn ? 'বাড়িওয়ালার নাম' : 'Contact Name', property.contactName, titleColor, subtitleColor),
                      _buildInfoRow(bn ? 'বাড়িওয়ালার ইমেইল' : 'Owner Email', property.ownerEmail, titleColor, subtitleColor),
                      _buildInfoRow(
                        bn ? 'মোবাইল নম্বর' : 'Phone',
                        property.userMobile.isNotEmpty
                            ? (bn ? property.userMobile.toLocalizedDigits(languageCode) : property.userMobile)
                            : 'N/A',
                        titleColor,
                        subtitleColor,
                      ),
                      if (property.userWhatsApp.isNotEmpty)
                        _buildInfoRow(
                          bn ? 'হোয়াটসঅ্যাপ' : 'WhatsApp',
                          bn ? property.userWhatsApp.toLocalizedDigits(languageCode) : property.userWhatsApp,
                          titleColor,
                          subtitleColor,
                        ),
                      _buildInfoRow(
                        bn ? 'লোকেশন' : 'Location',
                        "${property.area.getLocalizedName(languageCode)}, ${property.district.getLocalizedName(languageCode)}, ${property.division.getLocalizedName(languageCode)}",
                        titleColor,
                        subtitleColor,
                      ),
                      _buildInfoRow(bn ? 'রুম / সিট' : 'Room/Seat', property.roomOrSeat.getLocalizedRoomOrSeat(l10n), titleColor, subtitleColor),
                      _buildInfoRow(
                        bn ? 'ফ্লোর' : 'Floor Number',
                        property.floorNumber != null
                            ? (bn ? property.floorNumber.toString().toLocalizedDigits(languageCode) : property.floorNumber.toString())
                            : 'N/A',
                        titleColor,
                        subtitleColor,
                      ),
                      _buildInfoRow(
                        bn ? 'বাথরুম' : 'Bathrooms',
                        property.commonBathrooms != null
                            ? (bn ? property.commonBathrooms.toString().toLocalizedDigits(languageCode) : property.commonBathrooms.toString())
                            : 'N/A',
                        titleColor,
                        subtitleColor,
                      ),
                      _buildInfoRow(
                        bn ? 'বিদ্যুৎ বিল' : 'Electricity',
                        property.electricityBillType != null
                            ? (bn
                                ? (property.electricityBillType == 'Prepaid'
                                    ? 'প্রিপেইড'
                                    : (property.electricityBillType == 'Postpaid' ? 'পোস্টপেইড' : property.electricityBillType!))
                                : property.electricityBillType!)
                            : 'N/A',
                        titleColor,
                        subtitleColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(bn ? 'অনুমোদন স্ট্যাটাস' : 'Approval Status', style: TextStyle(color: subtitleColor, fontSize: 12.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (property.rejectionReason != null && property.rejectionReason!.isNotEmpty)
                        _buildInfoRow(bn ? 'প্রত্যাখ্যানের কারণ' : 'Rejection Reason', property.rejectionReason!, Colors.redAccent, subtitleColor),
                      if (property.detailedDescription.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(bn ? 'বিবরণ:' : 'Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor)),
                        const SizedBox(height: 4),
                        Text(property.detailedDescription, style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(color: borderColor, height: 20),

              // --- Action Buttons (Approve & Reject) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (property.approvalStatus != 'approved')
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(bn ? 'অনুমোদন করুন' : 'Approve', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await adminService.updatePropertyApproval(property.id, 'approved');
                        onStatusChanged?.call();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(bn ? 'বিজ্ঞাপনটি অনুমোদিত হয়েছে!' : 'Property Approved!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                    ),
                  if (property.approvalStatus != 'approved' && property.approvalStatus != 'rejected')
                    const SizedBox(width: 8),
                  if (property.approvalStatus != 'rejected')
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(bn ? 'প্রত্যাখ্যান করুন' : 'Reject', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRejectModal(context, property.id, isProperty: true, isBn: bn, adminService: adminService, onStatusChanged: onStatusChanged);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the Tenant Demand Full Details Popup.
  static void showDemandDetails(
    BuildContext context,
    TenantDemandModel demand, {
    bool? isBn,
    bool? isDark,
    VoidCallback? onStatusChanged,
  }) {
    final l10n = context.localizations;
    final bn = isBn ?? (l10n.localeName == 'bn');
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final languageCode = bn ? 'bn' : 'en';

    final modalBg = dark ? const Color(0xFF0F201D) : Colors.white;
    final borderColor = dark ? const Color(0xFF22443D) : const Color(0xFFE2E8F0);
    final titleColor = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subtitleColor = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final adminService = AdminFirestoreService();

    final status = demand.approvalStatus;
    Color statusColor;
    String statusLabel;
    if (status == 'approved') {
      statusColor = const Color(0xFF10B981);
      statusLabel = bn ? 'অনুমোদিত' : 'APPROVED';
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusLabel = bn ? 'প্রত্যাখ্যাত' : 'REJECTED';
    } else {
      statusColor = Colors.amber.shade800;
      statusLabel = bn ? 'পেন্ডিং / পর্যালোচনায়' : 'PENDING';
    }

    final budgetText = demand.budgetRange != null
        ? (bn ? "বাজেট: ${demand.budgetRange!.toLocalizedDigits(languageCode)} ৳" : "Budget: ৳ ${demand.budgetRange}")
        : (bn ? "বাজেট: নির্ধারিত নেই" : "Budget: Not specified");

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: modalBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row (Title & Close Button) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: dark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        bn ? 'ভাড়াটিয়া চাহিদার বিস্তারিত' : 'Demand Full Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: titleColor),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: subtitleColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              Divider(color: borderColor, height: 20),

              // --- Content Body ---
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subheading
                      Text(
                        '${demand.houseType.getLocalizedLabel(l10n)} - ${demand.month.getLocalizedMonth(l10n)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budgetText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.themeColor),
                      ),
                      const SizedBox(height: 14),

                      // Information Rows
                      _buildInfoRow(bn ? 'ভাড়াটিয়ার নাম' : 'Tenant Name', demand.userName.isNotEmpty ? demand.userName : 'N/A', titleColor, subtitleColor),
                      _buildInfoRow(bn ? 'ভাড়াটিয়ার ইমেইল' : 'Tenant Email', demand.tenantEmail, titleColor, subtitleColor),
                      _buildInfoRow(
                        bn ? 'মোবাইল নম্বর' : 'Phone',
                        demand.userMobile.isNotEmpty
                            ? (bn ? demand.userMobile.toLocalizedDigits(languageCode) : demand.userMobile)
                            : 'N/A',
                        titleColor,
                        subtitleColor,
                      ),
                      if (demand.userWhatsApp.isNotEmpty)
                        _buildInfoRow(
                          bn ? 'হোয়াটসঅ্যাপ' : 'WhatsApp',
                          bn ? demand.userWhatsApp.toLocalizedDigits(languageCode) : demand.userWhatsApp,
                          titleColor,
                          subtitleColor,
                        ),
                      _buildInfoRow(
                        bn ? 'লোকেশন' : 'Location',
                        "${demand.area.getLocalizedName(languageCode)}, ${demand.district.getLocalizedName(languageCode)}, ${demand.division.getLocalizedName(languageCode)}",
                        titleColor,
                        subtitleColor,
                      ),
                      _buildInfoRow(bn ? 'ভাড়াটিয়ার ধরন' : 'Tenant Type', demand.tenantType?.getLocalizedLabel(l10n) ?? 'N/A', titleColor, subtitleColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(bn ? 'অনুমোদন স্ট্যাটাস' : 'Approval Status', style: TextStyle(color: subtitleColor, fontSize: 12.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (demand.rejectionReason != null && demand.rejectionReason!.isNotEmpty)
                        _buildInfoRow(bn ? 'প্রত্যাখ্যানের কারণ' : 'Rejection Reason', demand.rejectionReason!, Colors.redAccent, subtitleColor),
                      if (demand.detailedDescription.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(bn ? 'বিবরণ:' : 'Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor)),
                        const SizedBox(height: 4),
                        Text(demand.detailedDescription, style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.4)),
                      ],
                    ],
                  ),
                ),
              ),

              Divider(color: borderColor, height: 20),

              // --- Action Buttons (Approve & Reject) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (demand.approvalStatus != 'approved')
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(bn ? 'অনুমোদন করুন' : 'Approve', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await adminService.updateDemandApproval(demand.id, 'approved');
                        onStatusChanged?.call();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(bn ? 'চাহিদা পোস্টটি অনুমোদিত হয়েছে!' : 'Demand Post Approved!'), backgroundColor: Colors.green),
                          );
                        }
                      },
                    ),
                  if (demand.approvalStatus != 'approved' && demand.approvalStatus != 'rejected')
                    const SizedBox(width: 8),
                  if (demand.approvalStatus != 'rejected')
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(bn ? 'প্রত্যাখ্যান করুন' : 'Reject', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRejectModal(context, demand.id, isProperty: false, isBn: bn, adminService: adminService, onStatusChanged: onStatusChanged);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full screen zoomable image viewer where ONLY the image zooms in/out with pinch-to-zoom,
  /// pan, zoom in/out buttons, image switcher (prev/next), and thumbnail strip.
  static void _showFullScreenImageViewer(
    BuildContext context,
    List<String> images,
    int initialIndex, {
    required bool isBn,
  }) {
    int currentIndex = initialIndex;
    final transformationController = TransformationController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (viewerCtx) => StatefulBuilder(
        builder: (context, setViewerState) {
          final languageCode = isBn ? 'bn' : 'en';

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                // Zoomable Image Area (Only image zooms)
                Center(
                  child: InteractiveViewer(
                    transformationController: transformationController,
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: _buildImage(
                      images[currentIndex],
                      MediaQuery.of(context).size.width * 0.9,
                      MediaQuery.of(context).size.height * 0.75,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Top Toolbar (Counter, Zoom In/Out, Reset, Close)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Counter Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isBn
                                ? "ছবি ${(currentIndex + 1).toString().toLocalizedDigits(languageCode)} / ${images.length.toString().toLocalizedDigits(languageCode)}"
                                : "Photo ${currentIndex + 1} / ${images.length}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),

                        // Image Zoom Controls & Close
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 22),
                              tooltip: isBn ? 'জুম আউট' : 'Zoom Out',
                              onPressed: () {
                                transformationController.value = Matrix4.copy(transformationController.value)..scaleByDouble(0.8, 0.8, 1.0, 1.0);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.restart_alt_rounded, color: Colors.white, size: 22),
                              tooltip: isBn ? 'রিসেট জুম' : 'Reset Zoom',
                              onPressed: () {
                                transformationController.value = Matrix4.identity();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 22),
                              tooltip: isBn ? 'জুম ইন' : 'Zoom In',
                              onPressed: () {
                                transformationController.value = Matrix4.copy(transformationController.value)..scaleByDouble(1.25, 1.25, 1.0, 1.0);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                              tooltip: isBn ? 'বন্ধ করুন' : 'Close',
                              onPressed: () => Navigator.pop(viewerCtx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Previous Image Arrow Button
                if (currentIndex > 0)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                          onPressed: () {
                            setViewerState(() {
                              currentIndex--;
                              transformationController.value = Matrix4.identity();
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                // Next Image Arrow Button
                if (currentIndex < images.length - 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 22),
                          onPressed: () {
                            setViewerState(() {
                              currentIndex++;
                              transformationController.value = Matrix4.identity();
                            });
                          },
                        ),
                      ),
                    ),
                  ),

                // Bottom Thumbnail Strip (if multiple images)
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(images.length, (idx) {
                              final isSelected = idx == currentIndex;
                              return GestureDetector(
                                onTap: () {
                                  setViewerState(() {
                                    currentIndex = idx;
                                    transformationController.value = Matrix4.identity();
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: _buildImage(images[idx], 44, 44),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value, Color valueColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 12.5)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  static void _showRejectModal(
    BuildContext context,
    String id, {
    required bool isProperty,
    required bool isBn,
    required AdminFirestoreService adminService,
    VoidCallback? onStatusChanged,
  }) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isBn ? 'পোস্ট প্রত্যাখ্যানের কারণ' : 'Reject Post'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: isBn ? 'সুনির্দিষ্ট কারণ লিখুন...' : 'Enter rejection reason...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(isBn ? 'বাতিল' : 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(c);
              if (isProperty) {
                await adminService.updatePropertyApproval(id, 'rejected', reason: reasonController.text.trim());
              } else {
                await adminService.updateDemandApproval(id, 'rejected', reason: reasonController.text.trim());
              }
              onStatusChanged?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isBn ? 'পোস্টটি প্রত্যাখ্যান করা হয়েছে।' : 'Post rejected.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: Text(isBn ? 'প্রত্যাখ্যান' : 'Reject'),
          ),
        ],
      ),
    );
  }

  static Widget _buildImage(String src, double width, double height, {BoxFit fit = BoxFit.cover}) {
    if (src.isEmpty) {
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
    if (src.startsWith('data:image') || src.startsWith('/9j/') || src.startsWith('iVBOR') || src.length > 255) {
      try {
        final base64Str = src.contains(',') ? src.split(',').last : src;
        return Image.memory(base64Decode(base64Str.trim()), width: width, height: height, fit: fit);
      } catch (_) {
        return const Icon(Icons.broken_image, size: 20);
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(src, width: width, height: height, fit: fit);
    } else {
      try {
        if (!kIsWeb && File(src).existsSync()) {
          return Image.file(File(src), width: width, height: height, fit: fit);
        }
      } catch (_) {}
      return Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 20));
    }
  }
}
