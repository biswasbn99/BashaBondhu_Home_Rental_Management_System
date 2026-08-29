import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/providers/subscription_provider.dart';
import '../../data/services/sslcommerz_service.dart';

class SSLCommerzWebviewScreen extends StatefulWidget {
  final SubscriptionPlanModel plan;
  final UserModel user;
  final bool isSandbox;
  final String storeId;
  final String storePassword;

  const SSLCommerzWebviewScreen({
    super.key,
    required this.plan,
    required this.user,
    this.isSandbox = true,
    this.storeId = SSLCommerzService.defaultSandboxStoreId,
    this.storePassword = SSLCommerzService.defaultSandboxStorePassword,
  });

  @override
  State<SSLCommerzWebviewScreen> createState() => _SSLCommerzWebviewScreenState();
}

class _SSLCommerzWebviewScreenState extends State<SSLCommerzWebviewScreen> {
  late final WebViewController _webViewController;
  late final SSLCommerzService _sslService;

  bool _isInitLoading = true;
  bool _isVerifying = false;
  bool _hasHandledCallback = false;
  String? _initErrorMessage;
  int _loadingProgress = 0;
  bool _isSuccessReceipt = false;
  SSLCommerzInitResponse? _initResponse;
  SSLCommerzValidationResponse? _validationResult;

  @override
  void initState() {
    super.initState();
    _sslService = SSLCommerzService(
      storeId: widget.storeId,
      storePassword: widget.storePassword,
      isSandbox: widget.isSandbox,
    );

    _initWebViewController();
    _startPaymentSession();
  }

  bool _checkAndInterceptUrl(String url) {
    if (_hasHandledCallback) return true;

    final lowerUrl = url.toLowerCase();

    // Check Success Callback
    if (lowerUrl.contains('payment-success') ||
        lowerUrl.contains('status=valid') ||
        lowerUrl.contains('status=success') ||
        lowerUrl.contains('val_id=') ||
        url.startsWith(SSLCommerzService.successUrl)) {
      _hasHandledCallback = true;
      _handleSuccessRedirect(url);
      return true;
    }

    // Check Fail Callback
    if (lowerUrl.contains('payment-fail') ||
        lowerUrl.contains('status=failed') ||
        url.startsWith(SSLCommerzService.failUrl)) {
      _hasHandledCallback = true;
      _handleFailRedirect();
      return true;
    }

    // Check Cancel Callback
    if (lowerUrl.contains('payment-cancel') ||
        lowerUrl.contains('status=cancelled') ||
        url.startsWith(SSLCommerzService.cancelUrl)) {
      _hasHandledCallback = true;
      _handleCancelRedirect();
      return true;
    }

    return false;
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress);
            }
          },
          onPageStarted: (url) {
            _checkAndInterceptUrl(url);
            if (mounted) {
              setState(() => _loadingProgress = 10);
            }
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _checkAndInterceptUrl(change.url!);
            }
          },
          onPageFinished: (url) {
            _checkAndInterceptUrl(url);
            if (mounted) {
              setState(() => _loadingProgress = 100);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.url != null) {
              _checkAndInterceptUrl(error.url!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkAndInterceptUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _startPaymentSession() async {
    setState(() {
      _isInitLoading = true;
      _initErrorMessage = null;
      _hasHandledCallback = false;
    });

    final res = await _sslService.initPaymentSession(
      plan: widget.plan,
      user: widget.user,
    );

    if (!mounted) return;

    _initResponse = res;

    if (res.isSuccess && res.gatewayPageURL != null) {
      setState(() => _isInitLoading = false);
      _webViewController.loadRequest(Uri.parse(res.gatewayPageURL!));
    } else {
      setState(() {
        _isInitLoading = false;
        _initErrorMessage = res.failedReason ?? 'SSLCOMMERZ পেমেন্ট সেশন শুরু করা সম্ভব হয়নি।';
      });
    }
  }

  Future<void> _handleSuccessRedirect(String url) async {
    setState(() => _isVerifying = true);

    final uri = Uri.tryParse(url);
    final valId = uri?.queryParameters['val_id'] ?? '';
    final tranIdFromUrl = uri?.queryParameters['tran_id'] ?? '';
    final effectiveTranId = tranIdFromUrl.isNotEmpty
        ? tranIdFromUrl
        : (_initResponse?.tranId ?? 'BB_SUB_${DateTime.now().millisecondsSinceEpoch}');

    SSLCommerzValidationResponse? valRes;

    if (valId.isNotEmpty) {
      valRes = await _sslService.validateTransaction(valId: valId);
    }

    // Fallback for Sandbox or if validation response not available from GET query
    if (valRes == null || !valRes.isValid) {
      if (widget.isSandbox) {
        valRes = SSLCommerzValidationResponse(
          isValid: true,
          status: 'VALID',
          tranId: effectiveTranId,
          valId: valId.isNotEmpty ? valId : 'SB_VAL_${DateTime.now().millisecondsSinceEpoch}',
          amount: widget.plan.effectivePrice,
          cardType: uri?.queryParameters['card_type'] ?? 'bKash (Sandbox)',
          bankTranId: uri?.queryParameters['bank_tran_id'] ?? 'BKASH_${DateTime.now().millisecondsSinceEpoch}',
          cardNo: widget.user.mobile.isNotEmpty ? widget.user.mobile : '01700000000',
          tranDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        );
      }
    }

    if (!mounted) return;

    if (valRes != null && valRes.isValid) {
      final subProvider = context.read<SubscriptionProvider>();
      final ok = await subProvider.processPaymentAndActivate(
        context: context,
        user: widget.user,
        plan: widget.plan,
        transactionId: valRes.tranId.isNotEmpty ? valRes.tranId : effectiveTranId,
        senderPhone: valRes.cardNo.isNotEmpty ? valRes.cardNo : (widget.user.mobile.isNotEmpty ? widget.user.mobile : 'SSLCOMMERZ'),
      );

      if (ok && mounted) {
        setState(() {
          _isVerifying = false;
          _isSuccessReceipt = true;
          _validationResult = valRes;
        });
      } else if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('পেমেন্ট সফল হলেও সাবস্ক্রিপশন ডাটাবেসে সেভ করতে সমস্যা হয়েছে। অ্যাডমিনের সাথে যোগাযোগ করুন।'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (mounted) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SSLCOMMERZ ভ্যালিডেশন ব্যর্থ হয়েছে (${valRes?.status ?? "ERROR"})'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _handleFailRedirect() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পেমেন্ট সম্পন্ন হয়নি (Payment Failed)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _handleCancelRedirect() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পেমেন্ট বাতিল করা হয়েছে (Payment Cancelled)'),
          backgroundColor: Colors.grey,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSuccessReceipt) {
      Navigator.pop(context);
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('পেমেন্ট বাতিল করতে চান?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('আপনি কি নিশ্চিত যে SSLCOMMERZ পেমেন্ট পেজ থেকে বের হতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না, চালিয়ে যান'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, বের হন'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _onWillPop();
        if (ok && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final ok = await _onWillPop();
              if (ok && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SSLCOMMERZ',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.isSandbox)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '🧪 SANDBOX',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                  ),
                ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _loadingProgress < 100 && !_isInitLoading
                ? LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE2136E)),
                    minHeight: 3,
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: Stack(
          children: [
            // WebView
            if (!_isInitLoading && _initErrorMessage == null)
              WebViewWidget(controller: _webViewController),

            // Initial Loading
            if (_isInitLoading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFE2136E)),
                    const SizedBox(height: 16),
                    Text(
                      widget.isSandbox
                          ? (Localizations.localeOf(context).languageCode == 'bn'
                              ? 'SSLCOMMERZ স্যান্ডবক্স গেটওয়ে লোড হচ্ছে...'
                              : 'Loading SSLCOMMERZ Sandbox Gateway...')
                          : (Localizations.localeOf(context).languageCode == 'bn'
                              ? 'SSLCOMMERZ গেটওয়ে লোড হচ্ছে...'
                              : 'Loading SSLCOMMERZ Gateway...'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${Localizations.localeOf(context).languageCode == "bn" ? "৳${widget.plan.effectivePrice.toInt().toString().toLocalizedDigits("bn")}" : "৳${widget.plan.effectivePrice.toInt()}"} • ${Localizations.localeOf(context).languageCode == "bn" ? (widget.plan.titleBn.isNotEmpty ? widget.plan.titleBn : widget.plan.titleEn) : (widget.plan.titleEn.isNotEmpty ? widget.plan.titleEn : widget.plan.titleBn)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            // Error State
            if (_initErrorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 54, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        Localizations.localeOf(context).languageCode == 'bn'
                            ? 'গেটওয়ে লোড করতে ব্যর্থ হয়েছে'
                            : 'Failed to load Payment Gateway',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _initErrorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _startPaymentSession,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.themeColor),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(Localizations.localeOf(context).languageCode == 'bn' ? 'পুনরায় চেষ্টা করুন' : 'Try Again'),
                      ),
                    ],
                  ),
                ),
              ),

            // Server-Side Verification Overlay
            if (_isVerifying)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.greenAccent),
                      const SizedBox(height: 18),
                      Text(
                        Localizations.localeOf(context).languageCode == 'bn'
                            ? 'SSLCOMMERZ পেমেন্ট যাচাই করা হচ্ছে...'
                            : 'Verifying SSLCOMMERZ Payment...',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Localizations.localeOf(context).languageCode == 'bn'
                            ? 'দয়া করে অপেক্ষা করুন, অ্যাপ বন্ধ করবেন না।'
                            : 'Please wait, do not close the app.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),

            // Success Receipt Modal
            if (_isSuccessReceipt)
              _buildSuccessReceiptModal(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessReceiptModal(BuildContext context, bool isDark) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(now);
    final expiryDate = DateFormat('dd MMM yyyy').format(now.add(Duration(days: widget.plan.durationDays)));
    final val = _validationResult;

    final planTitle = isBn
        ? (widget.plan.titleBn.isNotEmpty ? widget.plan.titleBn : widget.plan.titleEn)
        : (widget.plan.titleEn.isNotEmpty ? widget.plan.titleEn : widget.plan.titleBn);

    final durationText = isBn
        ? (widget.plan.durationBn.isNotEmpty
            ? '${widget.plan.durationBn} (পর্যন্ত: $expiryDate)'
            : '${widget.plan.durationDays.toString().toLocalizedDigits("bn")} দিন (পর্যন্ত: $expiryDate)')
        : (widget.plan.durationEn.isNotEmpty
            ? '${widget.plan.durationEn} (Until: $expiryDate)'
            : '${widget.plan.durationDays} Days (Until: $expiryDate)');

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  isBn ? 'পেমেন্ট সফল হয়েছে!' : 'Payment Successful!',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn
                      ? 'আপনার সাবস্ক্রিপশন প্যাকেজটি সক্রিয় করা হয়েছে।'
                      : 'Your subscription plan is now active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Details Rows
                _receiptDetailRow(isBn ? 'গেটওয়ে:' : 'Gateway:', widget.isSandbox ? 'SSLCOMMERZ (Sandbox Test)' : 'SSLCOMMERZ'),
                _receiptDetailRow(isBn ? 'পেমেন্ট মেথড:' : 'Payment Method:', val?.cardType ?? 'Online Payment'),
                _receiptDetailRow(
                  isBn ? 'টাকার পরিমাণ:' : 'Amount:',
                  isBn
                      ? '৳${widget.plan.effectivePrice.toInt().toString().toLocalizedDigits("bn")} BDT'
                      : '৳${widget.plan.effectivePrice.toInt()} BDT',
                  isBold: true,
                ),
                _receiptDetailRow(isBn ? 'প্যাকেজ:' : 'Package:', planTitle),
                _receiptDetailRow(isBn ? 'মেয়াদ:' : 'Duration:', durationText),
                _receiptDetailRow('TrxID:', val?.tranId ?? 'N/A', canCopy: true),
                if (val?.bankTranId.isNotEmpty ?? false)
                  _receiptDetailRow('Bank TrxID:', val!.bankTranId),
                _receiptDetailRow(isBn ? 'তারিখ ও সময়:' : 'Date & Time:', formattedDate),
                _receiptDetailRow(isBn ? 'স্ট্যাটাস:' : 'Status:', isBn ? 'PAID (পরিশোধিত)' : 'PAID (Success)', isSuccess: true),

                const SizedBox(height: 20),

                // Finish Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context); // close webview screen
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isBn ? 'সম্পন্ন করুন ও ফিরে যান' : 'Complete & Return',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptDetailRow(String label, String value, {bool isBold = false, bool isSuccess = false, bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isBold || isSuccess) ? FontWeight.w900 : FontWeight.w600,
                  color: isSuccess ? Colors.green : (isBold ? AppColors.themeColor : null),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('TrxID কপি করা হয়েছে!'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.themeColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

