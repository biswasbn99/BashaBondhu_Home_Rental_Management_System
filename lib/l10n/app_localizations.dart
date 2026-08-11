import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @signUpSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account with details'**
  String get signUpSubTitle;

  /// No description provided for @signInSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your details to continue'**
  String get signInSubTitle;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @doNotHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get doNotHaveAnAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @accommodationPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'For which month and what type of accommodation are you looking?'**
  String get accommodationPromptTitle;

  /// No description provided for @accommodationPromptSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Select the month and type of accommodation.'**
  String get accommodationPromptSubTitle;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @division.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get division;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @upazila.
  ///
  /// In en, this message translates to:
  /// **'Upazila'**
  String get upazila;

  /// No description provided for @roomOrSeat.
  ///
  /// In en, this message translates to:
  /// **'Room Or Seat'**
  String get roomOrSeat;

  /// No description provided for @roomOrSeatNo.
  ///
  /// In en, this message translates to:
  /// **'Number Of Room Or Seat'**
  String get roomOrSeatNo;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @bedroom.
  ///
  /// In en, this message translates to:
  /// **'BedRoom'**
  String get bedroom;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @emptySeat.
  ///
  /// In en, this message translates to:
  /// **'Empty Seat'**
  String get emptySeat;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @bedroomNo.
  ///
  /// In en, this message translates to:
  /// **'Number Of BedRoom'**
  String get bedroomNo;

  /// No description provided for @roomNo.
  ///
  /// In en, this message translates to:
  /// **'Number Of Room'**
  String get roomNo;

  /// No description provided for @emptySeatNo.
  ///
  /// In en, this message translates to:
  /// **'Number Of Empty Seat'**
  String get emptySeatNo;

  /// No description provided for @unitNo.
  ///
  /// In en, this message translates to:
  /// **'Number Of Unit'**
  String get unitNo;

  /// No description provided for @houseType.
  ///
  /// In en, this message translates to:
  /// **'House Type'**
  String get houseType;

  /// No description provided for @locationPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Which area do you want to look for a house in?'**
  String get locationPromptTitle;

  /// No description provided for @locationPromptSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Select those.'**
  String get locationPromptSubTitle;

  /// No description provided for @divisionNoLoadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Department information could not be loaded...'**
  String get divisionNoLoadPrompt;

  /// No description provided for @districtNoLoadPrompt.
  ///
  /// In en, this message translates to:
  /// **'District information could not be loaded...'**
  String get districtNoLoadPrompt;

  /// No description provided for @upazilaNoLoadPrompt.
  ///
  /// In en, this message translates to:
  /// **'The upazila information could not be loaded...'**
  String get upazilaNoLoadPrompt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
