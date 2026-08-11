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

  @override
  String get accommodationPromptTitle =>
      'For which month and what type of accommodation are you looking?';

  @override
  String get accommodationPromptSubTitle =>
      'Select the month and type of accommodation.';

  @override
  String get month => 'Month';

  @override
  String get division => 'Division';

  @override
  String get district => 'District';

  @override
  String get upazila => 'Upazila';

  @override
  String get roomOrSeat => 'Room Or Seat';

  @override
  String get roomOrSeatNo => 'Number Of Room Or Seat';

  @override
  String get loading => 'Loading...';

  @override
  String get bedroom => 'BedRoom';

  @override
  String get room => 'Room';

  @override
  String get emptySeat => 'Empty Seat';

  @override
  String get unit => 'Unit';

  @override
  String get bedroomNo => 'Number Of BedRoom';

  @override
  String get roomNo => 'Number Of Room';

  @override
  String get emptySeatNo => 'Number Of Empty Seat';

  @override
  String get unitNo => 'Number Of Unit';

  @override
  String get houseType => 'House Type';

  @override
  String get locationPromptTitle =>
      'Which area do you want to look for a house in?';

  @override
  String get locationPromptSubTitle => 'Select those.';

  @override
  String get divisionNoLoadPrompt =>
      'Department information could not be loaded...';

  @override
  String get districtNoLoadPrompt =>
      'District information could not be loaded...';

  @override
  String get upazilaNoLoadPrompt =>
      'The upazila information could not be loaded...';
}
