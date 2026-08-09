// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get version => 'Version';

  @override
  String get signUpSubTitle => 'Create an account with details';

  @override
  String get signInSubTitle => 'Please enter your details to continue';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String get doNotHaveAnAccount => 'Don\'t have an account?';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';
}
