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

  static String? validateName(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Enter your name';
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
      return 'Enter a valid name (only letters)';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your phone number';
    }
    if (RegExp(r'^01[3-9]\d{8}$').hasMatch(value.trim()) == false) {
      return 'Enter a valid Bangladeshi phone number';
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

  static String? validateNumber(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Enter a valid number';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter only numbers';
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