import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_colors.dart';

class AdminPdfPreviewModal extends StatefulWidget {
  final Future<Uint8List> Function() pdfFuture;
  final String title;
  final String fileName;
  final bool isBn;

  const AdminPdfPreviewModal({
    super.key,
    required this.pdfFuture,
    required this.title,
    required this.fileName,
    this.isBn = false,
  });

  static void show(
    BuildContext context, {
    required Future<Uint8List> Function() pdfFuture,
    required String title,
    required String fileName,
    required bool isBn,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: AdminPdfPreviewModal(
          pdfFuture: pdfFuture,
          title: title,
          fileName: fileName,
          isBn: isBn,
        ),
      ),
    );
  }

  @override
  State<AdminPdfPreviewModal> createState() => _AdminPdfPreviewModalState();
}

class _AdminPdfPreviewModalState extends State<AdminPdfPreviewModal> {
  Uint8List? _cachedData;
  bool _isDownloading = false;

  Future<Uint8List> _getPdfBytes() async {
    if (_cachedData != null) {
      return Uint8List.fromList(_cachedData!);
    }
    final raw = await widget.pdfFuture();
    _cachedData = Uint8List.fromList(raw);
    return Uint8List.fromList(_cachedData!);
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final bytes = await _getPdfBytes();
      String? savedPath;

      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: Uint8List.fromList(bytes),
          filename: widget.fileName,
        );
      } else {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
          if (userProfile != null) {
            final downloadsDir = Directory('$userProfile/Downloads');
            final targetDir = downloadsDir.existsSync() ? downloadsDir : Directory(userProfile);
            final filePath = '${targetDir.path}\\${widget.fileName}';
            final file = File(filePath);
            await file.writeAsBytes(Uint8List.fromList(bytes));
            savedPath = filePath;
          }
        } else {
          await Printing.sharePdf(
            bytes: Uint8List.fromList(bytes),
            filename: widget.fileName,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  savedPath != null
                      ? (widget.isBn
                          ? 'PDF ফাইলটি সফলভাবে ডাউনলোড করা হয়েছে:\n$savedPath'
                          : 'PDF saved successfully to Downloads:\n$savedPath')
                      : (widget.isBn ? 'PDF ডাউনলোড সম্পন্ন হয়েছে' : 'PDF download completed successfully'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00897B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          action: savedPath != null
              ? SnackBarAction(
                  label: widget.isBn ? 'ফাইল খুলুন' : 'Open File',
                  textColor: Colors.yellowAccent,
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.file(savedPath!));
                    } catch (_) {}
                  },
                )
              : null,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBn ? 'ডাউনলোডে সমস্যা হয়েছে: $e' : 'Failed to download PDF: $e',
            style: const TextStyle(fontSize: 12.5),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final double modalWidth = (size.width * 0.9).clamp(320.0, 950.0);
    final double modalHeight = (size.height * 0.88).clamp(400.0, 800.0);

    return Container(
      width: modalWidth,
      height: modalHeight,
      color: isDark ? const Color(0xFF0F1E1B) : Colors.white,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162B27) : const Color(0xFFF1F5F9),
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF23443E) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.themeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isBn
                            ? 'অফিসিয়াল PDF রিপোর্ট প্রিভিউ, প্রিন্ট বা ডাউনলোড করুন'
                            : 'Preview, Print, or Download Official PDF Report',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isDownloading ? null : _handleDownload,
                  icon: _isDownloading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    widget.isBn ? 'ডাউনলোড' : 'Download',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: widget.isBn ? 'বন্ধ করুন' : 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // PDF Preview Body
          Expanded(
            child: PdfPreview(
              build: (format) => _getPdfBytes(),
              pdfFileName: widget.fileName,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowSharing: false,
              allowPrinting: true,
              actions: [
                PdfPreviewAction(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: (ctx, buildFn, format) => _handleDownload(),
                ),
              ],
              maxPageWidth: 850,
              previewPageMargin: const EdgeInsets.all(12),
              loadingWidget: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.themeColor),
                    const SizedBox(height: 14),
                    Text(
                      widget.isBn
                          ? 'উচ্চমানের PDF ডকুমেন্ট তৈরি হচ্ছে...'
                          : 'Generating High-Quality PDF Document...',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              onError: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        widget.isBn
                            ? 'ডকুমেন্ট তৈরিতে সমস্যা হয়েছে: $error'
                            : 'Failed to generate PDF document: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => setState(() => _cachedData = null),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(widget.isBn ? 'পুনরায় চেষ্টা করুন' : 'Try Again'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
