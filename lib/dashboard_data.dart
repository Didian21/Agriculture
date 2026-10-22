// Barrel file: keeps `import 'dashboard_data.dart'` working everywhere.
// The real code now lives in core/, models/, services/ and providers/.

export 'core/localization.dart';
export 'models/app_notification.dart';
export 'models/farm_advice.dart';
export 'models/farm_models.dart';
export 'models/planting_guide.dart';
export 'models/price_prediction.dart';
export 'models/weather_models.dart';
export 'providers/dashboard_provider.dart';
export 'services/advice_service.dart';
export 'services/farmer_repository.dart';
export 'services/notification_service.dart';
export 'services/price_prediction_service.dart';
export 'services/weather_service.dart';
