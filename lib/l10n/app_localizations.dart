import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tl.dart';

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
    Locale('en'),
    Locale('tl'),
  ];

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pagsanjan Agriculture'**
  String get appSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get navWeather;

  /// No description provided for @navFarm.
  ///
  /// In en, this message translates to:
  /// **'My Farm'**
  String get navFarm;

  /// No description provided for @navPlanting.
  ///
  /// In en, this message translates to:
  /// **'Planting'**
  String get navPlanting;

  /// No description provided for @navPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get navPrices;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Getting your farm weather...'**
  String get loadingWeather;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @hectares.
  ///
  /// In en, this message translates to:
  /// **'hectares'**
  String get hectares;

  /// No description provided for @sqmShort.
  ///
  /// In en, this message translates to:
  /// **'sqm'**
  String get sqmShort;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @portalTitle.
  ///
  /// In en, this message translates to:
  /// **'Pagsanjan Farmer Portal'**
  String get portalTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Portal'**
  String get signInTitle;

  /// No description provided for @signInHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and security PIN to continue.'**
  String get signInHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'4-Digit PIN Passcode'**
  String get pinLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @todayWeather.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weather'**
  String get todayWeather;

  /// No description provided for @heatIndex.
  ///
  /// In en, this message translates to:
  /// **'Heat index'**
  String get heatIndex;

  /// No description provided for @heatIndexSub.
  ///
  /// In en, this message translates to:
  /// **'How hot it feels when humidity is included'**
  String get heatIndexSub;

  /// No description provided for @heatNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get heatNormal;

  /// No description provided for @heatCaution.
  ///
  /// In en, this message translates to:
  /// **'Caution'**
  String get heatCaution;

  /// No description provided for @heatExtremeCaution.
  ///
  /// In en, this message translates to:
  /// **'Extreme caution'**
  String get heatExtremeCaution;

  /// No description provided for @heatDanger.
  ///
  /// In en, this message translates to:
  /// **'Danger'**
  String get heatDanger;

  /// No description provided for @heatExtremeDanger.
  ///
  /// In en, this message translates to:
  /// **'Extreme danger'**
  String get heatExtremeDanger;

  /// No description provided for @heatAdviceNormal.
  ///
  /// In en, this message translates to:
  /// **'Comfortable for field work. Drink water regularly.'**
  String get heatAdviceNormal;

  /// No description provided for @heatAdviceCaution.
  ///
  /// In en, this message translates to:
  /// **'Fatigue is possible with long exposure. Rest in the shade and drink water.'**
  String get heatAdviceCaution;

  /// No description provided for @heatAdviceExtremeCaution.
  ///
  /// In en, this message translates to:
  /// **'Heat cramps and exhaustion are possible. Work early morning or late afternoon and rest often.'**
  String get heatAdviceExtremeCaution;

  /// No description provided for @heatAdviceDanger.
  ///
  /// In en, this message translates to:
  /// **'Heat exhaustion is likely and heat stroke is possible. Avoid field work at midday.'**
  String get heatAdviceDanger;

  /// No description provided for @heatAdviceExtremeDanger.
  ///
  /// In en, this message translates to:
  /// **'Heat stroke is highly likely. Stay indoors or in the shade and avoid field work.'**
  String get heatAdviceExtremeDanger;

  /// No description provided for @heatScaleSource.
  ///
  /// In en, this message translates to:
  /// **'Estimated from temperature and humidity. Levels follow the PAGASA heat index scale.'**
  String get heatScaleSource;

  /// No description provided for @forecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecastTitle;

  /// No description provided for @hourlyTab.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourlyTab;

  /// No description provided for @weeklyTab.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get weeklyTab;

  /// No description provided for @heatTimeline.
  ///
  /// In en, this message translates to:
  /// **'Heat index by hour today'**
  String get heatTimeline;

  /// No description provided for @heatHottest.
  ///
  /// In en, this message translates to:
  /// **'Hottest time'**
  String get heatHottest;

  /// No description provided for @farmCropsTitle.
  ///
  /// In en, this message translates to:
  /// **'My crops'**
  String get farmCropsTitle;

  /// No description provided for @farmCropsSub.
  ///
  /// In en, this message translates to:
  /// **'Tap a crop to see its best planting months.'**
  String get farmCropsSub;

  /// No description provided for @farmTotalHarvest.
  ///
  /// In en, this message translates to:
  /// **'Total harvest'**
  String get farmTotalHarvest;

  /// No description provided for @farmShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your land'**
  String farmShare(String percent);

  /// No description provided for @farmThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get farmThisMonth;

  /// No description provided for @farmDaysGrown.
  ///
  /// In en, this message translates to:
  /// **'Day {days} of about {total}'**
  String farmDaysGrown(int days, int total);

  /// No description provided for @farmExpectedHarvest.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest: {range}'**
  String farmExpectedHarvest(String range);

  /// No description provided for @farmReadySoon.
  ///
  /// In en, this message translates to:
  /// **'Almost ready to harvest'**
  String get farmReadySoon;

  /// No description provided for @farmLastHarvest.
  ///
  /// In en, this message translates to:
  /// **'Last harvest'**
  String get farmLastHarvest;

  /// No description provided for @farmYieldPerHa.
  ///
  /// In en, this message translates to:
  /// **'{value} kg per hectare'**
  String farmYieldPerHa(String value);

  /// No description provided for @farmEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'Dates are estimates. The actual harvest depends on the weather and the variety.'**
  String get farmEstimateNote;

  /// No description provided for @priceMyCrops.
  ///
  /// In en, this message translates to:
  /// **'My crops'**
  String get priceMyCrops;

  /// No description provided for @priceAllCrops.
  ///
  /// In en, this message translates to:
  /// **'All crops'**
  String get priceAllCrops;

  /// No description provided for @priceRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get priceRising;

  /// No description provided for @priceFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling'**
  String get priceFalling;

  /// No description provided for @priceGraphTitle.
  ///
  /// In en, this message translates to:
  /// **'Expected price, next 7 days'**
  String get priceGraphTitle;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'7-day range'**
  String get priceRange;

  /// No description provided for @priceHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest expected'**
  String get priceHighest;

  /// No description provided for @priceWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why is the price changing?'**
  String get priceWhyTitle;

  /// No description provided for @priceFactorRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get priceFactorRain;

  /// No description provided for @priceFactorHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get priceFactorHeat;

  /// No description provided for @priceFactorSeason.
  ///
  /// In en, this message translates to:
  /// **'Harvest season'**
  String get priceFactorSeason;

  /// No description provided for @priceRainHeavy.
  ///
  /// In en, this message translates to:
  /// **'About {mm} mm of rain in the next 7 days. Flooded fields can cut supply, so prices tend to rise.'**
  String priceRainHeavy(String mm);

  /// No description provided for @priceRainDry.
  ///
  /// In en, this message translates to:
  /// **'Only about {mm} mm of rain in the next 7 days. A dry spell can reduce harvests, so prices may rise slightly.'**
  String priceRainDry(String mm);

  /// No description provided for @priceRainNormal.
  ///
  /// In en, this message translates to:
  /// **'About {mm} mm of rain in the next 7 days. Normal weather, so supply stays steady.'**
  String priceRainNormal(String mm);

  /// No description provided for @priceHeatHigh.
  ///
  /// In en, this message translates to:
  /// **'Very hot days ahead (heat index up to {hi}°C). Heat stress can lower harvests, so prices may rise.'**
  String priceHeatHigh(String hi);

  /// No description provided for @priceHeatNormal.
  ///
  /// In en, this message translates to:
  /// **'No extreme heat expected. No effect on the price.'**
  String get priceHeatNormal;

  /// No description provided for @priceSeasonPeak.
  ///
  /// In en, this message translates to:
  /// **'Based on the planting calendar, this crop is in its peak harvest time. More supply usually means lower prices.'**
  String get priceSeasonPeak;

  /// No description provided for @priceSeasonOff.
  ///
  /// In en, this message translates to:
  /// **'Based on the planting calendar, this crop is not in its peak harvest time. Less supply usually keeps prices steady or higher.'**
  String get priceSeasonOff;

  /// No description provided for @priceLastHarvestValue.
  ///
  /// In en, this message translates to:
  /// **'Your last harvest ({kg} kg) would be worth about ₱{value} at the expected price.'**
  String priceLastHarvestValue(String kg, String value);

  /// No description provided for @priceDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These are estimates from a simple model that uses the 7-day weather forecast and the planting calendar. The current prices are sample values, not official market prices. Please check with your Municipal Agriculture Office or the market before selling.'**
  String get priceDisclaimer;

  /// No description provided for @farmOverview.
  ///
  /// In en, this message translates to:
  /// **'Farm overview'**
  String get farmOverview;

  /// No description provided for @overviewCrops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get overviewCrops;

  /// No description provided for @overviewCropsSub.
  ///
  /// In en, this message translates to:
  /// **'Active crops'**
  String get overviewCropsSub;

  /// No description provided for @overviewPlantNow.
  ///
  /// In en, this message translates to:
  /// **'Good to plant'**
  String get overviewPlantNow;

  /// No description provided for @overviewPlantNowSub.
  ///
  /// In en, this message translates to:
  /// **'crops this month'**
  String get overviewPlantNowSub;

  /// No description provided for @next12Hours.
  ///
  /// In en, this message translates to:
  /// **'Next 12 hours'**
  String get next12Hours;

  /// No description provided for @adviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm advice for today'**
  String get adviceTitle;

  /// No description provided for @adviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on the live weather'**
  String get adviceSubtitle;

  /// No description provided for @forecast7Days.
  ///
  /// In en, this message translates to:
  /// **'7-day forecast'**
  String get forecast7Days;

  /// No description provided for @plantInMonth.
  ///
  /// In en, this message translates to:
  /// **'Good to plant in {month}'**
  String plantInMonth(String month);

  /// No description provided for @noBestCrop.
  ///
  /// In en, this message translates to:
  /// **'No crop is at its best planting time this month.'**
  String get noBestCrop;

  /// No description provided for @statusLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get statusLive;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get statusOffline;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get feelsLike;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @rainChance.
  ///
  /// In en, this message translates to:
  /// **'Rain chance'**
  String get rainChance;

  /// No description provided for @todayRange.
  ///
  /// In en, this message translates to:
  /// **'Today: {min}° - {max}°   •   Rain {rain} mm'**
  String todayRange(String min, String max, String rain);

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}  (auto-refresh every 10 min)'**
  String updatedAt(DateTime time);

  /// No description provided for @homeCropsTitle.
  ///
  /// In en, this message translates to:
  /// **'Crops of Pagsanjan'**
  String get homeCropsTitle;

  /// No description provided for @homeCropsSub.
  ///
  /// In en, this message translates to:
  /// **'Tap a crop to see the best months to plant it.'**
  String get homeCropsSub;

  /// No description provided for @homeCropsNote.
  ///
  /// In en, this message translates to:
  /// **'Common crops grown in Laguna. Planting months are a guide - confirm with your Municipal Agriculture Office.'**
  String get homeCropsNote;

  /// No description provided for @dssTitle.
  ///
  /// In en, this message translates to:
  /// **'Best months to plant'**
  String get dssTitle;

  /// No description provided for @dssSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pagsanjan, Laguna - planting calendar guide'**
  String get dssSubtitle;

  /// No description provided for @dssRainNote.
  ///
  /// In en, this message translates to:
  /// **'A lot of rain is expected this week. Check your canals and drainage before planting.'**
  String get dssRainNote;

  /// No description provided for @dssBestMonths.
  ///
  /// In en, this message translates to:
  /// **'Best months'**
  String get dssBestMonths;

  /// No description provided for @dssPossibleMonths.
  ///
  /// In en, this message translates to:
  /// **'Possible months'**
  String get dssPossibleMonths;

  /// No description provided for @dssTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get dssTip;

  /// No description provided for @dssDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This graph is a guide based on the planting calendar for Pagsanjan, Laguna. It is not a forecast of yield or price. Please confirm with your Municipal Agriculture Office.'**
  String get dssDisclaimer;

  /// No description provided for @totalLandSize.
  ///
  /// In en, this message translates to:
  /// **'Total land size'**
  String get totalLandSize;

  /// No description provided for @plantedWhere.
  ///
  /// In en, this message translates to:
  /// **'What is planted where'**
  String get plantedWhere;

  /// No description provided for @cropHistory.
  ///
  /// In en, this message translates to:
  /// **'Crop record history'**
  String get cropHistory;

  /// No description provided for @plantedOn.
  ///
  /// In en, this message translates to:
  /// **'Planted {date}'**
  String plantedOn(DateTime date);

  /// No description provided for @harvestedOn.
  ///
  /// In en, this message translates to:
  /// **'Harvested {date}'**
  String harvestedOn(DateTime date);

  /// No description provided for @stillGrowing.
  ///
  /// In en, this message translates to:
  /// **'Still growing'**
  String get stillGrowing;

  /// No description provided for @whenToPlant.
  ///
  /// In en, this message translates to:
  /// **'When should I plant?'**
  String get whenToPlant;

  /// No description provided for @tapMonth.
  ///
  /// In en, this message translates to:
  /// **'Tap a month to see which crops are best to plant.'**
  String get tapMonth;

  /// No description provided for @legendBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get legendBest;

  /// No description provided for @legendPossible.
  ///
  /// In en, this message translates to:
  /// **'Possible'**
  String get legendPossible;

  /// No description provided for @legendAvoid.
  ///
  /// In en, this message translates to:
  /// **'Not advised'**
  String get legendAvoid;

  /// No description provided for @myCrop.
  ///
  /// In en, this message translates to:
  /// **'My crop'**
  String get myCrop;

  /// No description provided for @statusBest.
  ///
  /// In en, this message translates to:
  /// **'Best time to plant'**
  String get statusBest;

  /// No description provided for @statusPossible.
  ///
  /// In en, this message translates to:
  /// **'Can plant, some risk'**
  String get statusPossible;

  /// No description provided for @statusAvoid.
  ///
  /// In en, this message translates to:
  /// **'Not advised now'**
  String get statusAvoid;

  /// No description provided for @bestMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Best: {month}'**
  String bestMonthLabel(String month);

  /// No description provided for @harvestIn.
  ///
  /// In en, this message translates to:
  /// **'Ready to harvest in {time}'**
  String harvestIn(String time);

  /// No description provided for @plantingDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a general guide for Laguna. Weather can change from year to year - please confirm with your Municipal Agriculture Office.'**
  String get plantingDisclaimer;

  /// No description provided for @cropPrices.
  ///
  /// In en, this message translates to:
  /// **'Crop prices'**
  String get cropPrices;

  /// No description provided for @pricesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expected price based on the coming weather. In PHP per kg.'**
  String get pricesSubtitle;

  /// No description provided for @noPriceData.
  ///
  /// In en, this message translates to:
  /// **'No price data for your crops yet.'**
  String get noPriceData;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @appSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'View your account, get help, and read the privacy policy.'**
  String get appSettingsSub;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @farmerName.
  ///
  /// In en, this message translates to:
  /// **'Farmer Name'**
  String get farmerName;

  /// No description provided for @barangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get barangay;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @landSize.
  ///
  /// In en, this message translates to:
  /// **'Land Size'**
  String get landSize;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// No description provided for @displaySettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Make the text easier to read'**
  String get displaySettingsSub;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSizeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textSizeNormal;

  /// No description provided for @textSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textSizeLarge;

  /// No description provided for @textSizeXLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textSizeXLarge;

  /// No description provided for @textSizeSample.
  ///
  /// In en, this message translates to:
  /// **'Sample: Good morning, farmer!'**
  String get textSizeSample;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpSupportSub.
  ///
  /// In en, this message translates to:
  /// **'Need help with the app or your farm?'**
  String get helpSupportSub;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use PAGRI'**
  String get howToUse;

  /// No description provided for @howTo1.
  ///
  /// In en, this message translates to:
  /// **'DSS (the green button in the middle): first set your total land size, then add your crops with land area, planting date, last yield and cost. You will see when to plant, an estimate of harvest and income, and price advice.'**
  String get howTo1;

  /// No description provided for @howTo2.
  ///
  /// In en, this message translates to:
  /// **'Weather: see today\'s weather, the 7-day forecast, the heat index and advice for your crops.'**
  String get howTo2;

  /// No description provided for @howTo3.
  ///
  /// In en, this message translates to:
  /// **'My Farm: see your crops and how your land is shared (hectares or square meters). Tap a crop to open it in DSS. Your harvest records are here too.'**
  String get howTo3;

  /// No description provided for @howTo4.
  ///
  /// In en, this message translates to:
  /// **'Prices: only the crops you added in DSS appear here, with expected prices and when it is a good time to sell.'**
  String get howTo4;

  /// No description provided for @howTo5.
  ///
  /// In en, this message translates to:
  /// **'After harvest, tap \"Record harvest\" in DSS so estimates get closer to your own farm. Tap the bell at the top to read notifications. Numbers are estimates only, not official.'**
  String get howTo5;

  /// No description provided for @contactOffice.
  ///
  /// In en, this message translates to:
  /// **'Municipal Agriculture Office'**
  String get contactOffice;

  /// No description provided for @contactOfficeSub.
  ///
  /// In en, this message translates to:
  /// **'Visit the office in Pagsanjan, Laguna for account changes, subsidies and farming help.'**
  String get contactOfficeSub;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'PAGRI version 1.0.0'**
  String get appVersion;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacySystemName.
  ///
  /// In en, this message translates to:
  /// **'Pagsanjan Agriculture System'**
  String get privacySystemName;

  /// No description provided for @privacySummary.
  ///
  /// In en, this message translates to:
  /// **'PAGRI (Pagsanjan Agricultural Decision Support System) protects the data of every registered farmer. Information such as barangay, land size, and crops are used solely for weather forecasting, market pricing, and support from the Municipal Agriculture Office.'**
  String get privacySummary;

  /// No description provided for @readFullPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read Full Privacy Policy'**
  String get readFullPolicy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your PAGRI portal?'**
  String get logoutConfirm;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutButton;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Decision Support System (PAGRI - Pagsanjan, Laguna)'**
  String get privacySubtitle;

  /// No description provided for @policy1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get policy1Title;

  /// No description provided for @policy1Body.
  ///
  /// In en, this message translates to:
  /// **'PAGRI collects basic farmer information including name, barangay, land size, and crop types to generate localized weather advisories and price forecasts.'**
  String get policy1Body;

  /// No description provided for @policy2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How Information is Used'**
  String get policy2Title;

  /// No description provided for @policy2Body.
  ///
  /// In en, this message translates to:
  /// **'Your data is strictly utilized to process Open-Meteo weather forecasts, model estimated market prices, and assist the Pagsanjan Municipal Agriculture Office in local agricultural planning.'**
  String get policy2Body;

  /// No description provided for @policy3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Data Protection & Security'**
  String get policy3Title;

  /// No description provided for @policy3Body.
  ///
  /// In en, this message translates to:
  /// **'All farmer records are protected under secure protocols. Personal details are never sold or shared with third parties for commercial gain.'**
  String get policy3Body;

  /// No description provided for @policy4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Farmer Rights'**
  String get policy4Title;

  /// No description provided for @policy4Body.
  ///
  /// In en, this message translates to:
  /// **'Farmers maintain full rights to review, update, or request deletion of their profile records anytime through the app or by contacting the Municipal Agriculture Office.'**
  String get policy4Body;

  /// No description provided for @understand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get understand;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications right now.'**
  String get noNotifications;

  /// No description provided for @cropRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get cropRice;

  /// No description provided for @cropEggplant.
  ///
  /// In en, this message translates to:
  /// **'Eggplant'**
  String get cropEggplant;

  /// No description provided for @cropTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get cropTomato;

  /// No description provided for @cropStringBeans.
  ///
  /// In en, this message translates to:
  /// **'String beans'**
  String get cropStringBeans;

  /// No description provided for @cropBanana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get cropBanana;

  /// No description provided for @cropCoconut.
  ///
  /// In en, this message translates to:
  /// **'Coconut'**
  String get cropCoconut;

  /// No description provided for @cropAmpalaya.
  ///
  /// In en, this message translates to:
  /// **'Bitter gourd'**
  String get cropAmpalaya;

  /// No description provided for @cropSquash.
  ///
  /// In en, this message translates to:
  /// **'Squash'**
  String get cropSquash;

  /// No description provided for @cropSweetPotato.
  ///
  /// In en, this message translates to:
  /// **'Sweet potato'**
  String get cropSweetPotato;

  /// No description provided for @cropTaro.
  ///
  /// In en, this message translates to:
  /// **'Taro (Gabi)'**
  String get cropTaro;

  /// No description provided for @cropCalamansi.
  ///
  /// In en, this message translates to:
  /// **'Calamansi'**
  String get cropCalamansi;

  /// No description provided for @cropDescBanana.
  ///
  /// In en, this message translates to:
  /// **'Bears fruit through the year. Plant at the start of the rainy season and prop plants before typhoons.'**
  String get cropDescBanana;

  /// No description provided for @cropDescRice.
  ///
  /// In en, this message translates to:
  /// **'Staple grain of the Philippines, grown in flooded paddies. Planted in both the wet and dry seasons.'**
  String get cropDescRice;

  /// No description provided for @cropDescCoconut.
  ///
  /// In en, this message translates to:
  /// **'A tree crop that gives buko, copra and coconut oil.'**
  String get cropDescCoconut;

  /// No description provided for @cropDescEggplant.
  ///
  /// In en, this message translates to:
  /// **'A popular vegetable for tortang talong and pinakbet. Grows best in the cooler dry months.'**
  String get cropDescEggplant;

  /// No description provided for @cropDescAmpalaya.
  ///
  /// In en, this message translates to:
  /// **'A bitter vegetable that climbs on a trellis. Used in ginisang ampalaya and pinakbet.'**
  String get cropDescAmpalaya;

  /// No description provided for @cropDescStringBeans.
  ///
  /// In en, this message translates to:
  /// **'A fast-growing vegetable that climbs on a trellis or stakes.'**
  String get cropDescStringBeans;

  /// No description provided for @cropDescSquash.
  ///
  /// In en, this message translates to:
  /// **'A vine with nutritious fruit. The leaves and flowers are also eaten. Common in pinakbet and ginataan.'**
  String get cropDescSquash;

  /// No description provided for @cropDescTomato.
  ///
  /// In en, this message translates to:
  /// **'Eaten fresh and used in sauces. Too much rain causes disease, so plant after the typhoon season.'**
  String get cropDescTomato;

  /// No description provided for @cropDescSweetPotato.
  ///
  /// In en, this message translates to:
  /// **'An easy-to-grow root crop that handles dry weather. Both the roots and the tops (talbos) are eaten.'**
  String get cropDescSweetPotato;

  /// No description provided for @cropDescTaro.
  ///
  /// In en, this message translates to:
  /// **'A root crop that likes moist soil. The corm (gabi) and the leaves are eaten, used in laing and sinigang.'**
  String get cropDescTaro;

  /// No description provided for @cropDescCalamansi.
  ///
  /// In en, this message translates to:
  /// **'A small citrus tree. The sour fruit is used for juice, dipping sauce and cooking. Needs sun and well-drained soil.'**
  String get cropDescCalamansi;

  /// No description provided for @plotHarvested.
  ///
  /// In en, this message translates to:
  /// **'Harvested'**
  String get plotHarvested;

  /// No description provided for @plotGrowing.
  ///
  /// In en, this message translates to:
  /// **'Growing'**
  String get plotGrowing;

  /// No description provided for @weatherSunny.
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get weatherSunny;

  /// No description provided for @weatherClearNight.
  ///
  /// In en, this message translates to:
  /// **'Clear night'**
  String get weatherClearNight;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherFoggy.
  ///
  /// In en, this message translates to:
  /// **'Foggy'**
  String get weatherFoggy;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Light drizzle'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @adviceThunderTitle.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm risk'**
  String get adviceThunderTitle;

  /// No description provided for @adviceThunderMsg.
  ///
  /// In en, this message translates to:
  /// **'Stay out of open fields and keep tools and animals under shelter.'**
  String get adviceThunderMsg;

  /// No description provided for @adviceRainTitle.
  ///
  /// In en, this message translates to:
  /// **'Rain is likely today'**
  String get adviceRainTitle;

  /// No description provided for @adviceRainMsg.
  ///
  /// In en, this message translates to:
  /// **'Do not spray or fertilize today - rain will wash it away. Check that your canals drain well.'**
  String get adviceRainMsg;

  /// No description provided for @adviceHotTitle.
  ///
  /// In en, this message translates to:
  /// **'Very hot today'**
  String get adviceHotTitle;

  /// No description provided for @adviceHotMsg.
  ///
  /// In en, this message translates to:
  /// **'Water early morning or late afternoon. Shade young seedlings during midday.'**
  String get adviceHotMsg;

  /// No description provided for @adviceWindTitle.
  ///
  /// In en, this message translates to:
  /// **'Strong wind'**
  String get adviceWindTitle;

  /// No description provided for @adviceWindMsg.
  ///
  /// In en, this message translates to:
  /// **'Secure banana plants with props and tie up tomato and bean stakes.'**
  String get adviceWindMsg;

  /// No description provided for @adviceFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Good days for field work'**
  String get adviceFieldTitle;

  /// No description provided for @adviceFieldMsg.
  ///
  /// In en, this message translates to:
  /// **'Dry days ahead - good for harvesting, drying palay, spraying and fertilizing.'**
  String get adviceFieldMsg;

  /// No description provided for @adviceNormalTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal weather'**
  String get adviceNormalTitle;

  /// No description provided for @adviceNormalMsg.
  ///
  /// In en, this message translates to:
  /// **'No special warnings. Continue your regular farm work.'**
  String get adviceNormalMsg;

  /// No description provided for @notifWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather Alert for Pagsanjan'**
  String get notifWeatherTitle;

  /// No description provided for @notifWeatherMsg.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain expected in the coming days. Ensure proper canal drainage for your crops.'**
  String get notifWeatherMsg;

  /// No description provided for @notifMarketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market Price Update'**
  String get notifMarketTitle;

  /// No description provided for @notifMarketMsg.
  ///
  /// In en, this message translates to:
  /// **'Tomato and Eggplant market prices show a potential 8% increase based on rain forecasts.'**
  String get notifMarketMsg;

  /// No description provided for @notifPlantingTitle.
  ///
  /// In en, this message translates to:
  /// **'Planting Season Window'**
  String get notifPlantingTitle;

  /// No description provided for @notifPlantingMsg.
  ///
  /// In en, this message translates to:
  /// **'Optimal planting window for Rice (Palay) is open this month in Laguna.'**
  String get notifPlantingMsg;

  /// No description provided for @notifPestTitle.
  ///
  /// In en, this message translates to:
  /// **'Pest Alert: Rice Stem Borer'**
  String get notifPestTitle;

  /// No description provided for @notifPestMsg.
  ///
  /// In en, this message translates to:
  /// **'Farmers in surrounding barangays reported minor stem borer activity. Monitor your paddies.'**
  String get notifPestMsg;

  /// No description provided for @notifSubsidyTitle.
  ///
  /// In en, this message translates to:
  /// **'Municipal Agri Subsidy'**
  String get notifSubsidyTitle;

  /// No description provided for @notifSubsidyMsg.
  ///
  /// In en, this message translates to:
  /// **'Organic fertilizer distribution is ongoing at the Municipal Agriculture Office.'**
  String get notifSubsidyMsg;

  /// No description provided for @reasonHeavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain expected; supply may drop.'**
  String get reasonHeavyRain;

  /// No description provided for @reasonDry.
  ///
  /// In en, this message translates to:
  /// **'Dry spell expected; mild supply pressure.'**
  String get reasonDry;

  /// No description provided for @reasonStable.
  ///
  /// In en, this message translates to:
  /// **'Stable weather; supply steady.'**
  String get reasonStable;

  /// No description provided for @sellWait.
  ///
  /// In en, this message translates to:
  /// **'Price may rise - consider waiting a few days to sell.'**
  String get sellWait;

  /// No description provided for @sellSlight.
  ///
  /// In en, this message translates to:
  /// **'Slight rise expected - sell when your harvest is ready.'**
  String get sellSlight;

  /// No description provided for @sellSoon.
  ///
  /// In en, this message translates to:
  /// **'Price may dip - sell soon if your crop is ready.'**
  String get sellSoon;

  /// No description provided for @guideHarvestRice.
  ///
  /// In en, this message translates to:
  /// **'110-120 days'**
  String get guideHarvestRice;

  /// No description provided for @guideTipRice.
  ///
  /// In en, this message translates to:
  /// **'Wet season crop starts June-July. Dry season crop starts Nov-Dec and needs steady irrigation.'**
  String get guideTipRice;

  /// No description provided for @guideHarvestEggplant.
  ///
  /// In en, this message translates to:
  /// **'90-120 days'**
  String get guideHarvestEggplant;

  /// No description provided for @guideTipEggplant.
  ///
  /// In en, this message translates to:
  /// **'Grows best in the cooler dry months. Avoid transplanting during heavy rain.'**
  String get guideTipEggplant;

  /// No description provided for @guideHarvestTomato.
  ///
  /// In en, this message translates to:
  /// **'90-110 days'**
  String get guideHarvestTomato;

  /// No description provided for @guideTipTomato.
  ///
  /// In en, this message translates to:
  /// **'Too much rain causes disease and rotting. Plant after the typhoon season for best yield.'**
  String get guideTipTomato;

  /// No description provided for @guideHarvestStringBeans.
  ///
  /// In en, this message translates to:
  /// **'60-70 days'**
  String get guideHarvestStringBeans;

  /// No description provided for @guideTipStringBeans.
  ///
  /// In en, this message translates to:
  /// **'Fast crop. Provide trellis or stakes. Needs well-drained soil.'**
  String get guideTipStringBeans;

  /// No description provided for @guideHarvestBanana.
  ///
  /// In en, this message translates to:
  /// **'9-12 months'**
  String get guideHarvestBanana;

  /// No description provided for @guideTipBanana.
  ///
  /// In en, this message translates to:
  /// **'Plant at the start of the rainy season so suckers root well. Prop plants before typhoons.'**
  String get guideTipBanana;

  /// No description provided for @guideHarvestCoconut.
  ///
  /// In en, this message translates to:
  /// **'3-6 years to the first fruits'**
  String get guideHarvestCoconut;

  /// No description provided for @guideTipCoconut.
  ///
  /// In en, this message translates to:
  /// **'Plant seedlings at the start of the rainy season and keep them watered during the first dry season.'**
  String get guideTipCoconut;

  /// No description provided for @guideHarvestAmpalaya.
  ///
  /// In en, this message translates to:
  /// **'2-3 months after planting'**
  String get guideHarvestAmpalaya;

  /// No description provided for @guideTipAmpalaya.
  ///
  /// In en, this message translates to:
  /// **'Provide a trellis. Water regularly but avoid waterlogged soil.'**
  String get guideTipAmpalaya;

  /// No description provided for @guideHarvestSquash.
  ///
  /// In en, this message translates to:
  /// **'3-4 months after planting'**
  String get guideHarvestSquash;

  /// No description provided for @guideTipSquash.
  ///
  /// In en, this message translates to:
  /// **'Give the vines room to spread. Avoid planting during the heaviest rains.'**
  String get guideTipSquash;

  /// No description provided for @guideHarvestSweetPotato.
  ///
  /// In en, this message translates to:
  /// **'3-4 months after planting'**
  String get guideHarvestSweetPotato;

  /// No description provided for @guideTipSweetPotato.
  ///
  /// In en, this message translates to:
  /// **'Plant vine cuttings in loose soil. Avoid fields that flood.'**
  String get guideTipSweetPotato;

  /// No description provided for @guideHarvestTaro.
  ///
  /// In en, this message translates to:
  /// **'6-9 months after planting'**
  String get guideHarvestTaro;

  /// No description provided for @guideTipTaro.
  ///
  /// In en, this message translates to:
  /// **'Plant in moist soil with a steady water supply.'**
  String get guideTipTaro;

  /// No description provided for @guideHarvestCalamansi.
  ///
  /// In en, this message translates to:
  /// **'1-3 years to the first fruits'**
  String get guideHarvestCalamansi;

  /// No description provided for @guideTipCalamansi.
  ///
  /// In en, this message translates to:
  /// **'Choose a sunny spot with good drainage. Prune and fertilize regularly.'**
  String get guideTipCalamansi;

  /// No description provided for @errorLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load data. Check your internet connection and try again.'**
  String get errorLoad;

  /// No description provided for @navDss.
  ///
  /// In en, this message translates to:
  /// **'DSS'**
  String get navDss;

  /// No description provided for @dssMyTitle.
  ///
  /// In en, this message translates to:
  /// **'Farm Decision Support'**
  String get dssMyTitle;

  /// No description provided for @dssMySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your crop and get advice made for your farm'**
  String get dssMySubtitle;

  /// No description provided for @dssMyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These numbers are estimates and a guide only, not official data or a guaranteed forecast. Confirm with your Municipal Agriculture Office before making big decisions.'**
  String get dssMyDisclaimer;

  /// No description provided for @dssMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get dssMonthsShort;

  /// No description provided for @dssEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first crop'**
  String get dssEmptyTitle;

  /// No description provided for @dssEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the crop, land size and planting date. The planting advice, expected harvest, income and selling time will appear here.'**
  String get dssEmptyBody;

  /// No description provided for @dssAddPlanting.
  ///
  /// In en, this message translates to:
  /// **'Add crop'**
  String get dssAddPlanting;

  /// No description provided for @dssEditPlanting.
  ///
  /// In en, this message translates to:
  /// **'Edit crop'**
  String get dssEditPlanting;

  /// No description provided for @dssAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get dssAdd;

  /// No description provided for @dssDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dssDelete;

  /// No description provided for @dssDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this crop?'**
  String get dssDeleteTitle;

  /// No description provided for @dssDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{crop} will be removed from your list.'**
  String dssDeleteBody(String crop);

  /// No description provided for @dssMyPlantings.
  ///
  /// In en, this message translates to:
  /// **'My crops'**
  String get dssMyPlantings;

  /// No description provided for @dssCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get dssCrop;

  /// No description provided for @dssLandSize.
  ///
  /// In en, this message translates to:
  /// **'Land size'**
  String get dssLandSize;

  /// No description provided for @dssLandSizeHint.
  ///
  /// In en, this message translates to:
  /// **'In hectares. 1,000 sq m = 0.1 ha'**
  String get dssLandSizeHint;

  /// No description provided for @dssAreaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than 0'**
  String get dssAreaInvalid;

  /// No description provided for @dssPlantedOn.
  ///
  /// In en, this message translates to:
  /// **'Date planted'**
  String get dssPlantedOn;

  /// No description provided for @dssLastYield.
  ///
  /// In en, this message translates to:
  /// **'Last harvest (optional)'**
  String get dssLastYield;

  /// No description provided for @dssLastYieldHint.
  ///
  /// In en, this message translates to:
  /// **'Total kg from your last harvest on this land. Makes the estimate closer to your farm.'**
  String get dssLastYieldHint;

  /// No description provided for @dssDaysGrown.
  ///
  /// In en, this message translates to:
  /// **'Days since planting'**
  String get dssDaysGrown;

  /// No description provided for @dssDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String dssDaysCount(int n);

  /// No description provided for @dssNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet planted'**
  String get dssNotYet;

  /// No description provided for @dssExpectedHarvest.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest'**
  String get dssExpectedHarvest;

  /// No description provided for @dssHarvestYearRound.
  ///
  /// In en, this message translates to:
  /// **'Harvested through the year'**
  String get dssHarvestYearRound;

  /// No description provided for @dssPlantingAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Planting advice'**
  String get dssPlantingAdvisory;

  /// No description provided for @dssPlantingAdvisorySub.
  ///
  /// In en, this message translates to:
  /// **'Which months are best for this crop'**
  String get dssPlantingAdvisorySub;

  /// No description provided for @dssFitBest.
  ///
  /// In en, this message translates to:
  /// **'Now is a good time to plant {crop}'**
  String dssFitBest(String crop);

  /// No description provided for @dssFitPossible.
  ///
  /// In en, this message translates to:
  /// **'You can plant {crop} now, but it is not the best time'**
  String dssFitPossible(String crop);

  /// No description provided for @dssFitAvoid.
  ///
  /// In en, this message translates to:
  /// **'Not a good time to plant {crop} now'**
  String dssFitAvoid(String crop);

  /// No description provided for @dssLegendBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get dssLegendBest;

  /// No description provided for @dssLegendPossible.
  ///
  /// In en, this message translates to:
  /// **'Possible'**
  String get dssLegendPossible;

  /// No description provided for @dssLegendAvoid.
  ///
  /// In en, this message translates to:
  /// **'Avoid'**
  String get dssLegendAvoid;

  /// No description provided for @dssNextBest.
  ///
  /// In en, this message translates to:
  /// **'Next best months'**
  String get dssNextBest;

  /// No description provided for @dssWeatherBasis.
  ///
  /// In en, this message translates to:
  /// **'Based on'**
  String get dssWeatherBasis;

  /// No description provided for @dssWeatherBasisBody.
  ///
  /// In en, this message translates to:
  /// **'the usual rainy and dry seasons in Laguna. Check the weather forecast before planting.'**
  String get dssWeatherBasisBody;

  /// No description provided for @dssHarvestIncome.
  ///
  /// In en, this message translates to:
  /// **'Harvest and income'**
  String get dssHarvestIncome;

  /// No description provided for @dssHarvestIncomeSub.
  ///
  /// In en, this message translates to:
  /// **'Estimate with a range'**
  String get dssHarvestIncomeSub;

  /// No description provided for @dssExpectedYield.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest'**
  String get dssExpectedYield;

  /// No description provided for @dssYieldPerYear.
  ///
  /// In en, this message translates to:
  /// **'Harvest per year'**
  String get dssYieldPerYear;

  /// No description provided for @dssExpectedIncome.
  ///
  /// In en, this message translates to:
  /// **'Expected income'**
  String get dssExpectedIncome;

  /// No description provided for @dssNoPrice.
  ///
  /// In en, this message translates to:
  /// **'No sample price for this crop'**
  String get dssNoPrice;

  /// No description provided for @dssNoEstimate.
  ///
  /// In en, this message translates to:
  /// **'No estimate available for this crop yet.'**
  String get dssNoEstimate;

  /// No description provided for @dssLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get dssLow;

  /// No description provided for @dssLikely.
  ///
  /// In en, this message translates to:
  /// **'Likely'**
  String get dssLikely;

  /// No description provided for @dssHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get dssHigh;

  /// No description provided for @dssHowComputed.
  ///
  /// In en, this message translates to:
  /// **'How it is computed'**
  String get dssHowComputed;

  /// No description provided for @dssBasisOwn.
  ///
  /// In en, this message translates to:
  /// **'Your own harvest per hectare (from your records), for {ha} (±15%).'**
  String dssBasisOwn(String ha);

  /// No description provided for @dssBasisTypical.
  ///
  /// In en, this message translates to:
  /// **'Typical harvest of about {kgHa} kg per hectare, for {ha}.'**
  String dssBasisTypical(String ha, String kgHa);

  /// No description provided for @dssPriceUsed.
  ///
  /// In en, this message translates to:
  /// **'Price used'**
  String get dssPriceUsed;

  /// No description provided for @dssPriceAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Price advice'**
  String get dssPriceAdvisory;

  /// No description provided for @dssPriceAdvisorySub.
  ///
  /// In en, this message translates to:
  /// **'Which months prices are usually high'**
  String get dssPriceAdvisorySub;

  /// No description provided for @dssSellBest.
  ///
  /// In en, this message translates to:
  /// **'Prices are expected to be higher in {months}'**
  String dssSellBest(String months);

  /// No description provided for @dssLegendHighPrice.
  ///
  /// In en, this message translates to:
  /// **'Higher price'**
  String get dssLegendHighPrice;

  /// No description provided for @dssLegendLowPrice.
  ///
  /// In en, this message translates to:
  /// **'Lower price'**
  String get dssLegendLowPrice;

  /// No description provided for @dssYourHarvest.
  ///
  /// In en, this message translates to:
  /// **'Your harvest'**
  String get dssYourHarvest;

  /// No description provided for @dssHarvestHighPrice.
  ///
  /// In en, this message translates to:
  /// **'You will likely harvest around {month}, when prices are usually good.'**
  String dssHarvestHighPrice(String month);

  /// No description provided for @dssHarvestLowPrice.
  ///
  /// In en, this message translates to:
  /// **'You will likely harvest around {month}, when many farmers harvest and prices tend to be lower.'**
  String dssHarvestLowPrice(String month);

  /// No description provided for @dssTipStorable.
  ///
  /// In en, this message translates to:
  /// **'This crop keeps well. If you can store it safely, consider selling in {months}.'**
  String dssTipStorable(String months);

  /// No description provided for @dssTipFresh.
  ///
  /// In en, this message translates to:
  /// **'This crop spoils quickly, so sell soon after harvest. Ask buyers for the best price and sell directly if you can.'**
  String get dssTipFresh;

  /// No description provided for @dssPriceRangeYear.
  ///
  /// In en, this message translates to:
  /// **'Price range through the year'**
  String get dssPriceRangeYear;

  /// No description provided for @dssPriceFlat.
  ///
  /// In en, this message translates to:
  /// **'There is no clear monthly price pattern for {crop} in our guide.'**
  String dssPriceFlat(String crop);

  /// No description provided for @dssFarmMap.
  ///
  /// In en, this message translates to:
  /// **'My farm map'**
  String get dssFarmMap;

  /// No description provided for @dssFarmMapSub.
  ///
  /// In en, this message translates to:
  /// **'Farm location and weather there now'**
  String get dssFarmMapSub;

  /// No description provided for @dssMapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to move the pin to your farm.'**
  String get dssMapHint;

  /// No description provided for @dssResetLocation.
  ///
  /// In en, this message translates to:
  /// **'Back to Pagsanjan center'**
  String get dssResetLocation;

  /// No description provided for @dssWeatherHere.
  ///
  /// In en, this message translates to:
  /// **'Weather at your farm now'**
  String get dssWeatherHere;

  /// No description provided for @dssWeatherFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the weather here.'**
  String get dssWeatherFailed;

  /// No description provided for @dssFeelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get dssFeelsLike;

  /// No description provided for @dssSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'DSS'**
  String get dssSummaryTitle;

  /// No description provided for @dssSummaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add your crop in the DSS tab to get advice for your farm'**
  String get dssSummaryEmpty;

  /// No description provided for @dssSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest about {kg}, income {low} to {high}.'**
  String dssSummaryLine(String kg, String low, String high);

  /// No description provided for @dssSummaryLineNoPrice.
  ///
  /// In en, this message translates to:
  /// **'Expected harvest about {kg}.'**
  String dssSummaryLineNoPrice(String kg);

  /// No description provided for @weatherLightRain.
  ///
  /// In en, this message translates to:
  /// **'Light rain'**
  String get weatherLightRain;

  /// No description provided for @weatherHeavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get weatherHeavyRain;

  /// No description provided for @heatBestWork.
  ///
  /// In en, this message translates to:
  /// **'Best time for field work'**
  String get heatBestWork;

  /// No description provided for @heatNoSafe.
  ///
  /// In en, this message translates to:
  /// **'Avoid long field work today'**
  String get heatNoSafe;

  /// No description provided for @priceNoMyCrops.
  ///
  /// In en, this message translates to:
  /// **'Add your crop in the DSS tab to see its expected price here.'**
  String get priceNoMyCrops;

  /// No description provided for @cropAdvHarvestReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: check for harvest'**
  String cropAdvHarvestReadyTitle(String crop);

  /// No description provided for @cropAdvHarvestReadyMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {crop} has reached the usual harvest age. Check the crop and plan your harvest and buyers.'**
  String cropAdvHarvestReadyMsg(String crop);

  /// No description provided for @cropAdvHarvestSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: harvest is near'**
  String cropAdvHarvestSoonTitle(String crop);

  /// No description provided for @cropAdvHarvestSoonMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {crop} may be ready in about {days} days. Prepare containers, workers and buyers.'**
  String cropAdvHarvestSoonMsg(String crop, int days);

  /// No description provided for @cropAdvDrainageTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: check drainage'**
  String cropAdvDrainageTitle(String crop);

  /// No description provided for @cropAdvDrainageMsg.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain is expected in the next 3 days. Clear the canals so water does not pool around your {crop}.'**
  String cropAdvDrainageMsg(String crop);

  /// No description provided for @cropAdvHeatTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: protect from heat'**
  String cropAdvHeatTitle(String crop);

  /// No description provided for @cropAdvHeatMsg.
  ///
  /// In en, this message translates to:
  /// **'It is very hot today. Water your {crop} early morning or late afternoon, not at midday.'**
  String cropAdvHeatMsg(String crop);

  /// No description provided for @cropAdvWindTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: secure your plants'**
  String cropAdvWindTitle(String crop);

  /// No description provided for @cropAdvWindMsg.
  ///
  /// In en, this message translates to:
  /// **'Strong wind today. Support or tie your {crop} so the plants do not fall.'**
  String cropAdvWindMsg(String crop);

  /// No description provided for @cropAdvDryTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: good drying days'**
  String cropAdvDryTitle(String crop);

  /// No description provided for @cropAdvDryMsg.
  ///
  /// In en, this message translates to:
  /// **'Dry days ahead. Good for harvesting and drying your {crop}, and for spraying and fertilizing.'**
  String cropAdvDryMsg(String crop);

  /// No description provided for @notifStormTitle.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm now'**
  String get notifStormTitle;

  /// No description provided for @notifStormMsg.
  ///
  /// In en, this message translates to:
  /// **'Stay out of open fields and keep tools and animals under shelter.'**
  String get notifStormMsg;

  /// No description provided for @notifRainTitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain expected'**
  String get notifRainTitle;

  /// No description provided for @notifRainMsg.
  ///
  /// In en, this message translates to:
  /// **'About {mm} mm of rain in the next 3 days. Clear your canals so water does not pool in the field.'**
  String notifRainMsg(int mm);

  /// No description provided for @notifHeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Dangerous heat today'**
  String get notifHeatTitle;

  /// No description provided for @notifHeatMsg.
  ///
  /// In en, this message translates to:
  /// **'Heat index up to {hi}°C. Avoid field work at midday, rest in the shade and drink water.'**
  String notifHeatMsg(int hi);

  /// No description provided for @notifHarvestReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: check for harvest'**
  String notifHarvestReadyTitle(String crop);

  /// No description provided for @notifHarvestReadyMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {crop} has reached the usual harvest age. Check the crop and plan your harvest.'**
  String notifHarvestReadyMsg(String crop);

  /// No description provided for @notifHarvestSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop}: harvest is near'**
  String notifHarvestSoonTitle(String crop);

  /// No description provided for @notifHarvestSoonMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {crop} may be ready in about {days} days.'**
  String notifHarvestSoonMsg(String crop, int days);

  /// No description provided for @notifMarketUpTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop} price may go up'**
  String notifMarketUpTitle(String crop);

  /// No description provided for @notifMarketUpMsg.
  ///
  /// In en, this message translates to:
  /// **'The price of {crop} may rise about {percent}% in the next 7 days. This is an estimate from the weather forecast.'**
  String notifMarketUpMsg(String crop, int percent);

  /// No description provided for @notifMarketDownTitle.
  ///
  /// In en, this message translates to:
  /// **'{crop} price may go down'**
  String notifMarketDownTitle(String crop);

  /// No description provided for @notifMarketDownMsg.
  ///
  /// In en, this message translates to:
  /// **'The price of {crop} may fall about {percent}% in the next 7 days. This is an estimate from the weather forecast.'**
  String notifMarketDownMsg(String crop, int percent);

  /// No description provided for @notifPlantingNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Good time to plant {crop}'**
  String notifPlantingNowTitle(String crop);

  /// No description provided for @notifPlantingNowMsg.
  ///
  /// In en, this message translates to:
  /// **'This month is one of the best months to plant {crop} in Pagsanjan, Laguna.'**
  String notifPlantingNowMsg(String crop);

  /// No description provided for @dssUnitHa.
  ///
  /// In en, this message translates to:
  /// **'Hectares (ha)'**
  String get dssUnitHa;

  /// No description provided for @dssUnitSqm.
  ///
  /// In en, this message translates to:
  /// **'Square meters (m²)'**
  String get dssUnitSqm;

  /// No description provided for @dssUnitNote.
  ///
  /// In en, this message translates to:
  /// **'1 hectare = 10,000 m². You can switch between the two anytime.'**
  String get dssUnitNote;

  /// No description provided for @dssTotalLand.
  ///
  /// In en, this message translates to:
  /// **'Total land size'**
  String get dssTotalLand;

  /// No description provided for @dssTotalLandSub.
  ///
  /// In en, this message translates to:
  /// **'Enter the whole size of your farm. You will divide it among your crops in \"Add crop\".'**
  String get dssTotalLandSub;

  /// No description provided for @dssTotalTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Too small. Your crops already use {area}.'**
  String dssTotalTooSmall(String area);

  /// No description provided for @dssExceeds.
  ///
  /// In en, this message translates to:
  /// **'Too much. Only {area} of your land is left.'**
  String dssExceeds(String area);

  /// No description provided for @dssRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {area}'**
  String dssRemaining(String area);

  /// No description provided for @dssLandUsed.
  ///
  /// In en, this message translates to:
  /// **'Planted: {area}'**
  String dssLandUsed(String area);

  /// No description provided for @dssLandSet.
  ///
  /// In en, this message translates to:
  /// **'Set land size'**
  String get dssLandSet;

  /// No description provided for @dssLandNotSet.
  ///
  /// In en, this message translates to:
  /// **'Enter your total land size so the app can show how much each crop uses.'**
  String get dssLandNotSet;

  /// No description provided for @farmUnallocated.
  ///
  /// In en, this message translates to:
  /// **'Not planted'**
  String get farmUnallocated;

  /// No description provided for @dssCost.
  ///
  /// In en, this message translates to:
  /// **'Production cost (optional)'**
  String get dssCost;

  /// No description provided for @dssCostHint.
  ///
  /// In en, this message translates to:
  /// **'Total you spent or will spend on this crop: seeds, fertilizer, pesticide, labor, water. It is used to show your profit.'**
  String get dssCostHint;

  /// No description provided for @dssCostDetails.
  ///
  /// In en, this message translates to:
  /// **'Cost details (optional)'**
  String get dssCostDetails;

  /// No description provided for @dssCostSeed.
  ///
  /// In en, this message translates to:
  /// **'Seeds / seedlings'**
  String get dssCostSeed;

  /// No description provided for @dssCostFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get dssCostFertilizer;

  /// No description provided for @dssCostPesticide.
  ///
  /// In en, this message translates to:
  /// **'Pesticide'**
  String get dssCostPesticide;

  /// No description provided for @dssCostLabor.
  ///
  /// In en, this message translates to:
  /// **'Labor and hired work'**
  String get dssCostLabor;

  /// No description provided for @dssCostOther.
  ///
  /// In en, this message translates to:
  /// **'Other (water, fuel, transport)'**
  String get dssCostOther;

  /// No description provided for @dssYourCost.
  ///
  /// In en, this message translates to:
  /// **'Your cost'**
  String get dssYourCost;

  /// No description provided for @dssProfit.
  ///
  /// In en, this message translates to:
  /// **'Estimated profit'**
  String get dssProfit;

  /// No description provided for @dssRoi.
  ///
  /// In en, this message translates to:
  /// **'Return on cost'**
  String get dssRoi;

  /// No description provided for @dssCostAsk.
  ///
  /// In en, this message translates to:
  /// **'Add your production cost when you edit this crop to see your profit.'**
  String get dssCostAsk;

  /// No description provided for @dssProfitNote.
  ///
  /// In en, this message translates to:
  /// **'Profit = expected income minus your cost. The low value uses the lower harvest and price, and the high value uses the higher ones.'**
  String get dssProfitNote;

  /// No description provided for @dssRecordHarvest.
  ///
  /// In en, this message translates to:
  /// **'Record harvest'**
  String get dssRecordHarvest;

  /// No description provided for @dssRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record harvest: {crop}'**
  String dssRecordTitle(String crop);

  /// No description provided for @dssRecordSub.
  ///
  /// In en, this message translates to:
  /// **'Enter what really happened. Your records make the advice closer to your own farm.'**
  String get dssRecordSub;

  /// No description provided for @dssHarvestedOn.
  ///
  /// In en, this message translates to:
  /// **'Date harvested'**
  String get dssHarvestedOn;

  /// No description provided for @dssActualYield.
  ///
  /// In en, this message translates to:
  /// **'Total harvest'**
  String get dssActualYield;

  /// No description provided for @dssSoldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price you sold at'**
  String get dssSoldPrice;

  /// No description provided for @dssSoldPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Estimated price: {price} per kg'**
  String dssSoldPriceHint(String price);

  /// No description provided for @dssRecIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dssRecIncome;

  /// No description provided for @dssRecProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get dssRecProfit;

  /// No description provided for @dssRecordSaved.
  ///
  /// In en, this message translates to:
  /// **'Harvest saved. The land is free again for your next crop.'**
  String get dssRecordSaved;

  /// No description provided for @farmHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Harvest history'**
  String get farmHistoryTitle;

  /// No description provided for @farmHistorySub.
  ///
  /// In en, this message translates to:
  /// **'Your recorded harvests, income and profit.'**
  String get farmHistorySub;

  /// No description provided for @farmHistoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get farmHistoryDeleteTitle;

  /// No description provided for @farmHistoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The {crop} harvest record will be removed.'**
  String farmHistoryDeleteBody(String crop);
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
      <String>['en', 'tl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tl':
      return AppLocalizationsTl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
