import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../home/data/models/property_model.dart';
import '../../../subscription/data/models/subscription_model.dart';
import '../../../tenant/data/models/tenant_demand_model.dart';

/// Unicode shaping engine for Bengali Indic script rendering in PDF
class BengaliPdfShaper {
  static bool _isBengaliConsonant(int code) {
    return (code >= 0x0995 && code <= 0x09B9) ||
        code == 0x09CE ||
        code == 0x09DC ||
        code == 0x09DD ||
        code == 0x09DF;
  }

  static bool _isVirama(int code) => code == 0x09CD;
  static bool _isNukta(int code) => code == 0x09BC;

  /// Reorders pre-base vowel signs (ি, ে, ৈ, ো, ৌ) before consonants for proper visual display in PDF
  static String shape(String text) {
    if (text.isEmpty) return text;

    final runes = text.runes.toList();
    final result = <int>[];
    int i = 0;

    while (i < runes.length) {
      final code = runes[i];

      if (_isBengaliConsonant(code)) {
        final cluster = <int>[code];
        i++;

        // Check for nukta (়)
        if (i < runes.length && _isNukta(runes[i])) {
          cluster.add(runes[i]);
          i++;
        }

        // Check for conjuncts (Consonant + Virama + Consonant)
        while (i + 1 < runes.length && _isVirama(runes[i]) && _isBengaliConsonant(runes[i + 1])) {
          cluster.add(runes[i]);
          cluster.add(runes[i + 1]);
          i += 2;
          if (i < runes.length && _isNukta(runes[i])) {
            cluster.add(runes[i]);
            i++;
          }
        }

        // Check for following vowel signs
        if (i < runes.length) {
          final nextCode = runes[i];

          // ি (Rossho I-kar - 0x09BF) -> Pre-base
          if (nextCode == 0x09BF) {
            result.add(0x09BF);
            result.addAll(cluster);
            i++;
            continue;
          }
          // ে (E-kar - 0x09C7) -> Pre-base
          else if (nextCode == 0x09C7) {
            result.add(0x09C7);
            result.addAll(cluster);
            i++;
            continue;
          }
          // ৈ (OI-kar - 0x09C8) -> Pre-base
          else if (nextCode == 0x09C8) {
            result.add(0x09C8);
            result.addAll(cluster);
            i++;
            continue;
          }
          // ো (O-kar - 0x09CB) -> Split into ে (before) + া (after)
          else if (nextCode == 0x09CB) {
            result.add(0x09C7);
            result.addAll(cluster);
            result.add(0x09BE);
            i++;
            continue;
          }
          // ৌ (OU-kar - 0x09CC) -> Split into ে (before) + ৗ (after)
          else if (nextCode == 0x09CC) {
            result.add(0x09C7);
            result.addAll(cluster);
            result.add(0x09D7);
            i++;
            continue;
          }
        }

        result.addAll(cluster);
      } else {
        result.add(code);
        i++;
      }
    }

    return String.fromCharCodes(result);
  }
}

class AdminReportPdfService {
  static final AdminReportPdfService _instance = AdminReportPdfService._internal();
  factory AdminReportPdfService() => _instance;
  AdminReportPdfService._internal();

  // Robust font loader that supports both Bengali (বাংলা) and English (Latin) flawlessly
  Future<pw.ThemeData> _buildPdfTheme() async {
    try {
      final baseFont = await PdfGoogleFonts.notoSansBengaliRegular();
      final boldFont = await PdfGoogleFonts.notoSansBengaliBold();
      return pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
        fontFallback: [baseFont, boldFont],
      );
    } catch (_) {
      try {
        final roboto = await PdfGoogleFonts.robotoRegular();
        final robotoBold = await PdfGoogleFonts.robotoBold();
        return pw.ThemeData.withFont(
          base: roboto,
          bold: robotoBold,
          fontFallback: [roboto, robotoBold],
        );
      } catch (_) {
        return pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
          boldItalic: pw.Font.helveticaBoldOblique(),
        );
      }
    }
  }

  /// Formats any package plan title into clean, professional English for all reports & receipts
  String formatPlanTitle(String rawTitle, String planId, [bool isBn = false]) {
    final cleanTitle = rawTitle.trim();
    final cleanId = planId.trim();
    final lowerId = cleanId.toLowerCase();
    final lowerTitle = cleanTitle.toLowerCase();

    // 1. Duration Checks
    final bool has15 = lowerId.contains('15') || lowerTitle.contains('15') || cleanTitle.contains('১৫');
    final bool has30 = lowerId.contains('30') || lowerTitle.contains('30') || cleanTitle.contains('৩০');
    final bool has7 = lowerId.contains('7') || lowerTitle.contains('7') || cleanTitle.contains('৭');
    final bool has60 = lowerId.contains('60') || lowerTitle.contains('60') || cleanTitle.contains('৬০');
    final bool has90 = lowerId.contains('90') || lowerTitle.contains('90') || cleanTitle.contains('৯০');

    // 2. Role & Tier Checks
    final bool isStarter = lowerId.contains('starter') || lowerTitle.contains('starter') || cleanTitle.contains('স্টার্টার') || cleanTitle.contains('স্টার্টিং');
    final bool isStandard = lowerId.contains('standard') || lowerTitle.contains('standard') || cleanTitle.contains('স্ট্যান্ডার্ড');
    final bool isPremium = lowerId.contains('premium') || lowerTitle.contains('premium') || cleanTitle.contains('প্রিমিয়াম') || cleanTitle.contains('প্রিমিয়াম');
    final bool isPro = lowerId.contains('pro') || lowerTitle.contains('pro') || cleanTitle.contains('প্রো');
    final bool isBasic = lowerId.contains('basic') || lowerTitle.contains('basic') || cleanTitle.contains('বেসিক');
    final bool isHouseOwner = lowerId.contains('owner') || lowerId.contains('house_owner') || cleanTitle.contains('বাড়িওয়ালা') || cleanTitle.contains('মালিক');

    if (isStarter) {
      if (has15) return isHouseOwner ? '15 Days House Owner Starter Package' : '15 Days Starter Package';
      if (has30) return isHouseOwner ? '30 Days House Owner Starter Package' : '30 Days Starter Package';
      return isHouseOwner ? '7 Days House Owner Starter Package' : '7 Days Starter Package';
    }

    if (isStandard) {
      if (has30) return isHouseOwner ? '30 Days House Owner Standard Package' : '30 Days Standard Package';
      if (has7) return isHouseOwner ? '7 Days House Owner Standard Package' : '7 Days Standard Package';
      return isHouseOwner ? '15 Days House Owner Standard Package' : '15 Days Standard Package';
    }

    if (isPremium) {
      if (isPro) return has15 ? '15 Days Premium Pro Package' : '30 Days Premium Pro Package';
      if (has15) return isHouseOwner ? '15 Days House Owner Premium Package' : '15 Days Premium Package';
      if (has60) return isHouseOwner ? '60 Days House Owner Premium Package' : '60 Days Premium Package';
      if (has90) return isHouseOwner ? '90 Days House Owner Premium Package' : '90 Days Premium Package';
      return isHouseOwner ? '30 Days House Owner Premium Package' : '30 Days Premium Package';
    }

    if (isBasic) {
      return isHouseOwner ? 'House Owner Basic Plan' : 'Basic Plan';
    }

    // 3. Dynamic Parser & Translator for Custom Admin Packages (Bengali -> English)
    String converted = cleanTitle;

    // Convert Bengali digits (০-৯) to English (0-9)
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    for (int i = 0; i < 10; i++) {
      converted = converted.replaceAll(bnDigits[i], i.toString());
    }

    final replacements = <Pattern, String>{
      RegExp(r'দিনের|দিন|দিবস'): 'Days',
      RegExp(r'মাসের|মাস'): 'Month',
      RegExp(r'বছরের|বছর'): 'Year',
      RegExp(r'মেয়াদি|মেয়াদ'): '',
      RegExp(r'স্টার্টার|স্টার্টিং'): 'Starter',
      RegExp(r'স্ট্যান্ডার্ড'): 'Standard',
      RegExp(r'প্রিমিয়াম|প্রিমিয়াম'): 'Premium',
      RegExp(r'প্রো'): 'Pro',
      RegExp(r'বেসিক'): 'Basic',
      RegExp(r'এন্টারপ্রাইজ'): 'Enterprise',
      RegExp(r'প্যাকেজ'): 'Package',
      RegExp(r'প্ল্যান'): 'Plan',
      RegExp(r'বাড়িওয়ালা|মালিক'): 'House Owner',
      RegExp(r'ভাড়াটিয়া'): 'Tenant',
      RegExp(r'সাবস্ক্রিপশন'): 'Subscription',
      RegExp(r'আনলিমিটেড'): 'Unlimited',
      RegExp(r'স্পেশাল'): 'Special',
      RegExp(r'অফার'): 'Offer',
      RegExp(r'বিজ্ঞাপন'): 'Listing',
      RegExp(r'পোস্ট'): 'Post',
      RegExp(r'চাহিদা'): 'Demand',
      RegExp(r'ভিআইপি'): 'VIP',
      RegExp(r'গোল্ড'): 'Gold',
      RegExp(r'সিলভার'): 'Silver',
      RegExp(r'প্লাটিনাম'): 'Platinum',
    };

    replacements.forEach((pattern, replacement) {
      converted = converted.replaceAll(pattern, replacement);
    });

    converted = converted.replaceAll(RegExp(r'\s+'), ' ').trim();

    final hasRemainingBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(converted);
    if (hasRemainingBengali || converted.isEmpty) {
      if (cleanId.isNotEmpty) {
        return cleanId
            .replaceAll('_', ' ')
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
      }
      return 'Subscription Package Plan';
    }

    if (!converted.toLowerCase().contains('package') && !converted.toLowerCase().contains('plan')) {
      converted = '$converted Package';
    }

    return converted;
  }

  
  // 1. REVENUE & SUBSCRIPTIONS FINANCIAL STATEMENT (BILINGUAL / ALL TEXT SUPPORT)
  
  Future<Uint8List> generateRevenueReportPdf({
    required List<SubscriptionTransactionModel> transactions,
    required DateTime? startDate,
    required DateTime? endDate,
    bool isBn = false,
    String? adminEmail,
  }) async {
    final pdf = pw.Document(theme: await _buildPdfTheme());
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final double totalRevenue = transactions.fold(0.0, (sum, t) => sum + t.amountPaid);
    final int totalCount = transactions.length;
    final double avgOrder = totalCount > 0 ? (totalRevenue / totalCount) : 0.0;
    final dateRangeStr = _formatDateRange(startDate, endDate, isBn);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(
          title: isBn ? BengaliPdfShaper.shape('আয় ও সাবস্ক্রিপশন লেনদেন অডিট স্টেটমেন্ট') : 'OFFICIAL REVENUE & SUBSCRIPTIONS AUDIT STATEMENT',
          subtitle: isBn ? BengaliPdfShaper.shape('বাসাবন্ধু হোম রেন্টাল ম্যানেজমেন্ট সিস্টেম • আর্থিক হিসাব প্রতিবেদন') : 'BashaBondhu Home Rental Management System • Financial Statement Report',
          dateRange: dateRangeStr,
          isBn: isBn,
        ),
        footer: (context) => _buildFooter(context, adminEmail, isBn),
        build: (context) => [
          pw.SizedBox(height: 10),
          // KPI Summary Cards Row
          pw.Row(
            children: [
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('মোট অর্জিত আয়') : 'TOTAL GROSS REVENUE',
                value: 'BDT ${currencyFormat.format(totalRevenue)}',
                color: const PdfColor.fromInt(0xFF00897B),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('মোট সফল লেনদেন') : 'TRANSACTIONS COUNT',
                value: isBn ? BengaliPdfShaper.shape('$totalCount টি সফল পেমেন্ট') : '$totalCount Payments',
                color: const PdfColor.fromInt(0xFF0284C7),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('গড় পেমেন্ট মূল্য') : 'AVG. TICKET VALUE',
                value: 'BDT ${currencyFormat.format(avgOrder)}',
                color: const PdfColor.fromInt(0xFF4F46E5),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('পেমেন্ট স্ট্যাটাস') : 'SETTLEMENT STATUS',
                value: isBn ? BengaliPdfShaper.shape('১০০% নিশ্চিত ও ভেরিফাইড') : '100% Verified & Settled',
                color: const PdfColor.fromInt(0xFF10B981),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isBn ? BengaliPdfShaper.shape('লেনদেনের বিস্তারিত অডিট তালিকা (${transactions.length} টি রেকর্ড)') : 'TRANSACTION AUDIT BREAKDOWN (${transactions.length} RECORDS)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.blueGrey900),
              ),
              pw.Text(
                isBn ? BengaliPdfShaper.shape('সকল মূল্য বাংলাদেশি টাকায় (BDT ৳)') : 'All amounts in Bangladeshi Taka (BDT)',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // Transactions Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00897B)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(2.0),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(2.5),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(2.0),
              7: const pw.FlexColumnWidth(1.6),
            },
            headers: isBn
                ? [
                    BengaliPdfShaper.shape('নং'),
                    BengaliPdfShaper.shape('ট্রানজাকশন ID'),
                    BengaliPdfShaper.shape('ইউজার ইমেইল'),
                    BengaliPdfShaper.shape('মোবাইল / প্রেরক'),
                    BengaliPdfShaper.shape('প্যাকেজের বিবরণ'),
                    BengaliPdfShaper.shape('মেথড'),
                    BengaliPdfShaper.shape('তারিখ ও সময়'),
                    BengaliPdfShaper.shape('টাকা (BDT)')
                  ]
                : ['#', 'TRANSACTION ID', 'USER EMAIL', 'MOBILE / SENDER', 'PACKAGE PLAN', 'METHOD', 'DATE & TIME', 'AMOUNT (BDT)'],
            data: List.generate(transactions.length, (idx) {
              final t = transactions[idx];
              final trxId = t.transactionId.isNotEmpty ? t.transactionId : (t.id.length > 8 ? t.id.substring(0, 8).toUpperCase() : t.id.toUpperCase());
              final mobile = t.userMobile.isNotEmpty ? t.userMobile : (t.senderPhone.isNotEmpty ? t.senderPhone : 'N/A');
              final formattedPlan = formatPlanTitle(t.planTitle, t.planId, isBn);

              return [
                (idx + 1).toString(),
                trxId,
                t.userEmail,
                mobile,
                formattedPlan,
                t.paymentMethod.toUpperCase(),
                dateFormat.format(t.purchasedAt),
                currencyFormat.format(t.amountPaid),
              ];
            }),
          ),
          pw.SizedBox(height: 14),

          // Total Summary Strip
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 280,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(isBn ? BengaliPdfShaper.shape('মোট অর্জিত আয় (NET TOTAL):') : 'NET REVENUE TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                  pw.Text(
                    'BDT ${currencyFormat.format(totalRevenue)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: const PdfColor.fromInt(0xFF00897B)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  
  // 2. PROPERTY LISTINGS & INVENTORY AUDIT (BILINGUAL)

  Future<Uint8List> generatePropertiesReportPdf({
    required List<PropertyModel> properties,
    required DateTime? startDate,
    required DateTime? endDate,
    bool isBn = false,
    String? adminEmail,
  }) async {
    final pdf = pw.Document(theme: await _buildPdfTheme());
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final dateFormat = DateFormat('dd MMM yyyy');

    final int total = properties.length;
    final int approved = properties.where((p) => p.isApproved && p.approvalStatus != 'rejected').length;
    final int pending = properties.where((p) => p.approvalStatus == 'pending').length;
    final int rejected = properties.where((p) => p.approvalStatus == 'rejected').length;

    final double totalRentVal = properties.fold(0.0, (sum, p) {
      final rent = double.tryParse(p.amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      return sum + rent;
    });

    final dateRangeStr = _formatDateRange(startDate, endDate, isBn);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(
          title: isBn ? BengaliPdfShaper.shape('বাড়িভাড়া বিজ্ঞাপন ও ইনভেন্টরি অডিট রিপোর্ট') : 'PROPERTY LISTINGS & INVENTORY AUDIT REPORT',
          subtitle: isBn ? BengaliPdfShaper.shape('বাড়িওয়ালাদের বিজ্ঞাপনের অনুমোদন ও স্ট্যাটাস প্রতিবেদন') : 'House Owner Property Listings Inventory & Approval Status Overview',
          dateRange: dateRangeStr,
          isBn: isBn,
        ),
        footer: (context) => _buildFooter(context, adminEmail, isBn),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('মোট বিজ্ঞাপন') : 'TOTAL LISTINGS',
                value: total.toString(),
                color: const PdfColor.fromInt(0xFF0284C7),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('অনুমোদিত ও লাইভ') : 'APPROVED & LIVE',
                value: approved.toString(),
                color: const PdfColor.fromInt(0xFF10B981),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('রিভিউ পেন্ডিং') : 'PENDING REVIEW',
                value: pending.toString(),
                color: const PdfColor.fromInt(0xFFF59E0B),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('বাতিল / নিষ্ক্রিয়') : 'REJECTED / INACTIVE',
                value: rejected.toString(),
                color: const PdfColor.fromInt(0xFFE53935),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('সম্ভাব্য মোট ভাড়া') : 'TOTAL EST. RENT',
                value: 'BDT ${currencyFormat.format(totalRentVal)}',
                color: const PdfColor.fromInt(0xFF00897B),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            isBn ? BengaliPdfShaper.shape('বিজ্ঞাপনের বিস্তারিত তালিকা (${properties.length} টি প্রপার্টি)') : 'PROPERTY INVENTORY AUDIT DETAILS (${properties.length} PROPERTIES)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.blueGrey900),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0284C7)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(2.6),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(2.2),
              5: const pw.FlexColumnWidth(1.6),
              6: const pw.FlexColumnWidth(1.4),
              7: const pw.FlexColumnWidth(1.6),
            },
            headers: isBn
                ? [
                    BengaliPdfShaper.shape('নং'),
                    BengaliPdfShaper.shape('ধরন'),
                    BengaliPdfShaper.shape('ঠিকানা ও লোকেশন'),
                    BengaliPdfShaper.shape('ভাড়া (টাকা)'),
                    BengaliPdfShaper.shape('বাড়িওয়ালা / যোগাযোগ'),
                    BengaliPdfShaper.shape('মোবাইল'),
                    BengaliPdfShaper.shape('স্ট্যাটাস'),
                    BengaliPdfShaper.shape('পোস্ট তারিখ')
                  ]
                : ['#', 'HOUSE TYPE', 'LOCATION / ADDRESS', 'RENT (BDT)', 'OWNER / CONTACT', 'PHONE', 'STATUS', 'POST DATE'],
            data: List.generate(properties.length, (idx) {
              final p = properties[idx];
              final date = dateFormat.format(p.postDate);
              final owner = p.contactName.isNotEmpty ? (isBn ? BengaliPdfShaper.shape(p.contactName) : p.contactName) : p.ownerEmail;
              final loc = p.shortAddress.isNotEmpty ? (isBn ? BengaliPdfShaper.shape(p.shortAddress) : p.shortAddress) : '${p.area.name}, ${p.district.name}';
              final status = isBn ? (p.approvalStatus == 'approved' ? BengaliPdfShaper.shape('অনুমোদিত') : (p.approvalStatus == 'pending' ? BengaliPdfShaper.shape('পেন্ডিং') : BengaliPdfShaper.shape('বাতিল'))) : p.approvalStatus.toUpperCase();

              return [
                (idx + 1).toString(),
                p.houseType.name.toUpperCase(),
                loc,
                p.amount,
                owner,
                p.userMobile.isNotEmpty ? p.userMobile : 'N/A',
                status,
                date,
              ];
            }),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  
  // 3. TENANT DEMANDS REPORT PDF (BILINGUAL)
  
  Future<Uint8List> generateDemandsReportPdf({
    required List<TenantDemandModel> demands,
    required DateTime? startDate,
    required DateTime? endDate,
    bool isBn = false,
    String? adminEmail,
  }) async {
    final pdf = pw.Document(theme: await _buildPdfTheme());
    final dateFormat = DateFormat('dd MMM yyyy');

    final int total = demands.length;
    final int approved = demands.where((d) => d.isApproved && d.approvalStatus != 'rejected').length;
    final int pending = demands.where((d) => d.approvalStatus == 'pending').length;
    final int rejected = demands.where((d) => d.approvalStatus == 'rejected').length;

    final dateRangeStr = _formatDateRange(startDate, endDate, isBn);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(
          title: isBn ? BengaliPdfShaper.shape('ভাড়াটিয়াদের বাসা খোঁজার চাহিদা অডিট রিপোর্ট') : 'TENANT RENTAL DEMANDS AUDIT REPORT',
          subtitle: isBn ? BengaliPdfShaper.shape('ভাড়াটিয়াদের এলাকাভিত্তিক চাহিদাকৃত বাসার তালিকা ও বাজেট বিবরণী') : 'Tenant Accommodation Requirements & Budget Spread Overview',
          dateRange: dateRangeStr,
          isBn: isBn,
        ),
        footer: (context) => _buildFooter(context, adminEmail, isBn),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('মোট চাহিদা') : 'TOTAL DEMANDS',
                value: total.toString(),
                color: const PdfColor.fromInt(0xFF4F46E5),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('অনুমোদিত ও লাইভ') : 'APPROVED & LIVE',
                value: approved.toString(),
                color: const PdfColor.fromInt(0xFF10B981),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('রিভিউ পেন্ডিং') : 'PENDING REVIEW',
                value: pending.toString(),
                color: const PdfColor.fromInt(0xFFF59E0B),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('বাতিল / বন্ধ') : 'REJECTED / CLOSED',
                value: rejected.toString(),
                color: const PdfColor.fromInt(0xFFE53935),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            isBn ? BengaliPdfShaper.shape('চাহিদা পোস্টের তালিকা (${demands.length} টি রেকর্ড)') : 'TENANT DEMANDS LIST (${demands.length} RECORDS)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.blueGrey900),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF4F46E5)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(2.4),
              3: const pw.FlexColumnWidth(1.6),
              4: const pw.FlexColumnWidth(1.8),
              5: const pw.FlexColumnWidth(2.2),
              6: const pw.FlexColumnWidth(1.6),
              7: const pw.FlexColumnWidth(1.3),
              8: const pw.FlexColumnWidth(1.5),
            },
            headers: isBn
                ? [
                    BengaliPdfShaper.shape('নং'),
                    BengaliPdfShaper.shape('ধরন'),
                    BengaliPdfShaper.shape('প্রয়োজনীয় এলাকা'),
                    BengaliPdfShaper.shape('বাজেট সীমা (টাকা)'),
                    BengaliPdfShaper.shape('ভাড়াটিয়ার নাম'),
                    BengaliPdfShaper.shape('ইমেইল'),
                    BengaliPdfShaper.shape('মোবাইল'),
                    BengaliPdfShaper.shape('স্ট্যাটাস'),
                    BengaliPdfShaper.shape('তারিখ')
                  ]
                : ['#', 'HOUSE TYPE', 'TARGET LOCATION', 'BUDGET RANGE (BDT)', 'TENANT NAME', 'EMAIL', 'MOBILE', 'STATUS', 'POST DATE'],
            data: List.generate(demands.length, (idx) {
              final d = demands[idx];
              final date = dateFormat.format(d.postDate);
              final loc = '${d.area.name}, ${d.district.name}';
              final name = d.userName.isNotEmpty ? (isBn ? BengaliPdfShaper.shape(d.userName) : d.userName) : (isBn ? BengaliPdfShaper.shape('ভাড়াটিয়া') : 'Tenant');
              final status = isBn ? (d.approvalStatus == 'approved' ? BengaliPdfShaper.shape('অনুমোদিত') : (d.approvalStatus == 'pending' ? BengaliPdfShaper.shape('পেন্ডিং') : BengaliPdfShaper.shape('বাতিল'))) : d.approvalStatus.toUpperCase();

              return [
                (idx + 1).toString(),
                d.houseType.name.toUpperCase(),
                loc,
                d.budgetRange ?? 'N/A',
                name,
                d.tenantEmail,
                d.userMobile.isNotEmpty ? d.userMobile : 'N/A',
                status,
                date,
              ];
            }),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  
  // 4. HOUSE OWNERS & KYC AUDIT REPORT PDF (BILINGUAL)
  
  Future<Uint8List> generateHouseOwnersReportPdf({
    required List<UserModel> owners,
    required DateTime? startDate,
    required DateTime? endDate,
    bool isBn = false,
    String? adminEmail,
  }) async {
    final pdf = pw.Document(theme: await _buildPdfTheme());
    final dateFormat = DateFormat('dd MMM yyyy');

    final int total = owners.length;
    final int verified = owners.where((u) => u.isVerified).length;
    final int pending = owners.where((u) => u.isVerificationPending).length;
    final int blocked = owners.where((u) => u.isBlocked).length;

    final dateRangeStr = _formatDateRange(startDate, endDate, isBn);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(
          title: isBn ? BengaliPdfShaper.shape('বাড়িওয়ালাদের তালিকা ও NID ভেরিফিকেশন অডিট রিপোর্ট') : 'HOUSE OWNERS DIRECTORY & KYC AUDIT REPORT',
          subtitle: isBn ? BengaliPdfShaper.shape('নিবন্ধিত বাড়িওয়ালাদের প্রোফাইল ও জাতীয় পরিচয়পত্র ভেরিফিকেশন') : 'Registered Property Owners & NID Verification Compliance Directory',
          dateRange: dateRangeStr,
          isBn: isBn,
        ),
        footer: (context) => _buildFooter(context, adminEmail, isBn),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('মোট বাড়িওয়ালা') : 'TOTAL HOUSE OWNERS',
                value: total.toString(),
                color: const PdfColor.fromInt(0xFF0D9488),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('NID ভেরিফাইড') : 'NID VERIFIED',
                value: verified.toString(),
                color: const PdfColor.fromInt(0xFF10B981),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('ভেরিফিকেশন পেন্ডিং') : 'KYC PENDING',
                value: pending.toString(),
                color: const PdfColor.fromInt(0xFFF59E0B),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('স্থগিত / ব্লকড') : 'SUSPENDED / BLOCKED',
                value: blocked.toString(),
                color: const PdfColor.fromInt(0xFFE53935),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            isBn ? BengaliPdfShaper.shape('বাড়িওয়ালাদের তালিকা (${owners.length} জন)') : 'HOUSE OWNERS DIRECTORY LIST (${owners.length} ACCOUNTS)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.blueGrey900),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0D9488)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(2.0),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(1.8),
              5: const pw.FlexColumnWidth(1.5),
              6: const pw.FlexColumnWidth(1.3),
              7: const pw.FlexColumnWidth(1.6),
            },
            headers: isBn
                ? [
                    BengaliPdfShaper.shape('নং'),
                    BengaliPdfShaper.shape('বাড়িওয়ালার নাম'),
                    BengaliPdfShaper.shape('ইমেইল এড্রেস'),
                    BengaliPdfShaper.shape('মোবাইল নম্বর'),
                    BengaliPdfShaper.shape('শহর / জেলা'),
                    BengaliPdfShaper.shape('NID স্ট্যাটাস'),
                    BengaliPdfShaper.shape('অ্যাকাউন্ট'),
                    BengaliPdfShaper.shape('যোগদানের তারিখ')
                  ]
                : ['#', 'OWNER FULL NAME', 'EMAIL ADDRESS', 'MOBILE NUMBER', 'CITY / DISTRICT', 'NID / KYC STATUS', 'ACCOUNT STATUS', 'JOINED DATE'],
            data: List.generate(owners.length, (idx) {
              final u = owners[idx];
              final rawName = u.fullName.isNotEmpty ? u.fullName : '${u.firstName} ${u.lastName}'.trim();
              final name = isBn && rawName.isNotEmpty ? BengaliPdfShaper.shape(rawName) : (rawName.isNotEmpty ? rawName : 'Owner #${idx + 1}');
              DateTime? createdDt;
              try {
                createdDt = DateTime.tryParse(u.createdAt);
              } catch (_) {}
              final date = createdDt != null ? dateFormat.format(createdDt) : 'N/A';
              final kyc = isBn
                  ? (u.isVerified ? BengaliPdfShaper.shape('ভেরিফাইড') : (u.isVerificationPending ? BengaliPdfShaper.shape('পেন্ডিং') : BengaliPdfShaper.shape('আনভেরিফাইড')))
                  : (u.isVerified ? 'VERIFIED' : (u.isVerificationPending ? 'PENDING' : 'UNVERIFIED'));
              final status = isBn
                  ? (u.isBlocked ? BengaliPdfShaper.shape('স্থগিত') : BengaliPdfShaper.shape('সক্রিয়'))
                  : (u.isBlocked ? 'SUSPENDED' : 'ACTIVE');
              final city = isBn && u.city.isNotEmpty ? BengaliPdfShaper.shape(u.city) : (u.city.isNotEmpty ? u.city : 'N/A');

              return [
                (idx + 1).toString(),
                name,
                u.email,
                u.mobile.isNotEmpty ? u.mobile : 'N/A',
                city,
                kyc,
                status,
                date,
              ];
            }),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  
  // 5. TENANTS & KYC AUDIT REPORT PDF (BILINGUAL)
  
  Future<Uint8List> generateTenantsReportPdf({
    required List<UserModel> tenants,
    required DateTime? startDate,
    required DateTime? endDate,
    bool isBn = false,
    String? adminEmail,
  }) async {
    final pdf = pw.Document(theme: await _buildPdfTheme());
    final dateFormat = DateFormat('dd MMM yyyy');

    final int total = tenants.length;
    final int verified = tenants.where((u) => u.isVerified).length;
    final int pending = tenants.where((u) => u.isVerificationPending).length;
    final int subscribed = tenants.where((u) => u.isSubscribed).length;
    final int blocked = tenants.where((u) => u.isBlocked).length;

    final dateRangeStr = _formatDateRange(startDate, endDate, isBn);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(
          title: isBn ? BengaliPdfShaper.shape('ভাড়াটিয়াদের তালিকা ও NID ভেরিফিকেশন অডিট রিপোর্ট') : 'TENANTS DIRECTORY & KYC AUDIT REPORT',
          subtitle: isBn ? BengaliPdfShaper.shape('নিবন্ধিত ভাড়াটিয়াদের প্রোফাইল, সাবস্ক্রিপশন ও NID ভেরিফিকেশন') : 'Registered Tenant Accounts, Subscription Tier & NID Compliance',
          dateRange: dateRangeStr,
          isBn: isBn,
        ),
        footer: (context) => _buildFooter(context, adminEmail, isBn),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('মোট ভাড়াটিয়া') : 'TOTAL TENANTS',
                value: total.toString(),
                color: const PdfColor.fromInt(0xFF7C3AED),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('NID ভেরিফাইড') : 'NID VERIFIED',
                value: verified.toString(),
                color: const PdfColor.fromInt(0xFF10B981),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('ভেরিফিকেশন পেন্ডিং') : 'KYC PENDING',
                value: pending.toString(),
                color: const PdfColor.fromInt(0xFFF59E0B),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('প্রিমিয়াম সক্রিয়') : 'PREMIUM SUBSCRIBED',
                value: subscribed.toString(),
                color: const PdfColor.fromInt(0xFF0284C7),
              ),
              pw.SizedBox(width: 10),
              _buildKpiCard(
                title: isBn ? BengaliPdfShaper.shape('স্থগিত / ব্লকড') : 'SUSPENDED / BLOCKED',
                value: blocked.toString(),
                color: const PdfColor.fromInt(0xFFE53935),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            isBn ? BengaliPdfShaper.shape('ভাড়াটিয়াদের তালিকা (${tenants.length} জন)') : 'TENANTS DIRECTORY LIST (${tenants.length} ACCOUNTS)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5, color: PdfColors.blueGrey900),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7C3AED)),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.6),
              1: const pw.FlexColumnWidth(2.0),
              2: const pw.FlexColumnWidth(2.4),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(1.6),
              5: const pw.FlexColumnWidth(1.4),
              6: const pw.FlexColumnWidth(1.5),
              7: const pw.FlexColumnWidth(1.2),
              8: const pw.FlexColumnWidth(1.5),
            },
            headers: isBn
                ? [
                    BengaliPdfShaper.shape('নং'),
                    BengaliPdfShaper.shape('ভাড়াটিয়ার নাম'),
                    BengaliPdfShaper.shape('ইমেইল এড্রেস'),
                    BengaliPdfShaper.shape('মোবাইল নম্বর'),
                    BengaliPdfShaper.shape('শহর / জেলা'),
                    BengaliPdfShaper.shape('NID স্ট্যাটাস'),
                    BengaliPdfShaper.shape('সাবস্ক্রিপশন'),
                    BengaliPdfShaper.shape('অ্যাকাউন্ট'),
                    BengaliPdfShaper.shape('তারিখ')
                  ]
                : ['#', 'TENANT FULL NAME', 'EMAIL ADDRESS', 'MOBILE NUMBER', 'CITY / DISTRICT', 'NID / KYC STATUS', 'SUBSCRIPTION', 'STATUS', 'JOINED DATE'],
            data: List.generate(tenants.length, (idx) {
              final u = tenants[idx];
              final rawName = u.fullName.isNotEmpty ? u.fullName : '${u.firstName} ${u.lastName}'.trim();
              final name = isBn && rawName.isNotEmpty ? BengaliPdfShaper.shape(rawName) : (rawName.isNotEmpty ? rawName : 'Tenant #${idx + 1}');
              DateTime? createdDt;
              try {
                createdDt = DateTime.tryParse(u.createdAt);
              } catch (_) {}
              final date = createdDt != null ? dateFormat.format(createdDt) : 'N/A';
              final kyc = isBn
                  ? (u.isVerified ? BengaliPdfShaper.shape('ভেরিফাইড') : (u.isVerificationPending ? BengaliPdfShaper.shape('পেন্ডিং') : BengaliPdfShaper.shape('আনভেরিফাইড')))
                  : (u.isVerified ? 'VERIFIED' : (u.isVerificationPending ? 'PENDING' : 'UNVERIFIED'));
              final sub = isBn
                  ? (u.isSubscribed ? BengaliPdfShaper.shape('প্রিমিয়াম') : BengaliPdfShaper.shape('ফ্রি টায়ার'))
                  : (u.isSubscribed ? 'PREMIUM' : 'FREE TIER');
              final status = isBn
                  ? (u.isBlocked ? BengaliPdfShaper.shape('স্থগিত') : BengaliPdfShaper.shape('সক্রিয়'))
                  : (u.isBlocked ? 'SUSPENDED' : 'ACTIVE');
              final city = isBn && u.city.isNotEmpty ? BengaliPdfShaper.shape(u.city) : (u.city.isNotEmpty ? u.city : 'N/A');

              return [
                (idx + 1).toString(),
                name,
                u.email,
                u.mobile.isNotEmpty ? u.mobile : 'N/A',
                city,
                kyc,
                sub,
                status,
                date,
              ];
            }),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  
  // 6. SINGLE TRANSACTION PAYMENT RECEIPT / TAX INVOICE (PORTRAIT A4, BILINGUAL)
  
  Future<Uint8List> generateSingleTransactionReceiptPdf({
    required SubscriptionTransactionModel transaction,
    bool isBn = false,
    String? adminEmail,
  }) async {
    final pdf = pw.Document(theme: await _buildPdfTheme());
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
    final formattedPlan = formatPlanTitle(transaction.planTitle, transaction.planId, isBn);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Header & Paid Badge
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BASHABONDHU',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF00897B),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      isBn ? BengaliPdfShaper.shape('অফিসিয়াল সাবস্ক্রিপশন পেমেন্ট রিসিট ও ইনভয়েস') : 'Official Subscription Payment Receipt & Invoice',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.green700, width: 1.2),
                  ),
                  child: pw.Text(
                    isBn ? BengaliPdfShaper.shape('পরিশোধিত ও সক্রিয়') : 'PAID & SETTLED',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green800),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1.5, color: const PdfColor.fromInt(0xFF00897B)),
            pw.SizedBox(height: 16),

            // Metadata Grid
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(isBn ? BengaliPdfShaper.shape('গ্রাহকের বিবরণ (BILLED TO):') : 'BILLED TO (CUSTOMER):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Account Email: ${transaction.userEmail}', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.Text('Account Mobile: ${transaction.userMobile.isNotEmpty ? transaction.userMobile : "N/A"}', style: const pw.TextStyle(fontSize: 9.5)),
                    if (transaction.senderPhone.isNotEmpty)
                      pw.Text('MFS Sender Mobile: ${transaction.senderPhone}', style: const pw.TextStyle(fontSize: 9.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(isBn ? BengaliPdfShaper.shape('রিসিট বিবরণী (RECEIPT INFO):') : 'RECEIPT DETAILS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blueGrey900)),
                    pw.SizedBox(height: 4),
                    pw.Text('Receipt No: #${transaction.id.length > 8 ? transaction.id.substring(0, 8).toUpperCase() : transaction.id.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                    pw.Text('Transaction ID (TrxID): ${transaction.transactionId}', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.Text('Payment Date: ${dateFormat.format(transaction.purchasedAt)}', style: const pw.TextStyle(fontSize: 9.5)),
                    pw.Text('Plan Valid Until: ${dateFormat.format(transaction.expiresAt)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF00897B))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Item Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              columnWidths: {
                0: const pw.FlexColumnWidth(4.5),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00897B)),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(isBn ? BengaliPdfShaper.shape('প্যাকেজের বিবরণ') : 'DESCRIPTION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(isBn ? BengaliPdfShaper.shape('পেমেন্ট চ্যানেল') : 'PAYMENT CHANNEL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(isBn ? BengaliPdfShaper.shape('পরিশোধিত মূল্য (টাকা)') : 'AMOUNT (BDT)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9.5), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(formattedPlan, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                          pw.SizedBox(height: 2),
                          pw.Text('Plan SKU / ID: ${transaction.planId}', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                          pw.Text(
                            'Access: Full Unlimited Features & Direct Contacts',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text('${transaction.paymentMethod.toUpperCase()} (MFS Gateway)', style: const pw.TextStyle(fontSize: 9.5)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text('BDT ${currencyFormat.format(transaction.amountPaid)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Summary Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 240,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(isBn ? BengaliPdfShaper.shape('সাবটোটাল:') : 'Subtotal:', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('BDT ${currencyFormat.format(transaction.amountPaid)}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(isBn ? BengaliPdfShaper.shape('ভ্যাট / চার্জ:') : 'Taxes & Fee:', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('BDT 0.00', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(isBn ? BengaliPdfShaper.shape('সর্বমোট পরিশোধ:') : 'TOTAL PAID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                        pw.Text(
                          'BDT ${currencyFormat.format(transaction.amountPaid)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: const PdfColor.fromInt(0xFF00897B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.Spacer(),

            // Terms & Signature Footer
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(isBn ? BengaliPdfShaper.shape('গ্রাহক সেবা ও সহায়তা:') : 'CUSTOMER SUPPORT & HELP DESK:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                    pw.Text('Helpline: +880 1700-000000 • Email: support@bashabondhu.com', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('Official Portal: https://bashabondhu.com', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(isBn ? BengaliPdfShaper.shape('ডিজিটাল ভেরিফিকেশন সিল') : 'Authorized Electronic Stamp', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('BASHABONDHU SYSTEM VERIFIED', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF00897B))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ==========================================================================
  // SHARED PDF WIDGET HELPERS
  // ==========================================================================
  pw.Widget _buildHeader({
    required String title,
    required String subtitle,
    required String dateRange,
    required bool isBn,
  }) {
    final nowFormatted = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF00897B), width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 22,
                    height: 22,
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFF00897B),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text('B', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    isBn ? BengaliPdfShaper.shape('বাসাবন্ধু ম্যানেজমেন্ট সিস্টেম') : 'BashaBondhu Management System',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13.5, color: const PdfColor.fromInt(0xFF00897B)),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  '${isBn ? BengaliPdfShaper.shape("সময়কাল: ") : "Audit Filter: "}$dateRange',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF00897B)),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${isBn ? BengaliPdfShaper.shape("জেনারেট তারিখ: ") : "Generated on: "}$nowFormatted',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, String? adminEmail, bool isBn) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isBn
                ? BengaliPdfShaper.shape('বাসাবন্ধু হোম রেন্টাল ম্যানেজমেন্ট সিস্টেম • কনফিডেন্সিয়াল অ্যাডমিনিস্ট্রেটর অডিট')
                : 'BashaBondhu Home Rental Management System • Confidential Administrator Audit',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
          ),
          pw.Text(
            '${isBn ? BengaliPdfShaper.shape("পৃষ্ঠা ") : "Page "}${context.pageNumber}${isBn ? BengaliPdfShaper.shape(" এর ") : " of "}${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildKpiCard({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 0.9),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end, bool isBn) {
    if (start == null && end == null) {
      return isBn ? BengaliPdfShaper.shape('সর্বমোট (সম্পূর্ণ ইতিহাস)') : 'All Time (Complete History)';
    }
    final format = DateFormat('dd MMM yyyy');
    if (start != null && end != null) {
      return '${format.format(start)} - ${format.format(end)}';
    } else if (start != null) {
      return isBn ? '${format.format(start)} ${BengaliPdfShaper.shape("হতে")}' : 'From ${format.format(start)} onwards';
    } else {
      return isBn ? '${format.format(end!)} ${BengaliPdfShaper.shape("পর্যন্ত")}' : 'Until ${format.format(end!)}';
    }
  }
}
