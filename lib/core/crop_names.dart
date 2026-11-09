import '../l10n/app_localizations.dart';
import 'crop_info.dart';
import 'crop_l10n.dart';

/// Ang 11 orihinal na pananim ay may sariling pangalan at teksto sa ARB (crop_l10n.dart).
/// Ang mga bagong pananim ay kinukuha ang pangalan, paglalarawan at payo sa crop_info.dart.
const Set<String> _legacyCrops = {
  'Rice', 'Eggplant', 'Tomato', 'String beans', 'Coconut', 'Ampalaya', 'Squash', 'Sweet potato', 'Taro', 'Calamansi',
};

bool _useInfo(String id) => !_legacyCrops.contains(id) && cropInfoFor(id) != null;

String cropNameT(AppLocalizations t, String id) =>
    _useInfo(id) ? cropInfoFor(id)!.name(t.localeName == 'tl') : t.cropLabel(id);

String cropAboutT(AppLocalizations t, String id) =>
    _useInfo(id) ? cropInfoFor(id)!.desc(t.localeName == 'tl') : t.cropAbout(id);

String cropTipT(AppLocalizations t, String id) =>
    _useInfo(id) ? cropInfoFor(id)!.tips(t.localeName == 'tl').first : t.cropTip(id);