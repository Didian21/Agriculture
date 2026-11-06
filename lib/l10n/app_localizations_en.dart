// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appSubtitle => 'Pagsanjan Agriculture';

  @override
  String get notifications => 'Notifications';

  @override
  String get refresh => 'Refresh';

  @override
  String get navHome => 'Home';

  @override
  String get navWeather => 'Weather';

  @override
  String get navFarm => 'My Farm';

  @override
  String get navPlanting => 'Planting';

  @override
  String get navPrices => 'Prices';

  @override
  String get navSettings => 'Settings';

  @override
  String get loadingWeather => 'Getting your farm weather...';

  @override
  String get tryAgain => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get hectares => 'hectares';

  @override
  String get sqmShort => 'sqm';

  @override
  String get now => 'Now';

  @override
  String get today => 'Today';

  @override
  String get portalTitle => 'Pagsanjan Farmer Portal';

  @override
  String get signInTitle => 'Sign In to Portal';

  @override
  String get signInHint =>
      'Enter your phone number and security PIN to continue.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get pinLabel => '4-Digit PIN Passcode';

  @override
  String get signIn => 'Sign In';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get todayWeather => 'Today\'s weather';

  @override
  String get heatIndex => 'Heat index';

  @override
  String get heatIndexSub => 'How hot it feels when humidity is included';

  @override
  String get heatNormal => 'Normal';

  @override
  String get heatCaution => 'Caution';

  @override
  String get heatExtremeCaution => 'Extreme caution';

  @override
  String get heatDanger => 'Danger';

  @override
  String get heatExtremeDanger => 'Extreme danger';

  @override
  String get heatAdviceNormal =>
      'Comfortable for field work. Drink water regularly.';

  @override
  String get heatAdviceCaution =>
      'Fatigue is possible with long exposure. Rest in the shade and drink water.';

  @override
  String get heatAdviceExtremeCaution =>
      'Heat cramps and exhaustion are possible. Work early morning or late afternoon and rest often.';

  @override
  String get heatAdviceDanger =>
      'Heat exhaustion is likely and heat stroke is possible. Avoid field work at midday.';

  @override
  String get heatAdviceExtremeDanger =>
      'Heat stroke is highly likely. Stay indoors or in the shade and avoid field work.';

  @override
  String get heatScaleSource =>
      'Estimated from temperature and humidity. Levels follow the PAGASA heat index scale.';

  @override
  String get forecastTitle => 'Forecast';

  @override
  String get hourlyTab => 'Hourly';

  @override
  String get weeklyTab => '7 days';

  @override
  String get heatTimeline => 'Heat index by hour today';

  @override
  String get heatHottest => 'Hottest time';

  @override
  String get farmCropsTitle => 'My crops';

  @override
  String get farmCropsSub => 'Tap a crop to see its best planting months.';

  @override
  String get farmTotalHarvest => 'Total harvest';

  @override
  String farmShare(String percent) {
    return '$percent% of your land';
  }

  @override
  String get farmThisMonth => 'This month';

  @override
  String farmDaysGrown(int days, int total) {
    return 'Day $days of about $total';
  }

  @override
  String farmExpectedHarvest(String range) {
    return 'Expected harvest: $range';
  }

  @override
  String get farmReadySoon => 'Almost ready to harvest';

  @override
  String get farmLastHarvest => 'Last harvest';

  @override
  String farmYieldPerHa(String value) {
    return '$value kg per hectare';
  }

  @override
  String get farmEstimateNote =>
      'Dates are estimates. The actual harvest depends on the weather and the variety.';

  @override
  String get priceMyCrops => 'My crops';

  @override
  String get priceAllCrops => 'All crops';

  @override
  String get priceRising => 'Rising';

  @override
  String get priceFalling => 'Falling';

  @override
  String get priceGraphTitle => 'Expected price, next 7 days';

  @override
  String get priceRange => '7-day range';

  @override
  String get priceHighest => 'Highest expected';

  @override
  String get priceWhyTitle => 'Why is the price changing?';

  @override
  String get priceFactorRain => 'Rain';

  @override
  String get priceFactorHeat => 'Heat';

  @override
  String get priceFactorSeason => 'Harvest season';

  @override
  String priceRainHeavy(String mm) {
    return 'About $mm mm of rain in the next 7 days. Flooded fields can cut supply, so prices tend to rise.';
  }

  @override
  String priceRainDry(String mm) {
    return 'Only about $mm mm of rain in the next 7 days. A dry spell can reduce harvests, so prices may rise slightly.';
  }

  @override
  String priceRainNormal(String mm) {
    return 'About $mm mm of rain in the next 7 days. Normal weather, so supply stays steady.';
  }

  @override
  String priceHeatHigh(String hi) {
    return 'Very hot days ahead (heat index up to $hi°C). Heat stress can lower harvests, so prices may rise.';
  }

  @override
  String get priceHeatNormal =>
      'No extreme heat expected. No effect on the price.';

  @override
  String get priceSeasonPeak =>
      'Based on the planting calendar, this crop is in its peak harvest time. More supply usually means lower prices.';

  @override
  String get priceSeasonOff =>
      'Based on the planting calendar, this crop is not in its peak harvest time. Less supply usually keeps prices steady or higher.';

  @override
  String priceLastHarvestValue(String kg, String value) {
    return 'Your last harvest ($kg kg) would be worth about ₱$value at the expected price.';
  }

  @override
  String get priceDisclaimer =>
      'These are estimates from a simple model that uses the 7-day weather forecast and the planting calendar. The current prices are sample values, not official market prices. Please check with your Municipal Agriculture Office or the market before selling.';

  @override
  String get farmOverview => 'Farm overview';

  @override
  String get overviewCrops => 'Crops';

  @override
  String get overviewCropsSub => 'Active crops';

  @override
  String get overviewPlantNow => 'Good to plant';

  @override
  String get overviewPlantNowSub => 'crops this month';

  @override
  String get next12Hours => 'Next 12 hours';

  @override
  String get adviceTitle => 'Farm advice for today';

  @override
  String get adviceSubtitle => 'Based on the live weather';

  @override
  String get forecast7Days => '7-day forecast';

  @override
  String plantInMonth(String month) {
    return 'Good to plant in $month';
  }

  @override
  String get noBestCrop => 'No crop is at its best planting time this month.';

  @override
  String get statusLive => 'LIVE';

  @override
  String get statusOffline => 'OFFLINE';

  @override
  String get feelsLike => 'Feels like';

  @override
  String get humidity => 'Humidity';

  @override
  String get wind => 'Wind';

  @override
  String get rainChance => 'Rain chance';

  @override
  String todayRange(String min, String max, String rain) {
    return 'Today: $min° - $max°   •   Rain $rain mm';
  }

  @override
  String updatedAt(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'Updated $timeString  (auto-refresh every 10 min)';
  }

  @override
  String get homeCropsTitle => 'Crops of Pagsanjan';

  @override
  String get homeCropsSub => 'Tap a crop to see the best months to plant it.';

  @override
  String get homeCropsNote =>
      'Common crops grown in Laguna. Planting months are a guide - confirm with your Municipal Agriculture Office.';

  @override
  String get dssTitle => 'Best months to plant';

  @override
  String get dssSubtitle => 'Pagsanjan, Laguna - planting calendar guide';

  @override
  String get dssRainNote =>
      'A lot of rain is expected this week. Check your canals and drainage before planting.';

  @override
  String get dssBestMonths => 'Best months';

  @override
  String get dssPossibleMonths => 'Possible months';

  @override
  String get dssTip => 'Tip';

  @override
  String get dssDisclaimer =>
      'This graph is a guide based on the planting calendar for Pagsanjan, Laguna. It is not a forecast of yield or price. Please confirm with your Municipal Agriculture Office.';

  @override
  String get totalLandSize => 'Total land size';

  @override
  String get plantedWhere => 'What is planted where';

  @override
  String get cropHistory => 'Crop record history';

  @override
  String plantedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Planted $dateString';
  }

  @override
  String harvestedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Harvested $dateString';
  }

  @override
  String get stillGrowing => 'Still growing';

  @override
  String get whenToPlant => 'When should I plant?';

  @override
  String get tapMonth => 'Tap a month to see which crops are best to plant.';

  @override
  String get legendBest => 'Best';

  @override
  String get legendPossible => 'Possible';

  @override
  String get legendAvoid => 'Not advised';

  @override
  String get myCrop => 'My crop';

  @override
  String get statusBest => 'Best time to plant';

  @override
  String get statusPossible => 'Can plant, some risk';

  @override
  String get statusAvoid => 'Not advised now';

  @override
  String bestMonthLabel(String month) {
    return 'Best: $month';
  }

  @override
  String harvestIn(String time) {
    return 'Ready to harvest in $time';
  }

  @override
  String get plantingDisclaimer =>
      'This is a general guide for Laguna. Weather can change from year to year - please confirm with your Municipal Agriculture Office.';

  @override
  String get cropPrices => 'Crop prices';

  @override
  String get pricesSubtitle =>
      'Expected price based on the coming weather. In PHP per kg.';

  @override
  String get noPriceData => 'No price data for your crops yet.';

  @override
  String get expected => 'Expected';

  @override
  String get appSettings => 'App Settings';

  @override
  String get appSettingsSub =>
      'View your account, get help, and read the privacy policy.';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get farmerName => 'Farmer Name';

  @override
  String get barangay => 'Barangay';

  @override
  String get birthday => 'Birthday';

  @override
  String get landSize => 'Land Size';

  @override
  String get displaySettings => 'Display';

  @override
  String get displaySettingsSub => 'Make the text easier to read';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Large';

  @override
  String get textSizeXLarge => 'Extra large';

  @override
  String get textSizeSample => 'Sample: Good morning, farmer!';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpSupportSub => 'Need help with the app or your farm?';

  @override
  String get howToUse => 'How to use PAGRI';

  @override
  String get howTo1 =>
      'DSS (the green button in the middle): first set your total land size, then add your crops with land area, planting date, last yield and cost. You will see when to plant, an estimate of harvest and income, and price advice.';

  @override
  String get howTo2 =>
      'Weather: see today\'s weather, the 7-day forecast, the heat index and advice for your crops.';

  @override
  String get howTo3 =>
      'My Farm: see your crops and how your land is shared (hectares or square meters). Tap a crop to open it in DSS. Your harvest records are here too.';

  @override
  String get howTo4 =>
      'Prices: only the crops you added in DSS appear here, with expected prices and when it is a good time to sell.';

  @override
  String get howTo5 =>
      'After harvest, tap \"Record harvest\" in DSS so estimates get closer to your own farm. Tap the bell at the top to read notifications. Numbers are estimates only, not official.';

  @override
  String get contactOffice => 'Municipal Agriculture Office';

  @override
  String get contactOfficeSub =>
      'Visit the office in Pagsanjan, Laguna for account changes, subsidies and farming help.';

  @override
  String get aboutApp => 'About';

  @override
  String get appVersion => 'PAGRI version 1.0.0';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacySystemName => 'Pagsanjan Agriculture System';

  @override
  String get privacySummary =>
      'PAGRI (Pagsanjan Agricultural Decision Support System) protects the data of every registered farmer. Information such as barangay, land size, and crops are used solely for weather forecasting, market pricing, and support from the Municipal Agriculture Office.';

  @override
  String get readFullPolicy => 'Read Full Privacy Policy';

  @override
  String get logout => 'Log Out';

  @override
  String get logoutConfirm =>
      'Are you sure you want to log out of your PAGRI portal?';

  @override
  String get logoutButton => 'Log Out';

  @override
  String get privacySubtitle =>
      'Agricultural Decision Support System (PAGRI - Pagsanjan, Laguna)';

  @override
  String get policy1Title => '1. Information We Collect';

  @override
  String get policy1Body =>
      'PAGRI collects basic farmer information including name, barangay, land size, and crop types to generate localized weather advisories and price forecasts.';

  @override
  String get policy2Title => '2. How Information is Used';

  @override
  String get policy2Body =>
      'Your data is strictly utilized to process Open-Meteo weather forecasts, model estimated market prices, and assist the Pagsanjan Municipal Agriculture Office in local agricultural planning.';

  @override
  String get policy3Title => '3. Data Protection & Security';

  @override
  String get policy3Body =>
      'All farmer records are protected under secure protocols. Personal details are never sold or shared with third parties for commercial gain.';

  @override
  String get policy4Title => '4. Farmer Rights';

  @override
  String get policy4Body =>
      'Farmers maintain full rights to review, update, or request deletion of their profile records anytime through the app or by contacting the Municipal Agriculture Office.';

  @override
  String get understand => 'I Understand';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No new notifications right now.';

  @override
  String get cropRice => 'Rice';

  @override
  String get cropEggplant => 'Eggplant';

  @override
  String get cropTomato => 'Tomato';

  @override
  String get cropStringBeans => 'String beans';

  @override
  String get cropBanana => 'Banana';

  @override
  String get cropCoconut => 'Coconut';

  @override
  String get cropAmpalaya => 'Bitter gourd';

  @override
  String get cropSquash => 'Squash';

  @override
  String get cropSweetPotato => 'Sweet potato';

  @override
  String get cropTaro => 'Taro (Gabi)';

  @override
  String get cropCalamansi => 'Calamansi';

  @override
  String get cropDescBanana =>
      'Bears fruit through the year. Plant at the start of the rainy season and prop plants before typhoons.';

  @override
  String get cropDescRice =>
      'Staple grain of the Philippines, grown in flooded paddies. Planted in both the wet and dry seasons.';

  @override
  String get cropDescCoconut =>
      'A tree crop that gives buko, copra and coconut oil.';

  @override
  String get cropDescEggplant =>
      'A popular vegetable for tortang talong and pinakbet. Grows best in the cooler dry months.';

  @override
  String get cropDescAmpalaya =>
      'A bitter vegetable that climbs on a trellis. Used in ginisang ampalaya and pinakbet.';

  @override
  String get cropDescStringBeans =>
      'A fast-growing vegetable that climbs on a trellis or stakes.';

  @override
  String get cropDescSquash =>
      'A vine with nutritious fruit. The leaves and flowers are also eaten. Common in pinakbet and ginataan.';

  @override
  String get cropDescTomato =>
      'Eaten fresh and used in sauces. Too much rain causes disease, so plant after the typhoon season.';

  @override
  String get cropDescSweetPotato =>
      'An easy-to-grow root crop that handles dry weather. Both the roots and the tops (talbos) are eaten.';

  @override
  String get cropDescTaro =>
      'A root crop that likes moist soil. The corm (gabi) and the leaves are eaten, used in laing and sinigang.';

  @override
  String get cropDescCalamansi =>
      'A small citrus tree. The sour fruit is used for juice, dipping sauce and cooking. Needs sun and well-drained soil.';

  @override
  String get plotHarvested => 'Harvested';

  @override
  String get plotGrowing => 'Growing';

  @override
  String get weatherSunny => 'Sunny';

  @override
  String get weatherClearNight => 'Clear night';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFoggy => 'Foggy';

  @override
  String get weatherDrizzle => 'Light drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get adviceThunderTitle => 'Thunderstorm risk';

  @override
  String get adviceThunderMsg =>
      'Stay out of open fields and keep tools and animals under shelter.';

  @override
  String get adviceRainTitle => 'Rain is likely today';

  @override
  String get adviceRainMsg =>
      'Do not spray or fertilize today - rain will wash it away. Check that your canals drain well.';

  @override
  String get adviceHotTitle => 'Very hot today';

  @override
  String get adviceHotMsg =>
      'Water early morning or late afternoon. Shade young seedlings during midday.';

  @override
  String get adviceWindTitle => 'Strong wind';

  @override
  String get adviceWindMsg =>
      'Secure banana plants with props and tie up tomato and bean stakes.';

  @override
  String get adviceFieldTitle => 'Good days for field work';

  @override
  String get adviceFieldMsg =>
      'Dry days ahead - good for harvesting, drying palay, spraying and fertilizing.';

  @override
  String get adviceNormalTitle => 'Normal weather';

  @override
  String get adviceNormalMsg =>
      'No special warnings. Continue your regular farm work.';

  @override
  String get notifWeatherTitle => 'Weather Alert for Pagsanjan';

  @override
  String get notifWeatherMsg =>
      'Heavy rain expected in the coming days. Ensure proper canal drainage for your crops.';

  @override
  String get notifMarketTitle => 'Market Price Update';

  @override
  String get notifMarketMsg =>
      'Tomato and Eggplant market prices show a potential 8% increase based on rain forecasts.';

  @override
  String get notifPlantingTitle => 'Planting Season Window';

  @override
  String get notifPlantingMsg =>
      'Optimal planting window for Rice (Palay) is open this month in Laguna.';

  @override
  String get notifPestTitle => 'Pest Alert: Rice Stem Borer';

  @override
  String get notifPestMsg =>
      'Farmers in surrounding barangays reported minor stem borer activity. Monitor your paddies.';

  @override
  String get notifSubsidyTitle => 'Municipal Agri Subsidy';

  @override
  String get notifSubsidyMsg =>
      'Organic fertilizer distribution is ongoing at the Municipal Agriculture Office.';

  @override
  String get reasonHeavyRain => 'Heavy rain expected; supply may drop.';

  @override
  String get reasonDry => 'Dry spell expected; mild supply pressure.';

  @override
  String get reasonStable => 'Stable weather; supply steady.';

  @override
  String get sellWait =>
      'Price may rise - consider waiting a few days to sell.';

  @override
  String get sellSlight =>
      'Slight rise expected - sell when your harvest is ready.';

  @override
  String get sellSoon => 'Price may dip - sell soon if your crop is ready.';

  @override
  String get guideHarvestRice => '110-120 days';

  @override
  String get guideTipRice =>
      'Wet season crop starts June-July. Dry season crop starts Nov-Dec and needs steady irrigation.';

  @override
  String get guideHarvestEggplant => '90-120 days';

  @override
  String get guideTipEggplant =>
      'Grows best in the cooler dry months. Avoid transplanting during heavy rain.';

  @override
  String get guideHarvestTomato => '90-110 days';

  @override
  String get guideTipTomato =>
      'Too much rain causes disease and rotting. Plant after the typhoon season for best yield.';

  @override
  String get guideHarvestStringBeans => '60-70 days';

  @override
  String get guideTipStringBeans =>
      'Fast crop. Provide trellis or stakes. Needs well-drained soil.';

  @override
  String get guideHarvestBanana => '9-12 months';

  @override
  String get guideTipBanana =>
      'Plant at the start of the rainy season so suckers root well. Prop plants before typhoons.';

  @override
  String get guideHarvestCoconut => '3-6 years to the first fruits';

  @override
  String get guideTipCoconut =>
      'Plant seedlings at the start of the rainy season and keep them watered during the first dry season.';

  @override
  String get guideHarvestAmpalaya => '2-3 months after planting';

  @override
  String get guideTipAmpalaya =>
      'Provide a trellis. Water regularly but avoid waterlogged soil.';

  @override
  String get guideHarvestSquash => '3-4 months after planting';

  @override
  String get guideTipSquash =>
      'Give the vines room to spread. Avoid planting during the heaviest rains.';

  @override
  String get guideHarvestSweetPotato => '3-4 months after planting';

  @override
  String get guideTipSweetPotato =>
      'Plant vine cuttings in loose soil. Avoid fields that flood.';

  @override
  String get guideHarvestTaro => '6-9 months after planting';

  @override
  String get guideTipTaro => 'Plant in moist soil with a steady water supply.';

  @override
  String get guideHarvestCalamansi => '1-3 years to the first fruits';

  @override
  String get guideTipCalamansi =>
      'Choose a sunny spot with good drainage. Prune and fertilize regularly.';

  @override
  String get errorLoad =>
      'Could not load data. Check your internet connection and try again.';

  @override
  String get navDss => 'DSS';

  @override
  String get dssMyTitle => 'Farm Decision Support';

  @override
  String get dssMySubtitle =>
      'Enter your crop and get advice made for your farm';

  @override
  String get dssMyDisclaimer =>
      'These numbers are estimates and a guide only, not official data or a guaranteed forecast. Confirm with your Municipal Agriculture Office before making big decisions.';

  @override
  String get dssMonthsShort =>
      'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String get dssEmptyTitle => 'Add your first crop';

  @override
  String get dssEmptyBody =>
      'Enter the crop, land size and planting date. The planting advice, expected harvest, income and selling time will appear here.';

  @override
  String get dssAddPlanting => 'Add crop';

  @override
  String get dssEditPlanting => 'Edit crop';

  @override
  String get dssAdd => 'Add';

  @override
  String get dssDelete => 'Delete';

  @override
  String get dssDeleteTitle => 'Delete this crop?';

  @override
  String dssDeleteBody(String crop) {
    return '$crop will be removed from your list.';
  }

  @override
  String get dssMyPlantings => 'My crops';

  @override
  String get dssCrop => 'Crop';

  @override
  String get dssLandSize => 'Land size';

  @override
  String get dssLandSizeHint => 'In hectares. 1,000 sq m = 0.1 ha';

  @override
  String get dssAreaInvalid => 'Enter a number greater than 0';

  @override
  String get dssPlantedOn => 'Date planted';

  @override
  String get dssLastYield => 'Last harvest (optional)';

  @override
  String get dssLastYieldHint =>
      'Total kg from your last harvest on this land. Makes the estimate closer to your farm.';

  @override
  String get dssDaysGrown => 'Days since planting';

  @override
  String dssDaysCount(int n) {
    return '$n days';
  }

  @override
  String get dssNotYet => 'Not yet planted';

  @override
  String get dssExpectedHarvest => 'Expected harvest';

  @override
  String get dssHarvestYearRound => 'Harvested through the year';

  @override
  String get dssPlantingAdvisory => 'Planting advice';

  @override
  String get dssPlantingAdvisorySub => 'Which months are best for this crop';

  @override
  String dssFitBest(String crop) {
    return 'Now is a good time to plant $crop';
  }

  @override
  String dssFitPossible(String crop) {
    return 'You can plant $crop now, but it is not the best time';
  }

  @override
  String dssFitAvoid(String crop) {
    return 'Not a good time to plant $crop now';
  }

  @override
  String get dssLegendBest => 'Best';

  @override
  String get dssLegendPossible => 'Possible';

  @override
  String get dssLegendAvoid => 'Avoid';

  @override
  String get dssNextBest => 'Next best months';

  @override
  String get dssWeatherBasis => 'Based on';

  @override
  String get dssWeatherBasisBody =>
      'the usual rainy and dry seasons in Laguna. Check the weather forecast before planting.';

  @override
  String get dssHarvestIncome => 'Harvest and income';

  @override
  String get dssHarvestIncomeSub => 'Estimate with a range';

  @override
  String get dssExpectedYield => 'Expected harvest';

  @override
  String get dssYieldPerYear => 'Harvest per year';

  @override
  String get dssExpectedIncome => 'Expected income';

  @override
  String get dssNoPrice => 'No sample price for this crop';

  @override
  String get dssNoEstimate => 'No estimate available for this crop yet.';

  @override
  String get dssLow => 'Low';

  @override
  String get dssLikely => 'Likely';

  @override
  String get dssHigh => 'High';

  @override
  String get dssHowComputed => 'How it is computed';

  @override
  String dssBasisOwn(String ha) {
    return 'Your own harvest per hectare (from your records), for $ha (±15%).';
  }

  @override
  String dssBasisTypical(String ha, String kgHa) {
    return 'Typical harvest of about $kgHa kg per hectare, for $ha.';
  }

  @override
  String get dssPriceUsed => 'Price used';

  @override
  String get dssPriceAdvisory => 'Price advice';

  @override
  String get dssPriceAdvisorySub => 'Which months prices are usually high';

  @override
  String dssSellBest(String months) {
    return 'Prices are expected to be higher in $months';
  }

  @override
  String get dssLegendHighPrice => 'Higher price';

  @override
  String get dssLegendLowPrice => 'Lower price';

  @override
  String get dssYourHarvest => 'Your harvest';

  @override
  String dssHarvestHighPrice(String month) {
    return 'You will likely harvest around $month, when prices are usually good.';
  }

  @override
  String dssHarvestLowPrice(String month) {
    return 'You will likely harvest around $month, when many farmers harvest and prices tend to be lower.';
  }

  @override
  String dssTipStorable(String months) {
    return 'This crop keeps well. If you can store it safely, consider selling in $months.';
  }

  @override
  String get dssTipFresh =>
      'This crop spoils quickly, so sell soon after harvest. Ask buyers for the best price and sell directly if you can.';

  @override
  String get dssPriceRangeYear => 'Price range through the year';

  @override
  String dssPriceFlat(String crop) {
    return 'There is no clear monthly price pattern for $crop in our guide.';
  }

  @override
  String get dssFarmMap => 'My farm map';

  @override
  String get dssFarmMapSub => 'Farm location and weather there now';

  @override
  String get dssMapHint => 'Tap the map to move the pin to your farm.';

  @override
  String get dssResetLocation => 'Back to Pagsanjan center';

  @override
  String get dssWeatherHere => 'Weather at your farm now';

  @override
  String get dssWeatherFailed => 'Could not load the weather here.';

  @override
  String get dssFeelsLike => 'Feels like';

  @override
  String get dssSummaryTitle => 'DSS';

  @override
  String get dssSummaryEmpty =>
      'Add your crop in the DSS tab to get advice for your farm';

  @override
  String dssSummaryLine(String kg, String low, String high) {
    return 'Expected harvest about $kg, income $low to $high.';
  }

  @override
  String dssSummaryLineNoPrice(String kg) {
    return 'Expected harvest about $kg.';
  }

  @override
  String get weatherLightRain => 'Light rain';

  @override
  String get weatherHeavyRain => 'Heavy rain';

  @override
  String get heatBestWork => 'Best time for field work';

  @override
  String get heatNoSafe => 'Avoid long field work today';

  @override
  String get priceNoMyCrops =>
      'Add your crop in the DSS tab to see its expected price here.';

  @override
  String cropAdvHarvestReadyTitle(String crop) {
    return '$crop: check for harvest';
  }

  @override
  String cropAdvHarvestReadyMsg(String crop) {
    return 'Your $crop has reached the usual harvest age. Check the crop and plan your harvest and buyers.';
  }

  @override
  String cropAdvHarvestSoonTitle(String crop) {
    return '$crop: harvest is near';
  }

  @override
  String cropAdvHarvestSoonMsg(String crop, int days) {
    return 'Your $crop may be ready in about $days days. Prepare containers, workers and buyers.';
  }

  @override
  String cropAdvDrainageTitle(String crop) {
    return '$crop: check drainage';
  }

  @override
  String cropAdvDrainageMsg(String crop) {
    return 'Heavy rain is expected in the next 3 days. Clear the canals so water does not pool around your $crop.';
  }

  @override
  String cropAdvHeatTitle(String crop) {
    return '$crop: protect from heat';
  }

  @override
  String cropAdvHeatMsg(String crop) {
    return 'It is very hot today. Water your $crop early morning or late afternoon, not at midday.';
  }

  @override
  String cropAdvWindTitle(String crop) {
    return '$crop: secure your plants';
  }

  @override
  String cropAdvWindMsg(String crop) {
    return 'Strong wind today. Support or tie your $crop so the plants do not fall.';
  }

  @override
  String cropAdvDryTitle(String crop) {
    return '$crop: good drying days';
  }

  @override
  String cropAdvDryMsg(String crop) {
    return 'Dry days ahead. Good for harvesting and drying your $crop, and for spraying and fertilizing.';
  }

  @override
  String get notifStormTitle => 'Thunderstorm now';

  @override
  String get notifStormMsg =>
      'Stay out of open fields and keep tools and animals under shelter.';

  @override
  String get notifRainTitle => 'Heavy rain expected';

  @override
  String notifRainMsg(int mm) {
    return 'About $mm mm of rain in the next 3 days. Clear your canals so water does not pool in the field.';
  }

  @override
  String get notifHeatTitle => 'Dangerous heat today';

  @override
  String notifHeatMsg(int hi) {
    return 'Heat index up to $hi°C. Avoid field work at midday, rest in the shade and drink water.';
  }

  @override
  String notifHarvestReadyTitle(String crop) {
    return '$crop: check for harvest';
  }

  @override
  String notifHarvestReadyMsg(String crop) {
    return 'Your $crop has reached the usual harvest age. Check the crop and plan your harvest.';
  }

  @override
  String notifHarvestSoonTitle(String crop) {
    return '$crop: harvest is near';
  }

  @override
  String notifHarvestSoonMsg(String crop, int days) {
    return 'Your $crop may be ready in about $days days.';
  }

  @override
  String notifMarketUpTitle(String crop) {
    return '$crop price may go up';
  }

  @override
  String notifMarketUpMsg(String crop, int percent) {
    return 'The price of $crop may rise about $percent% in the next 7 days. This is an estimate from the weather forecast.';
  }

  @override
  String notifMarketDownTitle(String crop) {
    return '$crop price may go down';
  }

  @override
  String notifMarketDownMsg(String crop, int percent) {
    return 'The price of $crop may fall about $percent% in the next 7 days. This is an estimate from the weather forecast.';
  }

  @override
  String notifPlantingNowTitle(String crop) {
    return 'Good time to plant $crop';
  }

  @override
  String notifPlantingNowMsg(String crop) {
    return 'This month is one of the best months to plant $crop in Pagsanjan, Laguna.';
  }

  @override
  String get dssUnitHa => 'Hectares (ha)';

  @override
  String get dssUnitSqm => 'Square meters (m²)';

  @override
  String get dssUnitNote =>
      '1 hectare = 10,000 m². You can switch between the two anytime.';

  @override
  String get dssTotalLand => 'Total land size';

  @override
  String get dssTotalLandSub =>
      'Enter the whole size of your farm. You will divide it among your crops in \"Add crop\".';

  @override
  String dssTotalTooSmall(String area) {
    return 'Too small. Your crops already use $area.';
  }

  @override
  String dssExceeds(String area) {
    return 'Too much. Only $area of your land is left.';
  }

  @override
  String dssRemaining(String area) {
    return 'Remaining: $area';
  }

  @override
  String dssLandUsed(String area) {
    return 'Planted: $area';
  }

  @override
  String get dssLandSet => 'Set land size';

  @override
  String get dssLandNotSet =>
      'Enter your total land size so the app can show how much each crop uses.';

  @override
  String get farmUnallocated => 'Not planted';

  @override
  String get dssCost => 'Production cost (optional)';

  @override
  String get dssCostHint =>
      'Total you spent or will spend on this crop: seeds, fertilizer, pesticide, labor, water. It is used to show your profit.';

  @override
  String get dssCostDetails => 'Cost details (optional)';

  @override
  String get dssCostSeed => 'Seeds / seedlings';

  @override
  String get dssCostFertilizer => 'Fertilizer';

  @override
  String get dssCostPesticide => 'Pesticide';

  @override
  String get dssCostLabor => 'Labor and hired work';

  @override
  String get dssCostOther => 'Other (water, fuel, transport)';

  @override
  String get dssYourCost => 'Your cost';

  @override
  String get dssProfit => 'Estimated profit';

  @override
  String get dssRoi => 'Return on cost';

  @override
  String get dssCostAsk =>
      'Add your production cost when you edit this crop to see your profit.';

  @override
  String get dssProfitNote =>
      'Profit = expected income minus your cost. The low value uses the lower harvest and price, and the high value uses the higher ones.';

  @override
  String get dssRecordHarvest => 'Record harvest';

  @override
  String dssRecordTitle(String crop) {
    return 'Record harvest: $crop';
  }

  @override
  String get dssRecordSub =>
      'Enter what really happened. Your records make the advice closer to your own farm.';

  @override
  String get dssHarvestedOn => 'Date harvested';

  @override
  String get dssActualYield => 'Total harvest';

  @override
  String get dssSoldPrice => 'Price you sold at';

  @override
  String dssSoldPriceHint(String price) {
    return 'Estimated price: $price per kg';
  }

  @override
  String get dssRecIncome => 'Income';

  @override
  String get dssRecProfit => 'Profit';

  @override
  String get dssRecordSaved =>
      'Harvest saved. The land is free again for your next crop.';

  @override
  String get farmHistoryTitle => 'Harvest history';

  @override
  String get farmHistorySub => 'Your recorded harvests, income and profit.';

  @override
  String get farmHistoryDeleteTitle => 'Delete this record?';

  @override
  String farmHistoryDeleteBody(String crop) {
    return 'The $crop harvest record will be removed.';
  }
}
