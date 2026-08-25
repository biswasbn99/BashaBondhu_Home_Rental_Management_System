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
  /// **'MyPost'**
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
