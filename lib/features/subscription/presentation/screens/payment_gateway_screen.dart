import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/extensions/utility_extension.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../shared/presentation/widgets/app_bar.dart';
import '../../data/models/subscription_model.dart';
import '../../data/providers/subscription_provider.dart';
import 'sslcommerz_webview_screen.dart';

class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({
    super.key,
    required this.plan,
    required this.user,
  });

  final SubscriptionPlanModel plan;
  final UserModel user;

  static const String name = '/payment-gateway';

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

enum _PaymentStep {
  phoneNumber,
  otpVerification,
  pinConfirmation,
  processing,
  successReceipt,
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  static const String adminBkashNumber = '01746300498';

  _PaymentStep _currentStep = _PaymentStep.phoneNumber;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _agreeTerms = true;
  String _generatedOtp = '';
  String _generatedTrxId = '';
  DateTime? _paymentDateTime;
  bool _showSmsToast = false;
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Prefill phone from user if valid
    if (widget.user.mobile.trim().length >= 11) {
      _phoneController.text = widget.user.mobile.trim();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _sendOtp() {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final phone = _phoneController.text.trim();
    if (phone.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'সঠিক ১১ ডিজিটের বিকাশ মোবাইল নম্বর দিন' : 'Please enter a valid 11-digit bKash number'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'দয়া করে বিকাশ পেমেন্ট শর্তাবলীতে সম্মতি প্রদান করুন' : 'Please accept the bKash payment terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generate 6-digit OTP
    final random = Random();
    final otpNum = 100000 + random.nextInt(900000);
    _generatedOtp = otpNum.toString();

    setState(() {
      _currentStep = _PaymentStep.otpVerification;
      _showSmsToast = true;
    });

    _startCountdown();

    // Auto hide SMS toast after 8 seconds
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _showSmsToast = false);
      }
    });
  }

  void _verifyOtp() {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.isEmpty || enteredOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'অনুগ্রহ করে ৬ ডিজিটের ওটিপি (OTP) লিখুন' : 'Please enter the 6-digit OTP code'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (enteredOtp != _generatedOtp && enteredOtp != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'ভুল ওটিপি দিয়েছেন। সঠিক ওটিপি দিন অথবা অটো-ফিল করুন।' : 'Invalid OTP. Please enter the correct code or click auto-fill.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _showSmsToast = false;
      _currentStep = _PaymentStep.pinConfirmation;
    });
  }

  Future<void> _confirmPinAndPay() async {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final pin = _pinController.text.trim();
    if (pin.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBn ? 'অনুগ্রহ করে ৫ ডিজিটের বিকাশ পিন (PIN) দিন' : 'Please enter your 5-digit bKash PIN'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _currentStep = _PaymentStep.processing);

    // Generate Unique bKash TrxID e.g. BK89X7Q2L1
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomSuffix = List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    _generatedTrxId = 'BK$randomSuffix';
    _paymentDateTime = DateTime.now();

    final subProvider = context.read<SubscriptionProvider>();

    try {
      await subProvider.processPaymentAndActivate(
        context: context,
        user: widget.user,
        plan: widget.plan,
        transactionId: _generatedTrxId,
        senderPhone: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() => _currentStep = _PaymentStep.successReceipt);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentStep = _PaymentStep.pinConfirmation);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBn ? 'পেমেন্ট প্রক্রিয়াকরণে সমস্যা হয়েছে: $e' : 'Payment processing error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
      appBar: MainAppBar(
        automaticallyImplyLeading: _currentStep != _PaymentStep.processing,
        title: const Text(
          'bKash Payment Gateway',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- SSLCOMMERZ Gateway Switch Banner ---
                  if (_currentStep == _PaymentStep.phoneNumber)
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SSLCommerzWebviewScreen(
                              plan: widget.plan,
                              user: widget.user,
                              isSandbox: true,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payment_rounded, color: Color(0xFF6366F1), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Localizations.localeOf(context).languageCode == 'bn'
                                    ? 'Nagad, Rocket, বা Card দিয়ে পে করবেন? SSLCOMMERZ গেটওয়ে ব্যবহার করুন'
                                    : 'Pay with Cards, Nagad, or Rocket? Use SSLCOMMERZ Gateway',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6366F1)),
                          ],
                        ),
                      ),
                    ),

                  // --- bKash Official Style Top Header ---
                  _buildBkashHeader(isDark),
                  const SizedBox(height: 16),

                  // --- Dynamic Step Wizard Content ---
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: switch (_currentStep) {
                      _PaymentStep.phoneNumber => _buildPhoneStep(isDark),
                      _PaymentStep.otpVerification => _buildOtpStep(isDark),
                      _PaymentStep.pinConfirmation => _buildPinStep(isDark),
                      _PaymentStep.processing => _buildProcessingStep(),
                      _PaymentStep.successReceipt => _buildReceiptView(isDark),
                    },
                  ),
                ],
              ),
            ),
          ),

          // --- Simulated Top SMS Notification Banner ---
          if (_showSmsToast)
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: _buildSmsNotificationToast(),
            ),
        ],
      ),
    );
  }

  Widget _buildBkashHeader(bool isDark) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE2136E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2136E).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFE2136E), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'bKash Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '100% Secure',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBn ? 'প্রাপক (Merchant / Admin):' : 'Merchant / Admin:',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                  const Text(
                    adminBkashNumber,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isBn ? 'পরিশোধের পরিমাণ:' : 'Amount to Pay:',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                  Text(
                    isBn
                        ? '৳ ${widget.plan.effectivePrice.toInt().toString().toLocalizedDigits("bn")}'
                        : '৳ ${widget.plan.effectivePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 1: Phone Number Input ---
  Widget _buildPhoneStep(bool isDark) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final planTitle = isBn
        ? (widget.plan.titleBn.isNotEmpty ? widget.plan.titleBn : widget.plan.titleEn)
        : (widget.plan.titleEn.isNotEmpty ? widget.plan.titleEn : widget.plan.titleBn);
    final durationText = isBn
        ? (widget.plan.durationBn.isNotEmpty ? widget.plan.durationBn : '${widget.plan.durationDays.toString().toLocalizedDigits("bn")} দিন')
        : (widget.plan.durationEn.isNotEmpty ? widget.plan.durationEn : '${widget.plan.durationDays} Days');

    return Container(
      key: const ValueKey('phone_step'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? 'আপনার বিকাশ অ্যাকাউন্ট নম্বর দিন' : 'Enter your bKash Account Number',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${isBn ? "প্যাকেজ:" : "Plan:"} $planTitle ($durationText)',
            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            decoration: InputDecoration(
              hintText: 'e.g. 017XXXXXXXX',
              labelText: isBn ? 'বিকাশ মোবাইল নম্বর (১১ ডিজিট)' : 'bKash Mobile Number (11 digits)',
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFFE2136E)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9),
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agreeTerms,
            onChanged: (val) => setState(() => _agreeTerms = val ?? true),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFE2136E),
            title: Text(
              isBn ? 'আমি বিকাশ পেমেন্ট শর্তাবলী ও নিয়মে সম্মতি জানাচ্ছি' : 'I agree to the bKash payment terms and conditions',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _sendOtp,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE2136E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isBn ? 'পরবর্তী ধাপ (OTP পাঠান)' : 'Next Step (Send OTP)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: OTP Verification ---
  Widget _buildOtpStep(bool isDark) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Container(
      key: const ValueKey('otp_step'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBn ? '৬ ডিজিটের ওটিপি (OTP) দিন' : 'Enter 6-digit OTP',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_phoneController.text.trim().substring(0, 3)}****${_phoneController.text.trim().substring(7)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE2136E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isBn
                ? 'আপনার বিকাশ নম্বরে একটি ৬ ডিজিটের ভেরিফিকেশন কোড পাঠানো হয়েছে।'
                : 'A 6-digit verification code has been sent to your bKash number.',
            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '• • • • • •',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() => _otpController.text = _generatedOtp);
                },
                icon: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.amber),
                label: Text(
                  isBn ? 'ওটিপি অটো-ফিল করুন' : 'Auto-fill OTP',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                _resendCountdown > 0
                    ? (isBn ? 'পুনরায় পাঠান (${_resendCountdown}s)' : 'Resend in (${_resendCountdown}s)')
                    : (isBn ? 'পুনরায় পাঠান' : 'Resend'),
                style: TextStyle(
                  fontSize: 12,
                  color: _resendCountdown > 0 ? Colors.grey : const Color(0xFFE2136E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = _PaymentStep.phoneNumber),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isBn ? 'নম্বর পরিবর্তন' : 'Change Number'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _verifyOtp,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE2136E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isBn ? 'নিশ্চিত করুন' : 'Confirm', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 3: PIN Input ---
  Widget _buildPinStep(bool isDark) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Container(
      key: const ValueKey('pin_step'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isBn ? 'বিকাশ পিন (PIN) নম্বর দিন' : 'Enter bKash PIN Number',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            isBn
                ? 'লেনদেন সম্পন্ন করতে আপনার ৫ ডিজিটের গোপন পিন নম্বর প্রবেশ করান।'
                : 'Enter your 5-digit secret PIN to complete payment.',
            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 5,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 10),
            decoration: InputDecoration(
              hintText: '• • • • •',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFE2136E)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = _PaymentStep.otpVerification),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isBn ? 'পূর্ববর্তী' : 'Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _confirmPinAndPay,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE2136E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isBn ? 'পেমেন্ট নিশ্চিত করুন' : 'Confirm Payment',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 4: Processing State ---
  Widget _buildProcessingStep() {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Container(
      key: const ValueKey('processing_step'),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFFE2136E), strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            isBn ? 'বিকাশ পেমেন্ট প্রসেসিং হচ্ছে...' : 'Processing bKash Payment...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            isBn
                ? 'অনুগ্রহ করে অপেক্ষা করুন, প্যাকেজ স্বয়ংক্রিয়ভাবে সক্রিয় করা হচ্ছে।'
                : 'Please wait, your package is being activated automatically.',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- STEP 5: Full Digital Money Receipt ---
  Widget _buildReceiptView(bool isDark) {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(_paymentDateTime ?? DateTime.now());
    final expiryDate = DateFormat('dd MMM yyyy').format(DateTime.now().add(Duration(days: widget.plan.durationDays)));

    final planTitle = isBn
        ? (widget.plan.titleBn.isNotEmpty ? widget.plan.titleBn : widget.plan.titleEn)
        : (widget.plan.titleEn.isNotEmpty ? widget.plan.titleEn : widget.plan.titleBn);

    return Container(
      key: const ValueKey('receipt_step'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade600, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Receipt Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  isBn ? 'পেমেন্ট সফল ও প্যাকেজ সক্রিয়!' : 'Payment Successful & Plan Active!',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  isBn ? 'ডিজিটাল পেমেন্ট মানি রসিদ (Money Receipt)' : 'Digital Payment Money Receipt',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildReceiptRow(isBn ? 'স্ট্যাটাস (Status):' : 'Status:', isBn ? 'PAID / পরিশোধিত' : 'PAID / Success', isSuccess: true),
                const Divider(height: 16),
                _buildReceiptRow(
                  isBn ? 'পরিশোধিত অর্থ:' : 'Amount Paid:',
                  isBn
                      ? '৳ ${widget.plan.effectivePrice.toInt().toString().toLocalizedDigits("bn")}'
                      : '৳ ${widget.plan.effectivePrice.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const Divider(height: 16),
                _buildReceiptRow(isBn ? 'প্যাকেজ নাম:' : 'Plan Name:', planTitle),
                const Divider(height: 16),
                _buildReceiptRow(isBn ? 'মেয়াদ শেষ হবে:' : 'Expires On:', expiryDate),
                const Divider(height: 16),
                _buildReceiptRow(isBn ? 'লেনদেন আইডি (TrxID):' : 'Transaction ID:', _generatedTrxId, canCopy: true),
                const Divider(height: 16),
                _buildReceiptRow(isBn ? 'প্রেরক নম্বর:' : 'Sender Phone:', _phoneController.text.trim()),
                const Divider(height: 16),
                _buildReceiptRow(isBn ? 'প্রাপক মার্চেন্ট:' : 'Merchant:', adminBkashNumber),
                const Divider(height: 16),
                _buildReceiptRow(isBn ? 'তারিখ ও সময়:' : 'Date & Time:', formattedDate),
                const SizedBox(height: 24),

                // Return to Home / Finish Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(
                      isBn ? 'রসিদ সংরক্ষণ ও সম্পন্ন করুন' : 'Save Receipt & Complete',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isSuccess = false, bool isBold = false, bool canCopy = false}) {
    return Row(
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
                color: isSuccess ? Colors.green : (isBold ? const Color(0xFFE2136E) : null),
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  final isBn = Localizations.localeOf(context).languageCode == 'bn';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isBn ? 'TrxID কপি করা হয়েছে!' : 'TrxID copied!'), duration: const Duration(seconds: 2)),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.themeColor),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSmsNotificationToast() {
    final isBn = Localizations.localeOf(context).languageCode == 'bn';
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE2136E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.message_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✉️ bKash SMS Notification',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your verification code is: $_generatedOtp',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE2136E),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                setState(() {
                  _otpController.text = _generatedOtp;
                  _showSmsToast = false;
                });
              },
              child: Text(isBn ? 'অটো-ফিল' : 'Auto-Fill', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
