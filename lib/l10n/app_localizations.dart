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
  /// **'Sort Properties'**
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

  /// No description provided for @mainThumbnailTitle.
  ///
  /// In en, this message translates to:
  /// **'Add House Photo'**
  String get mainThumbnailTitle;

  /// No description provided for @mainThumbnailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will be used as the main thumbnail'**
  String get mainThumbnailSubtitle;

  /// No description provided for @additionalPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Additional Photos'**
  String get additionalPhotosTitle;

  /// No description provided for @additionalPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add up to 9 photos for tenant reference'**
  String get additionalPhotosSubtitle;

  /// No description provided for @galleryOption.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryOption;

  /// No description provided for @cameraOption.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraOption;

  /// No description provided for @mainThumbnailBadge.
  ///
  /// In en, this message translates to:
  /// **'Main Photo'**
  String get mainThumbnailBadge;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deletePhoto;

  /// No description provided for @myPost.
  ///
  /// In en, this message translates to:
  /// **'My Post'**
  String get myPost;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @deletePostConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post?'**
  String get deletePostConfirmTitle;

  /// No description provided for @deletePostConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this rent post?'**
  String get deletePostConfirmSubtitle;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No rent posts published yet'**
  String get noPostsYet;

  /// No description provided for @createPostPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create New Rent Post'**
  String get createPostPrompt;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @postUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post updated successfully!'**
  String get postUpdatedSuccess;

  /// No description provided for @postDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post deleted successfully!'**
  String get postDeletedSuccess;

  /// No description provided for @searchResult.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResult;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get myProfile;

  /// No description provided for @activePosts.
  ///
  /// In en, this message translates to:
  /// **'Active Posts'**
  String get activePosts;

  /// No description provided for @savedHouses.
  ///
  /// In en, this message translates to:
  /// **'Saved Houses'**
  String get savedHouses;

  /// No description provided for @myDemands.
  ///
  /// In en, this message translates to:
  /// **'My Demands'**
  String get myDemands;

  /// No description provided for @viewTenantDemands.
  ///
  /// In en, this message translates to:
  /// **'View Tenant Demands'**
  String get viewTenantDemands;

  /// No description provided for @welcomeGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BashaBondhu'**
  String get welcomeGuestTitle;

  /// No description provided for @welcomeGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to find or rent houses quickly and easily.'**
  String get welcomeGuestSubtitle;

  /// No description provided for @guestFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Features of BashaBondhu'**
  String get guestFeaturesTitle;

  /// No description provided for @featureFindHome.
  ///
  /// In en, this message translates to:
  /// **'Easily find homes in your area & budget'**
  String get featureFindHome;

  /// No description provided for @featurePostHome.
  ///
  /// In en, this message translates to:
  /// **'House owners can post rental listings directly'**
  String get featurePostHome;

  /// No description provided for @featureDemandHome.
  ///
  /// In en, this message translates to:
  /// **'Tenants can submit customized rental demands'**
  String get featureDemandHome;

  /// No description provided for @featureWishlist.
  ///
  /// In en, this message translates to:
  /// **'Save and bookmark favorite listings'**
  String get featureWishlist;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get logoutConfirmSubtitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, Log Out'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City / Area'**
  String get city;

  /// No description provided for @userRole.
  ///
  /// In en, this message translates to:
  /// **'User Role'**
  String get userRole;

  /// No description provided for @hostGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Host Guidelines & Support'**
  String get hostGuidelines;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyAndSecurity;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @editDemand.
  ///
  /// In en, this message translates to:
  /// **'Edit Demand'**
  String get editDemand;

  /// No description provided for @deleteDemandConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Demand?'**
  String get deleteDemandConfirmTitle;

  /// No description provided for @deleteDemandConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this tenant demand?'**
  String get deleteDemandConfirmSubtitle;

  /// No description provided for @demandPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your rental demand has been posted successfully!'**
  String get demandPostedSuccess;

  /// No description provided for @demandUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Demand updated successfully!'**
  String get demandUpdatedSuccess;

  /// No description provided for @demandDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Demand deleted successfully!'**
  String get demandDeletedSuccess;

  /// No description provided for @noDemandsYet.
  ///
  /// In en, this message translates to:
  /// **'No demands posted yet'**
  String get noDemandsYet;

  /// No description provided for @postNewDemand.
  ///
  /// In en, this message translates to:
  /// **'Post New Demand'**
  String get postNewDemand;

  /// No description provided for @allTenantDemands.
  ///
  /// In en, this message translates to:
  /// **'Tenant Demands'**
  String get allTenantDemands;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @editPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Personal Info'**
  String get editPersonalInfo;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get incomplete;

  /// No description provided for @updatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update Photo'**
  String get updatePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middleName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @dateOfBirthNid.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (According to NID)'**
  String get dateOfBirthNid;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @nidFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'National ID (Front Side)'**
  String get nidFrontTitle;

  /// No description provided for @nidBackTitle.
  ///
  /// In en, this message translates to:
  /// **'National ID (Back Side)'**
  String get nidBackTitle;

  /// No description provided for @nidFrontHint.
  ///
  /// In en, this message translates to:
  /// **'Upload front side (JPG, PNG only)'**
  String get nidFrontHint;

  /// No description provided for @nidBackHint.
  ///
  /// In en, this message translates to:
  /// **'Upload back side (JPG, PNG only)'**
  String get nidBackHint;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @completeProfilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile and stay verified'**
  String get completeProfilePrompt;

  /// No description provided for @uploadNid.
  ///
  /// In en, this message translates to:
  /// **'Upload NID'**
  String get uploadNid;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @myDashboard.
  ///
  /// In en, this message translates to:
  /// **'My Dashboard'**
  String get myDashboard;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashboardOverview;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity & History'**
  String get activityHistory;

  /// No description provided for @marketDemandsRadar.
  ///
  /// In en, this message translates to:
  /// **'Tenant Demands Radar'**
  String get marketDemandsRadar;

  /// No description provided for @noPropertiesPosted.
  ///
  /// In en, this message translates to:
  /// **'No rental properties posted yet'**
  String get noPropertiesPosted;

  /// No description provided for @totalListings.
  ///
  /// In en, this message translates to:
  /// **'Total Listings'**
  String get totalListings;

  /// No description provided for @availableUnits.
  ///
  /// In en, this message translates to:
  /// **'Available Units'**
  String get availableUnits;

  /// No description provided for @quickShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Quick Shortcuts'**
  String get quickShortcuts;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account Created'**
  String get accountCreated;

  /// No description provided for @recentDemands.
  ///
  /// In en, this message translates to:
  /// **'Recent Demands'**
  String get recentDemands;

  /// No description provided for @savedProperties.
  ///
  /// In en, this message translates to:
  /// **'Saved Properties'**
  String get savedProperties;

  /// No description provided for @verifiedHost.
  ///
  /// In en, this message translates to:
  /// **'Verified Host'**
  String get verifiedHost;

  /// No description provided for @verifiedTenant.
  ///
  /// In en, this message translates to:
  /// **'Verified Tenant'**
  String get verifiedTenant;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// No description provided for @activeDemands.
  ///
  /// In en, this message translates to:
  /// **'Active Demands'**
  String get activeDemands;

  /// No description provided for @homeRentPost.
  ///
  /// In en, this message translates to:
  /// **'Post House Rent'**
  String get homeRentPost;

  /// No description provided for @boostListing.
  ///
  /// In en, this message translates to:
  /// **'Boost Listing'**
  String get boostListing;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @nidVerified.
  ///
  /// In en, this message translates to:
  /// **'NID Verified'**
  String get nidVerified;

  /// No description provided for @nidPending.
  ///
  /// In en, this message translates to:
  /// **'NID Pending'**
  String get nidPending;

  /// No description provided for @monthUnit.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get monthUnit;

  /// No description provided for @budgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetLabel;

  /// No description provided for @viewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @bookedLabel.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get bookedLabel;

  /// No description provided for @joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined on'**
  String get joinedOn;

  /// No description provided for @noDemandsFound.
  ///
  /// In en, this message translates to:
  /// **'No active tenant demands found at the moment.'**
  String get noDemandsFound;

  /// No description provided for @noSavedHousesPrompt.
  ///
  /// In en, this message translates to:
  /// **'No properties saved to favorites yet. Explore homes on the search tab.'**
  String get noSavedHousesPrompt;

  /// No description provided for @postListingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create rental listings to connect directly with tenants looking for homes.'**
  String get postListingPrompt;

  /// No description provided for @postDemandPromptDashboard.
  ///
  /// In en, this message translates to:
  /// **'Post your rental demand to let landlords contact you directly.'**
  String get postDemandPromptDashboard;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign In Required'**
  String get signInRequired;

  /// No description provided for @signInAsTenantPrompt.
  ///
  /// In en, this message translates to:
  /// **'To post a rental demand or save wishlist properties, please sign in or register as a Tenant.'**
  String get signInAsTenantPrompt;

  /// No description provided for @signInAsHouseOwnerPrompt.
  ///
  /// In en, this message translates to:
  /// **'To publish a home rental listing, please sign in or register as a House Owner.'**
  String get signInAsHouseOwnerPrompt;

  /// No description provided for @signInAsTenant.
  ///
  /// In en, this message translates to:
  /// **'Sign In as Tenant'**
  String get signInAsTenant;

  /// No description provided for @signUpAsTenant.
  ///
  /// In en, this message translates to:
  /// **'Sign Up as Tenant'**
  String get signUpAsTenant;

  /// No description provided for @signInAsHouseOwner.
  ///
  /// In en, this message translates to:
  /// **'Sign In as House Owner'**
  String get signInAsHouseOwner;

  /// No description provided for @signUpAsHouseOwner.
  ///
  /// In en, this message translates to:
  /// **'Sign Up as House Owner'**
  String get signUpAsHouseOwner;

  /// No description provided for @lockedRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Type (Locked)'**
  String get lockedRoleLabel;

  /// No description provided for @roleLockedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Role is fixed for this action'**
  String get roleLockedTooltip;

  /// No description provided for @wishlistGuestPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Access Wishlist'**
  String get wishlistGuestPrompt;

  /// No description provided for @wishlistGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in as a Tenant to save and manage your favorite rental properties.'**
  String get wishlistGuestSubtitle;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to get the full benefits of your account'**
  String get welcomeSubtitle;

  /// No description provided for @findHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Easily find your dream home'**
  String get findHomeSubtitle;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageBn.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBn;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @footerAppTitle.
  ///
  /// In en, this message translates to:
  /// **'BashaBondhu Home Rental'**
  String get footerAppTitle;

  /// No description provided for @footerVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get footerVersion;

  /// No description provided for @footerCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 BashaBondhu Inc. All rights reserved.'**
  String get footerCopyright;

  /// No description provided for @yesLogout.
  ///
  /// In en, this message translates to:
  /// **'Yes, Logout'**
  String get yesLogout;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get sortNewest;

  /// No description provided for @sortNewestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most recently published'**
  String get sortNewestSubtitle;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get sortOldest;

  /// No description provided for @sortOldestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earlier published'**
  String get sortOldestSubtitle;

  /// No description provided for @sortPriceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Rent: Low to High'**
  String get sortPriceLowToHigh;

  /// No description provided for @sortPriceLowToHighSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lowest rent first'**
  String get sortPriceLowToHighSubtitle;

  /// No description provided for @sortPriceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Rent: High to Low'**
  String get sortPriceHighToLow;

  /// No description provided for @sortPriceHighToLowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Highest rent first'**
  String get sortPriceHighToLowSubtitle;

  /// No description provided for @floorLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floorLabel;

  /// No description provided for @sortNewestShort.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewestShort;

  /// No description provided for @sortOldestShort.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get sortOldestShort;

  /// No description provided for @sortPriceLowShort.
  ///
  /// In en, this message translates to:
  /// **'Rent: Low ➔ High'**
  String get sortPriceLowShort;

  /// No description provided for @sortPriceHighShort.
  ///
  /// In en, this message translates to:
  /// **'Rent: High ➔ Low'**
  String get sortPriceHighShort;

  /// No description provided for @propertyMapLocation.
  ///
  /// In en, this message translates to:
  /// **'Property Location on Map (Optional)'**
  String get propertyMapLocation;

  /// No description provided for @mapLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pinpoint the exact location on map so tenants can get live GPS directions'**
  String get mapLocationSubtitle;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMap;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocation;

  /// No description provided for @clearLocation.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get clearLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm This Location'**
  String get confirmLocation;

  /// No description provided for @locationPinned.
  ///
  /// In en, this message translates to:
  /// **'Location Pinned on Map'**
  String get locationPinned;

  /// No description provided for @viewDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get viewDirections;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'away from you'**
  String get distanceAway;

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching GPS location...'**
  String get fetchingLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS location on your device'**
  String get locationServiceDisabled;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Exact map location not specified'**
  String get locationNotSet;

  /// No description provided for @searchAddressOrArea.
  ///
  /// In en, this message translates to:
  /// **'Search area, road or address...'**
  String get searchAddressOrArea;

  /// No description provided for @searchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Searching location...'**
  String get searchingLocation;

  /// No description provided for @noLocationFound.
  ///
  /// In en, this message translates to:
  /// **'No matching location found'**
  String get noLocationFound;

  /// No description provided for @dragMapToAdjust.
  ///
  /// In en, this message translates to:
  /// **'Drag map to place pin at exact house spot'**
  String get dragMapToAdjust;

  /// No description provided for @viewLargeMap.
  ///
  /// In en, this message translates to:
  /// **'View Full Map'**
  String get viewLargeMap;

  /// No description provided for @radiusSearchTab.
  ///
  /// In en, this message translates to:
  /// **'Nearby (Radius)'**
  String get radiusSearchTab;

  /// No description provided for @areaSearchTab.
  ///
  /// In en, this message translates to:
  /// **'By Area'**
  String get areaSearchTab;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadius;

  /// No description provided for @searchRadiusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find houses within a specific distance of your location'**
  String get searchRadiusSubtitle;

  /// No description provided for @centerPoint.
  ///
  /// In en, this message translates to:
  /// **'Search Center Location'**
  String get centerPoint;

  /// No description provided for @useMyGps.
  ///
  /// In en, this message translates to:
  /// **'Use My Current GPS'**
  String get useMyGps;

  /// No description provided for @pickCenterOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickCenterOnMap;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @noHousesFoundInRadius.
  ///
  /// In en, this message translates to:
  /// **'No rental homes found within this distance. Try increasing the radius.'**
  String get noHousesFoundInRadius;

  /// No description provided for @selectSearchCenterPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a center location (GPS or Map) for radius search.'**
  String get selectSearchCenterPrompt;

  /// No description provided for @nearestFirst.
  ///
  /// In en, this message translates to:
  /// **'Nearest First'**
  String get nearestFirst;

  /// No description provided for @noHousesFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Rental Homes Found'**
  String get noHousesFoundTitle;

  /// No description provided for @noHousesFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No houses match your selected location and radius. Try expanding your search distance or modifying filters.'**
  String get noHousesFoundSubtitle;

  /// No description provided for @changeFilters.
  ///
  /// In en, this message translates to:
  /// **'Change Filters'**
  String get changeFilters;

  /// No description provided for @viewAllHomes.
  ///
  /// In en, this message translates to:
  /// **'View All Homes'**
  String get viewAllHomes;

  /// No description provided for @mySubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Premium Packages'**
  String get mySubscription;

  /// No description provided for @subscriptionPackages.
  ///
  /// In en, this message translates to:
  /// **'Subscription Packages'**
  String get subscriptionPackages;

  /// No description provided for @subscriptionHistory.
  ///
  /// In en, this message translates to:
  /// **'Subscription History'**
  String get subscriptionHistory;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlan;

  /// No description provided for @bKashPayment.
  ///
  /// In en, this message translates to:
  /// **'bKash Payment Gateway'**
  String get bKashPayment;

  /// No description provided for @adminBkashAccount.
  ///
  /// In en, this message translates to:
  /// **'Admin bKash Account (Send Money)'**
  String get adminBkashAccount;

  /// No description provided for @trxIdLabel.
  ///
  /// In en, this message translates to:
  /// **'bKash Transaction ID (TrxID)'**
  String get trxIdLabel;

  /// No description provided for @senderPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Sender bKash Phone Number'**
  String get senderPhoneLabel;

  /// No description provided for @verifyAndActivate.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment & Activate Package'**
  String get verifyAndActivate;

  /// No description provided for @demoInstantActivate.
  ///
  /// In en, this message translates to:
  /// **'⚡ Instant Demo Activation (For Testing)'**
  String get demoInstantActivate;

  /// No description provided for @unlockPromptHeader.
  ///
  /// In en, this message translates to:
  /// **'If you want to unlock numbers and contact landlords directly, please activate any of the support packages below.'**
  String get unlockPromptHeader;

  /// No description provided for @ownerUnlockPromptHeader.
  ///
  /// In en, this message translates to:
  /// **'If you want to post unlimited house listings and unlock tenant contact numbers, please activate any of the packages below.'**
  String get ownerUnlockPromptHeader;

  /// No description provided for @tenantQuotaStatus.
  ///
  /// In en, this message translates to:
  /// **'Number unlocks remaining: {remainingUnlocks}/5 (Used: {usedUnlocks}/5) • Radius searches remaining: {remainingRadius}/3 (Used: {usedRadius}/3)'**
  String tenantQuotaStatus(
    String remainingUnlocks,
    String usedUnlocks,
    String remainingRadius,
    String usedRadius,
  );

  /// No description provided for @ownerQuotaStatus.
  ///
  /// In en, this message translates to:
  /// **'Ad posts remaining: {remainingPosts}/2 (Used: {usedPosts}/2) • Tenant number unlocks remaining: {remainingUnlocks}/2 (Used: {usedUnlocks}/2)'**
  String ownerQuotaStatus(
    String remainingPosts,
    String usedPosts,
    String remainingUnlocks,
    String usedUnlocks,
  );

  /// No description provided for @tenantPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'👑 Premium Membership Active'**
  String get tenantPremiumActive;

  /// No description provided for @tenantPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited number unlocks, radius searches & demand posts active'**
  String get tenantPremiumSubtitle;

  /// No description provided for @ownerPremiumActive.
  ///
  /// In en, this message translates to:
  /// **'👑 House Owner Premium Active'**
  String get ownerPremiumActive;

  /// No description provided for @ownerPremiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited house listing posts & all tenant number unlocks active'**
  String get ownerPremiumSubtitle;

  /// No description provided for @freeAccountLimited.
  ///
  /// In en, this message translates to:
  /// **'Free Account (Active Limits)'**
  String get freeAccountLimited;

  /// No description provided for @freeOwnerAccountLimited.
  ///
  /// In en, this message translates to:
  /// **'Free House Owner Account (Limited)'**
  String get freeOwnerAccountLimited;

  /// No description provided for @activateSupportPackage.
  ///
  /// In en, this message translates to:
  /// **'👑 Activate Support Package'**
  String get activateSupportPackage;

  /// No description provided for @activateOwnerPackage.
  ///
  /// In en, this message translates to:
  /// **'👑 Activate Owner Package'**
  String get activateOwnerPackage;

  /// No description provided for @subscriptionDetailsAndPackages.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details & Packages'**
  String get subscriptionDetailsAndPackages;

  /// No description provided for @mapLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Map & GPS Location Locked'**
  String get mapLockedTitle;

  /// No description provided for @mapLockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock property details to view exact location and Google Maps navigation directions.'**
  String get mapLockedSubtitle;

  /// No description provided for @unlockMap.
  ///
  /// In en, this message translates to:
  /// **'Unlock Map'**
  String get unlockMap;

  /// No description provided for @unlockInfoAndNumberWithQuota.
  ///
  /// In en, this message translates to:
  /// **'Unlock Info & Contacts ({remaining}/5 Free Remaining)'**
  String unlockInfoAndNumberWithQuota(String remaining);

  /// No description provided for @unlockInfoAndNumberWithQuotaOwner.
  ///
  /// In en, this message translates to:
  /// **'Unlock Tenant Contact ({remaining}/2 Free Remaining)'**
  String unlockInfoAndNumberWithQuotaOwner(String remaining);

  /// No description provided for @loginToUnlockInfo.
  ///
  /// In en, this message translates to:
  /// **'Login to Unlock Info & Contacts'**
  String get loginToUnlockInfo;

  /// No description provided for @unlockWithSupportPackage.
  ///
  /// In en, this message translates to:
  /// **'👑 Get Support Package to Unlock'**
  String get unlockWithSupportPackage;

  /// No description provided for @unlockPropertyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Property Details & Contact'**
  String get unlockPropertyDialogTitle;

  /// No description provided for @unlockPropertyDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to use 1 free credit to unlock the exact sub-area, landlord\'s contact numbers, and all gallery photos?\n\n(Your free unlocks remaining: {remaining}/5)'**
  String unlockPropertyDialogContent(String remaining);

  /// No description provided for @unlockDemandDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Tenant Contact Number'**
  String get unlockDemandDialogTitle;

  /// No description provided for @unlockDemandDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to use 1 free credit to unlock this tenant\'s phone and WhatsApp number?\n\n(Your free unlocks remaining: {remaining}/2)'**
  String unlockDemandDialogContent(String remaining);

  /// No description provided for @unlockSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Property details, sub-area, and landlord contact unlocked successfully!'**
  String get unlockSuccessMessage;

  /// No description provided for @unlockDemandSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Tenant contact unlocked successfully!'**
  String get unlockDemandSuccessMessage;

  /// No description provided for @yesUnlock.
  ///
  /// In en, this message translates to:
  /// **'Yes, Unlock'**
  String get yesUnlock;

  /// No description provided for @photosLockedBadge.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total} (Unlock to view all photos)'**
  String photosLockedBadge(String current, String total);

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @loginToUnlockTenantContact.
  ///
  /// In en, this message translates to:
  /// **'Login to View Tenant Contact'**
  String get loginToUnlockTenantContact;

  /// No description provided for @unlockWithHouseOwnerPackage.
  ///
  /// In en, this message translates to:
  /// **'👑 Get House Owner Package to Unlock'**
  String get unlockWithHouseOwnerPackage;

  /// No description provided for @radiusLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Radius Searches Limit Reached'**
  String get radiusLimitReachedTitle;

  /// No description provided for @radiusLimitReachedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have used all 3 free radius searches. Activate any support package to enjoy unlimited radius searches.'**
  String get radiusLimitReachedSubtitle;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @viewPackages.
  ///
  /// In en, this message translates to:
  /// **'View Packages'**
  String get viewPackages;

  /// No description provided for @tenantQuotaOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Account Limit Overview'**
  String get tenantQuotaOverviewTitle;

  /// No description provided for @ownerQuotaOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Free House Owner Limit Overview'**
  String get ownerQuotaOverviewTitle;

  /// No description provided for @propertyUnlocksQuotaLabel.
  ///
  /// In en, this message translates to:
  /// **'Property & Landlord Contact Unlocks:'**
  String get propertyUnlocksQuotaLabel;

  /// No description provided for @radiusSearchQuotaLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius (Nearby) Search:'**
  String get radiusSearchQuotaLabel;

  /// No description provided for @demandPostQuotaLabel.
  ///
  /// In en, this message translates to:
  /// **'Rental Demand Posts:'**
  String get demandPostQuotaLabel;

  /// No description provided for @ownerDemandUnlocksQuotaLabel.
  ///
  /// In en, this message translates to:
  /// **'Tenant Contact Unlocks:'**
  String get ownerDemandUnlocksQuotaLabel;

  /// No description provided for @ownerPostQuotaLabel.
  ///
  /// In en, this message translates to:
  /// **'Rental House Posts:'**
  String get ownerPostQuotaLabel;

  /// No description provided for @quotaRemainingWithUsed.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{total} Left (Used: {used}/{total})'**
  String quotaRemainingWithUsed(String remaining, String total, String used);

  /// No description provided for @maxTwoFree.
  ///
  /// In en, this message translates to:
  /// **'Max 2 Free'**
  String get maxTwoFree;
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
