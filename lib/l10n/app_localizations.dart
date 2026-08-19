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
  /// **'Area'**
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

  /// No description provided for @flat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get flat;

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
  /// **'Area information could not be loaded...'**
  String get upazilaNoLoadPrompt;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Sub-area'**
  String get area;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @tenantType.
  ///
  /// In en, this message translates to:
  /// **'Tenant Type'**
  String get tenantType;

  /// No description provided for @bathroom.
  ///
  /// In en, this message translates to:
  /// **'Bathroom'**
  String get bathroom;

  /// No description provided for @balcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get balcony;

  /// No description provided for @floorNumber.
  ///
  /// In en, this message translates to:
  /// **'Floor Number'**
  String get floorNumber;

  /// No description provided for @lift.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get lift;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @lowestRent.
  ///
  /// In en, this message translates to:
  /// **'Lowest Rent'**
  String get lowestRent;

  /// No description provided for @highestRent.
  ///
  /// In en, this message translates to:
  /// **'Highest Rent'**
  String get highestRent;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @bachelorMale.
  ///
  /// In en, this message translates to:
  /// **'Bachelor Male'**
  String get bachelorMale;

  /// No description provided for @bachelorFemale.
  ///
  /// In en, this message translates to:
  /// **'Bachelor Female'**
  String get bachelorFemale;

  /// No description provided for @subLet.
  ///
  /// In en, this message translates to:
  /// **'Sub-let'**
  String get subLet;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @findHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Find Home'**
  String get findHomeButton;

  /// No description provided for @findHomePrompt.
  ///
  /// In en, this message translates to:
  /// **'Once all the above information is selected, click the Find Home button.'**
  String get findHomePrompt;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BashaBondhu App'**
  String get appName;

  /// No description provided for @basha.
  ///
  /// In en, this message translates to:
  /// **'Basha'**
  String get basha;

  /// No description provided for @bondhu.
  ///
  /// In en, this message translates to:
  /// **'Bondhu'**
  String get bondhu;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @postDemand.
  ///
  /// In en, this message translates to:
  /// **'Post Demand'**
  String get postDemand;

  /// No description provided for @postDemandPrompt.
  ///
  /// In en, this message translates to:
  /// **'Once all the above information is selected, click the Post Demand button.'**
  String get postDemandPrompt;

  /// No description provided for @bannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Landlord will find you!'**
  String get bannerTitle;

  /// No description provided for @bannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To get direct calls from landlords and instant notifications for preferred houses, state your demand with the following information.'**
  String get bannerSubtitle;

  /// No description provided for @bannerNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Notification permission must be given to receive notifications.'**
  String get bannerNote;

  /// No description provided for @noticeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Have you informed the landlord that you are vacating your current home?'**
  String get noticeQuestion;

  /// No description provided for @noticeHint.
  ///
  /// In en, this message translates to:
  /// **'Have you given notice that you are vacating the house?'**
  String get noticeHint;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Name'**
  String get enterName;

  /// No description provided for @enterMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Mobile Number'**
  String get enterMobile;

  /// No description provided for @enterWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Enter WhatsApp Number (if available)'**
  String get enterWhatsApp;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @budgetTenantPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your budget and tenant type?'**
  String get budgetTenantPromptTitle;

  /// No description provided for @budgetTenantPromptSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Select budget and tenant type.'**
  String get budgetTenantPromptSubTitle;

  /// No description provided for @amenitiesPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'What amenities and floor do you prefer?'**
  String get amenitiesPromptTitle;

  /// No description provided for @amenitiesPromptSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Select amenities and floor details.'**
  String get amenitiesPromptSubTitle;

  /// No description provided for @roomSeatPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Specify the number of rooms or seats.'**
  String get roomSeatPromptTitle;

  /// No description provided for @roomSeatPromptSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Select the required number.'**
  String get roomSeatPromptSubTitle;

  /// No description provided for @contactPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Contact Information'**
  String get contactPromptTitle;

  /// No description provided for @contactPromptSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Provide your name and number.'**
  String get contactPromptSubTitle;

  /// No description provided for @postFree.
  ///
  /// In en, this message translates to:
  /// **'Post Free'**
  String get postFree;

  /// No description provided for @postSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To rent out fast'**
  String get postSubtitle;

  /// No description provided for @postRentalTitle.
  ///
  /// In en, this message translates to:
  /// **'Post with all details to rent out'**
  String get postRentalTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @findHome.
  ///
  /// In en, this message translates to:
  /// **'Find a Home'**
  String get findHome;

  /// No description provided for @demand.
  ///
  /// In en, this message translates to:
  /// **'Demand'**
  String get demand;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get contactPerson;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @commonBathroom.
  ///
  /// In en, this message translates to:
  /// **'Common Bathroom'**
  String get commonBathroom;

  /// No description provided for @attachedBathroom.
  ///
  /// In en, this message translates to:
  /// **'Attached Bathroom'**
  String get attachedBathroom;

  /// No description provided for @kitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get kitchen;

  /// No description provided for @electricityBill.
  ///
  /// In en, this message translates to:
  /// **'Electricity Bill'**
  String get electricityBill;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @self.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get self;

  /// No description provided for @withRent.
  ///
  /// In en, this message translates to:
  /// **'With Rent'**
  String get withRent;

  /// No description provided for @cctv.
  ///
  /// In en, this message translates to:
  /// **'CCTV'**
  String get cctv;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get wifi;

  /// No description provided for @generator.
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get generator;

  /// No description provided for @securityGuard.
  ///
  /// In en, this message translates to:
  /// **'Security Guard'**
  String get securityGuard;

  /// No description provided for @marketDistance.
  ///
  /// In en, this message translates to:
  /// **'Market Distance (km)'**
  String get marketDistance;

  /// No description provided for @shortAddress.
  ///
  /// In en, this message translates to:
  /// **'Short Address'**
  String get shortAddress;

  /// No description provided for @detailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed Description'**
  String get detailedDescription;

  /// No description provided for @postNow.
  ///
  /// In en, this message translates to:
  /// **'Post Now'**
  String get postNow;

  /// No description provided for @photoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add up to 10 photos'**
  String get photoSubtitle;

  /// No description provided for @thumbnailLabel.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail'**
  String get thumbnailLabel;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Home Photos'**
  String get addPhotos;

  /// No description provided for @thumbnailHint.
  ///
  /// In en, this message translates to:
  /// **'This photo will be used as a thumbnail'**
  String get thumbnailHint;

  /// No description provided for @anotherPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Add more photos'**
  String get anotherPhotosHint;

  /// No description provided for @postedOn.
  ///
  /// In en, this message translates to:
  /// **'Posted on'**
  String get postedOn;

  /// No description provided for @postIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Post ID'**
  String get postIdLabel;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @facilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get facilitiesLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'Per Month'**
  String get perMonth;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfo;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;
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
