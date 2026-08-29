import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../auth/data/models/user_model.dart';
import '../models/subscription_model.dart';

class SSLCommerzInitResponse {
  final bool isSuccess;
  final String? gatewayPageURL;
  final String? sessionKey;
  final String? failedReason;
  final String tranId;

  const SSLCommerzInitResponse({
    required this.isSuccess,
    required this.tranId,
    this.gatewayPageURL,
    this.sessionKey,
    this.failedReason,
  });
}

class SSLCommerzValidationResponse {
  final bool isValid;
  final String status;
  final String tranId;
  final String valId;
  final double amount;
  final String cardType;
  final String bankTranId;
  final String cardNo;
  final String tranDate;

  const SSLCommerzValidationResponse({
    required this.isValid,
    required this.status,
    required this.tranId,
    required this.valId,
    required this.amount,
    required this.cardType,
    required this.bankTranId,
    required this.cardNo,
    required this.tranDate,
  });
}

class SSLCommerzService {
  // Default SSLCOMMERZ Sandbox Credentials
  static const String defaultSandboxStoreId = 'testbox';
  static const String defaultSandboxStorePassword = 'qwerty';

  // SSLCOMMERZ Sandbox URLs
  static const String sandboxInitUrl = 'https://sandbox.sslcommerz.com/gwprocess/v4/api.php';
  static const String sandboxValidateUrl = 'https://sandbox.sslcommerz.com/validator/api/validationserverAPI.php';

  // SSLCOMMERZ Live URLs
  static const String liveInitUrl = 'https://securepay.sslcommerz.com/gwprocess/v4/api.php';
  static const String liveValidateUrl = 'https://securepay.sslcommerz.com/validator/api/validationserverAPI.php';

  // Callback URLs to intercept in in-app WebView
  static const String successUrl = 'https://example.com/payment-success';
  static const String failUrl = 'https://example.com/payment-fail';
  static const String cancelUrl = 'https://example.com/payment-cancel';
  static const String ipnUrl = 'https://example.com/payment-ipn';

  final String storeId;
  final String storePassword;
  final bool isSandbox;

  SSLCommerzService({
    this.storeId = defaultSandboxStoreId,
    this.storePassword = defaultSandboxStorePassword,
    this.isSandbox = true,
  });

  /// Initialize SSLCOMMERZ Session and get GatewayPageURL
  Future<SSLCommerzInitResponse> initPaymentSession({
    required SubscriptionPlanModel plan,
    required UserModel user,
  }) async {
    final random = Random();
    final randomSuffix = List.generate(6, (_) => random.nextInt(10)).join();
    final tranId = 'BB_SUB_${DateTime.now().millisecondsSinceEpoch}_$randomSuffix';

    final effectivePrice = plan.effectivePrice.toStringAsFixed(2);
    final initUrl = isSandbox ? sandboxInitUrl : liveInitUrl;

    final customerName = user.fullName.trim().isNotEmpty ? user.fullName.trim() : 'BashaBondhu User';
    final customerEmail = user.email.trim().isNotEmpty ? user.email.trim() : 'user@bashabondhu.com';
    final customerPhone = user.mobile.trim().isNotEmpty ? user.mobile.trim() : '01700000000';

    final Map<String, String> body = {
      'store_id': storeId,
      'store_passwd': storePassword,
      'total_amount': effectivePrice,
      'currency': 'BDT',
      'tran_id': tranId,
      'success_url': successUrl,
      'fail_url': failUrl,
      'cancel_url': cancelUrl,
      'ipn_url': ipnUrl,
      'cus_name': customerName,
      'cus_email': customerEmail,
      'cus_phone': customerPhone,
      'cus_add1': 'Dhaka, Bangladesh',
      'cus_city': 'Dhaka',
      'cus_postcode': '1200',
      'cus_country': 'Bangladesh',
      'shipping_method': 'NO',
      'product_name': plan.titleEn.isNotEmpty ? plan.titleEn : 'BashaBondhu Subscription',
      'product_category': 'Rental Service Subscription',
      'product_profile': 'non-physical-goods',
    };

    try {
      if (kDebugMode) {
        print('💳 [SSLCOMMERZ] Initializing session with URL: $initUrl');
        print('💳 [SSLCOMMERZ] Payload: store_id=$storeId, amount=$effectivePrice, tran_id=$tranId');
      }

      final response = await http.post(
        Uri.parse(initUrl),
        body: body,
      );

      if (kDebugMode) {
        print('💳 [SSLCOMMERZ] Response (${response.statusCode}): ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final status = data['status']?.toString().toUpperCase();

        if (status == 'SUCCESS') {
          final gatewayPageUrl = data['GatewayPageURL']?.toString();
          final sessionKey = data['sessionkey']?.toString();
          return SSLCommerzInitResponse(
            isSuccess: true,
            tranId: tranId,
            gatewayPageURL: gatewayPageUrl,
            sessionKey: sessionKey,
          );
        } else {
          return SSLCommerzInitResponse(
            isSuccess: false,
            tranId: tranId,
            failedReason: data['failedreason']?.toString() ?? 'Failed to initialize payment gateway',
          );
        }
      } else {
        return SSLCommerzInitResponse(
          isSuccess: false,
          tranId: tranId,
          failedReason: 'Server error with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SSLCOMMERZ Error]: $e');
      }
      return SSLCommerzInitResponse(
        isSuccess: false,
        tranId: tranId,
        failedReason: e.toString(),
      );
    }
  }

  /// Validate SSLCOMMERZ Transaction with val_id
  Future<SSLCommerzValidationResponse> validateTransaction({
    required String valId,
  }) async {
    final validateUrl = isSandbox ? sandboxValidateUrl : liveValidateUrl;
    final uri = Uri.parse('$validateUrl?val_id=$valId&store_id=$storeId&store_passwd=$storePassword&format=json');

    try {
      if (kDebugMode) {
        print('🔍 [SSLCOMMERZ] Validating transaction with val_id: $valId');
      }

      final response = await http.get(uri);

      if (kDebugMode) {
        print('🔍 [SSLCOMMERZ] Validation response (${response.statusCode}): ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final status = data['status']?.toString().toUpperCase() ?? '';

        final isValid = status == 'VALID' || status == 'VALIDATED';
        final tranId = data['tran_id']?.toString() ?? '';
        final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
        final cardType = data['card_type']?.toString() ?? 'SSLCOMMERZ';
        final bankTranId = data['bank_tran_id']?.toString() ?? '';
        final cardNo = data['card_no']?.toString() ?? '';
        final tranDate = data['tran_date']?.toString() ?? DateTime.now().toIso8601String();

        return SSLCommerzValidationResponse(
          isValid: isValid,
          status: status,
          tranId: tranId,
          valId: valId,
          amount: amount,
          cardType: cardType,
          bankTranId: bankTranId,
          cardNo: cardNo,
          tranDate: tranDate,
        );
      } else {
        return SSLCommerzValidationResponse(
          isValid: false,
          status: 'HTTP_ERROR_${response.statusCode}',
          tranId: '',
          valId: valId,
          amount: 0,
          cardType: 'SSLCOMMERZ',
          bankTranId: '',
          cardNo: '',
          tranDate: '',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SSLCOMMERZ Validation Error]: $e');
      }
      return SSLCommerzValidationResponse(
        isValid: false,
        status: 'EXCEPTION: $e',
        tranId: '',
        valId: valId,
        amount: 0,
        cardType: 'SSLCOMMERZ',
        bankTranId: '',
        cardNo: '',
        tranDate: '',
      );
    }
  }
}

