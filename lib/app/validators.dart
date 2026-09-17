import 'package:email_validator/email_validator.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (EmailValidator.validate(value ?? '') == false) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validateText(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Enter a valid value';
    }
    return null;
  }

  static String? validateName(String? value, {String? message, bool isBn = false}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? (isBn ? 'দয়া করে নাম লিখুন' : 'Enter your name');
    }
    final trimmed = value.trim();
    // Comprehensive Name Regex supporting:
    // - English letters (a-zA-Z)
    // - Bengali script (\u0980-\u09FF)
    // - Bengali Zero-Width Joiner (\u200D) & Zero-Width Non-Joiner (\u200C)
    // - Accented Latin characters (\u00C0-\u024F)
    // - Spaces, dots (.), hyphens/dashes (-/–), apostrophes ('/’/`), commas (,), parentheses (), and visarga (ঃ)
    final nameRegex = RegExp(
      r"^[a-zA-Z\u0980-\u09FF\u200C\u200D\u00C0-\u024F\s.'’`\-–,()ঃ]+$",
      unicode: true,
    );
    if (!nameRegex.hasMatch(trimmed)) {
      return isBn ? 'সঠিক নাম লিখুন (শুধু অক্ষর গ্রহণযোগ্য)' : 'Enter a valid name (only letters)';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value, {bool isBn = false}) {
    if (value == null || value.trim().isEmpty) {
      return isBn ? 'দয়া করে মোবাইল নম্বর লিখুন' : 'Enter your phone number';
    }
    if (RegExp(r'^01[3-9]\d{8}$').hasMatch(value.trim()) == false) {
      return isBn ? '১১ ডিজিটের সঠিক মোবাইল নম্বর লিখুন' : 'Enter a valid Bangladeshi phone number';
    }
    return null;
  }

  static String? validateWhatsAppNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (RegExp(r'^01[3-9]\d{8}$').hasMatch(value.trim()) == false) {
      return 'Enter a valid Bangladeshi WhatsApp number';
    }
    return null;
  }

  static String? validateNumber(String? value, {String? message, bool isBn = false}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? (isBn ? 'সঠিক সংখ্যা লিখুন' : 'Enter a valid number');
    }
    final trimmed = value.trim();
    if (trimmed.contains('-')) {
      return isBn
          ? 'নেগেটিভ মান গ্রহণযোগ্য নয়'
          : 'Negative numbers are not allowed';
    }
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var normalized = trimmed;
    for (int i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(bnDigits[i], enDigits[i]);
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return isBn ? 'শুধুমাত্র সঠিক সংখ্যা লিখুন' : 'Please enter only numbers';
    }
    if (parsed <= 0) {
      return isBn ? 'সংখ্যাটি অবশ্যই ০ এর বেশি হতে হবে' : 'Number must be greater than 0';
    }
    return null;
  }

  /// Validates that rent amount is strictly positive and rejects negative values (e.g. -5000, -1000).
  static String? validatePositiveAmount(String? value, {bool isBn = false}) {
    if (value == null || value.trim().isEmpty) {
      return isBn ? 'ভাড়ার পরিমাণ লিখুন' : 'Enter rent amount';
    }
    final trimmed = value.trim();
    if (trimmed.contains('-')) {
      return isBn
          ? 'নেগেটিভ মান গ্রহণযোগ্য নয়। ধনাত্মক সংখ্যা লিখুন (যেমন: ৫০০০)'
          : 'Negative amount is not allowed. Enter a positive number (e.g. 5000)';
    }
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var normalized = trimmed;
    for (int i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(bnDigits[i], enDigits[i]);
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return isBn ? 'শুধুমাত্র সঠিক সংখ্যা লিখুন' : 'Please enter only numbers';
    }
    if (parsed <= 0) {
      return isBn
          ? 'ভাড়ার পরিমাণ অবশ্যই ০ এর বেশি হতে হবে'
          : 'Amount must be greater than 0';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null) {
      return 'Enter your password';
    } else if (value.length < 7) {
      return 'Enter a password more than 6 letters';
    }
    return null;
  }
}