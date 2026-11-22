import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/dss_catalog.dart';
import '../core/dss_protection.dart';
import '../core/dss_recommend.dart';
import '../models/farm_store.dart';
import 'dss_planner.dart';

enum StageKind { planting, germination, vegetative, flowering, fruiting, harvest }

/// Isang yugto (o mahalagang petsa) sa kalendaryo ng pananim. Ang [milestone] ay isang petsa lang (pagtatanim, pag-aani).
class CalStage {
  final StageKind kind;
  final DateTime start, end;
  final bool milestone;
  final String nameTl, nameEn, hintTl, hintEn;
  const CalStage(this.kind, this.start, this.end, this.nameTl, this.nameEn, this.hintTl, this.hintEn, {this.milestone = false});
  String name(bool tl) => tl ? nameTl : nameEn;
  String hint(bool tl) => tl ? hintTl : hintEn;

  bool isDone(DateTime now) => now.isAfter(end) && !milestone || (milestone && !now.isBefore(start));
  bool isCurrent(DateTime now) => !milestone && !now.isBefore(start) && !now.isAfter(end);
  double progress(DateTime now) {
    final total = end.difference(start).inHours;
    if (total <= 0) return 1;
    return (now.difference(start).inHours / total).clamp(0.0, 1.0);
  }
}

enum ReminderType { fertilizer, watering, pest, harvest }

/// Ulan sa isang araw mula sa forecast.
class DayRain {
  final num mm, chance;
  const DayRain(this.mm, this.chance);
  bool get wet => mm >= 5 || chance >= 60;
  bool get heavy => mm >= 20;
}

typedef RainMap = Map<DateTime, DayRain>;

/// Pareho ba ang dalawang forecast ng ulan (para hindi mag-reload nang walang dahilan).
bool sameRain(RainMap? a, RainMap? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (final e in a.entries) {
    final o = b[e.key];
    if (o == null || o.mm != e.value.mm || o.chance != e.value.chance) return false;
  }
  return true;
}

class Reminder {
  final String profileId, cropId;
  final ReminderType type;
  final DateTime date;
  final String titleTl, titleEn, detailTl, detailEn;
  final String? wxTl, wxEn; // babala o tala tungkol sa panahon
  final bool wxWarn;
  const Reminder(this.profileId, this.cropId, this.type, this.date, this.titleTl, this.titleEn, this.detailTl, this.detailEn,
      {this.wxTl, this.wxEn, this.wxWarn = false});

  Reminder withWeather(String tl, String en, bool warn) =>
      Reminder(profileId, cropId, type, date, titleTl, titleEn, detailTl, detailEn, wxTl: tl, wxEn: en, wxWarn: warn);

  String? wx(bool tl) => tl ? wxTl : wxEn;

  String title(bool tl) => tl ? titleTl : titleEn;
  String detail(bool tl) => tl ? detailTl : detailEn;
  String get key => '$profileId|${type.name}|${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}

/// Kagustuhan ng farmer: aling uri ng paalala ang gusto at kung may kasamang tala sa panahon.
class ReminderPrefs {
  final Set<ReminderType> types;
  final bool weatherNotes;
  const ReminderPrefs(this.types, this.weatherNotes);
  static ReminderPrefs get all => const ReminderPrefs({...ReminderType.values}, true);
}

class ReminderStore {
  static const _doneKey = 'cal_done_v1';
  static const _typesKey = 'rem_types_v1';
  static const _wxKey = 'rem_wx_v1';

  /// Tumataas kapag nagbago ang kagustuhan o nabura ang mga marka, para mag-refresh ang mga card.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<ReminderPrefs> loadPrefs() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getStringList(_typesKey);
      final types = raw == null ? {...ReminderType.values} : ReminderType.values.where((t) => raw.contains(t.name)).toSet();
      return ReminderPrefs(types, sp.getBool(_wxKey) ?? true);
    } catch (_) {
      return ReminderPrefs.all;
    }
  }

  static Future<void> savePrefs(ReminderPrefs p) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList(_typesKey, p.types.map((e) => e.name).toList());
      await sp.setBool(_wxKey, p.weatherNotes);
      changes.value++;
    } catch (_) {}
  }

  /// Binubura ang lahat ng markang "tapos na".
  static Future<void> clearDone() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_doneKey);
      changes.value++;
    } catch (_) {}
  }

  static Future<Set<String>> loadDone() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return (sp.getStringList(_doneKey) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> setDone(String key, bool done) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = (sp.getStringList(_doneKey) ?? const <String>[]).toSet();
      if (done) {
        s.add(key);
      } else {
        s.remove(key);
      }
      await sp.setStringList(_doneKey, s.toList());
    } catch (_) {}
  }

  /// Kondisyon ng lupa at tubig na pinili sa DSS.
  static Future<(Drainage, WaterSupply)> loadConditions() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final d = sp.getString('dss_drain_v1');
      final w = sp.getString('dss_water_v1');
      return (
      Drainage.values.firstWhere((e) => e.name == d, orElse: () => Drainage.unknown),
      WaterSupply.values.firstWhere((e) => e.name == w, orElse: () => WaterSupply.unknown),
      );
    } catch (_) {
      return (Drainage.unknown, WaterSupply.unknown);
    }
  }
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Awtomatikong kalendaryo ng pananim at mga paalala. Ang hati ng mga yugto ay TANTIYA batay sa karaniwang haba ng paglaki.
class CropCalendar {
  // (yugto, hanggang anong bahagi ng kabuuang araw)
  static const Map<String, List<(StageKind, double)>> _fractions = {
    'Rice': [(StageKind.germination, 0.12), (StageKind.vegetative, 0.45), (StageKind.flowering, 0.70), (StageKind.fruiting, 1.0)],
    'Eggplant': [(StageKind.germination, 0.12), (StageKind.vegetative, 0.40), (StageKind.flowering, 0.55), (StageKind.fruiting, 1.0)],
    'Squash': [(StageKind.germination, 0.10), (StageKind.vegetative, 0.40), (StageKind.flowering, 0.55), (StageKind.fruiting, 1.0)],
    'String beans': [(StageKind.germination, 0.12), (StageKind.vegetative, 0.40), (StageKind.flowering, 0.55), (StageKind.fruiting, 1.0)],
    'Okra': [(StageKind.germination, 0.12), (StageKind.vegetative, 0.40), (StageKind.flowering, 0.50), (StageKind.fruiting, 1.0)],
    'Pechay (Tagalog)': [(StageKind.germination, 0.15), (StageKind.vegetative, 1.0)],
    'Chili (hot)': [(StageKind.germination, 0.12), (StageKind.vegetative, 0.40), (StageKind.flowering, 0.55), (StageKind.fruiting, 1.0)],
    'Chili (long)': [(StageKind.germination, 0.12), (StageKind.vegetative, 0.40), (StageKind.flowering, 0.55), (StageKind.fruiting, 1.0)],
    'Cassava': [(StageKind.germination, 0.10), (StageKind.vegetative, 0.55), (StageKind.fruiting, 1.0)],
    'Coconut': [(StageKind.germination, 0.10), (StageKind.vegetative, 0.60), (StageKind.flowering, 0.80), (StageKind.fruiting, 1.0)],
    'Cacao': [(StageKind.germination, 0.10), (StageKind.vegetative, 0.60), (StageKind.flowering, 0.80), (StageKind.fruiting, 1.0)],
  };

  static (String, String) _name(DssCrop c, StageKind k) {
    switch (k) {
      case StageKind.planting:
        return ('Pagtatanim', 'Planting');
      case StageKind.germination:
        return c.perennial ? ('Pagtatatag ng punla', 'Seedling establishment') : (c.id == 'Rice' ? ('Pagsibol at pagkapit ng punla', 'Seedling and establishment') : ('Pagsibol (germination)', 'Germination'));
      case StageKind.vegetative:
        return ('Paglaki ng dahon at tangkay (vegetative)', 'Vegetative growth');
      case StageKind.flowering:
        return c.id == 'Rice' ? ('Pamumulaklak ng palay', 'Rice flowering') : ('Pamumulaklak (flowering)', 'Flowering');
      case StageKind.fruiting:
        if (c.id == 'Rice') return ('Pagbubuo ng butil at paghinog', 'Grain filling and ripening');
        if (c.id == 'Cassava') return ('Pagbubuo ng ugat (tuber)', 'Tuber bulking');
        return ('Pamumunga (fruiting)', 'Fruiting');
      case StageKind.harvest:
        return ('Inaasahang pag-aani', 'Expected harvest');
    }
  }

  static (String, String) _hint(DssCrop c, StageKind k) {
    switch (k) {
      case StageKind.planting:
        return ('Petsa ng pagtatanim o paglilipat-tanim.', 'Planting or transplanting date.');
      case StageKind.germination:
        return ('Panatilihing mamasa-masa ang lupa. Bantayan ang kuhol, uod at damo.', 'Keep the soil moist. Watch for snails, caterpillars and weeds.');
      case StageKind.vegetative:
        return ('Mabilis ang paglaki. Panahon ng abonong nitrogen at pagdadamo.', 'Fast growth. Time for nitrogen fertilizer and weeding.');
      case StageKind.flowering:
        return ('Iwasan ang kakulangan sa tubig at bantayan ang peste at sakit.', 'Avoid water stress and watch for pests and diseases.');
      case StageKind.fruiting:
        return c.id == 'Rice'
            ? ('Unti-unting huminog ang butil. Bawasan ang tubig bago anihin.', 'Grains fill and ripen. Reduce water before harvest.')
            : ('Bantayan ang peste sa bunga at sundin ang abono ayon sa iskedyul.', 'Watch for fruit pests and follow the fertilizer schedule.');
      case StageKind.harvest:
        return ('Maghanda ng sako, tao at transportasyon bago ang pag-aani.', 'Prepare bags, labor and transport before harvest.');
    }
  }

  /// Mga yugto mula pagtatanim hanggang pag-aani.
  static List<CalStage> stages(DssCrop crop, DateTime plantedOn, {DateTime? harvestOn}) {
    final planted = dayOnly(plantedOn);
    final out = <CalStage>[];
    var n = _name(crop, StageKind.planting), h = _hint(crop, StageKind.planting);
    out.add(CalStage(StageKind.planting, planted, planted, n.$1, n.$2, h.$1, h.$2, milestone: true));

    int total;
    DateTime harvestStart, harvestEnd;
    if (crop.perennial) {
      total = crop.firstHarvestDays ?? 730;
      harvestStart = planted.add(Duration(days: total));
      harvestEnd = harvestStart;
    } else {
      final d = crop.days ?? (100, 120);
      if (harvestOn != null) {
        total = dayOnly(harvestOn).difference(planted).inDays.clamp(1, 3650);
        harvestStart = dayOnly(harvestOn);
        harvestEnd = harvestStart;
      } else {
        total = ((d.$1 + d.$2) / 2).round();
        harvestStart = planted.add(Duration(days: d.$1));
        harvestEnd = planted.add(Duration(days: d.$2));
      }
    }

    final fr = _fractions[crop.id] ?? const [(StageKind.germination, 0.12), (StageKind.vegetative, 0.5), (StageKind.fruiting, 1.0)];
    var prev = 0.0;
    for (final f in fr) {
      final s = planted.add(Duration(days: (total * prev).round()));
      final e = planted.add(Duration(days: (total * f.$2).round()));
      n = _name(crop, f.$1);
      h = _hint(crop, f.$1);
      out.add(CalStage(f.$1, s, e, n.$1, n.$2, h.$1, h.$2));
      prev = f.$2;
    }
    n = _name(crop, StageKind.harvest);
    h = _hint(crop, StageKind.harvest);
    out.add(CalStage(StageKind.harvest, harvestStart, harvestEnd, crop.perennial ? 'Unang ani' : n.$1, crop.perennial ? 'First harvest' : n.$2, h.$1, h.$2, milestone: harvestStart == harvestEnd));
    return out;
  }

  /// Dinadagdagan ng babala o tala tungkol sa ulan ang mga paalala na pasok sa forecast (karaniwang 7 araw).
  static List<Reminder> applyWeather(List<Reminder> items, RainMap rain) {
    if (rain.isEmpty) return items;
    final keys = rain.keys.toList()..sort();
    const mTl = ['Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun', 'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis'];
    const mEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String fmtTl(DateTime d) => '${d.day} ${mTl[d.month - 1]}';
    String fmt(DateTime d) => '${mEn[d.month - 1]} ${d.day}';
    String mmOf(DayRain w) => '${w.mm.round()} mm';

    DateTime? nextDry(DateTime from) {
      for (final k in keys) {
        if (k.isAfter(from) && !(rain[k]!.wet)) return k;
      }
      return null;
    }

    return [
      for (final r in items)
            () {
          final d = dayOnly(r.date);
          final w = rain[d];
          if (w == null) return r; // wala sa forecast
          final prev = rain[d.subtract(const Duration(days: 1))];
          final next = rain[d.add(const Duration(days: 1))];
          switch (r.type) {
            case ReminderType.fertilizer:
              if (w.wet) {
                final dry = nextDry(d);
                return r.withWeather(
                  dry == null
                      ? 'Uulan sa araw na ito (${mmOf(w)}, ${w.chance.round()}%). Ipagpaliban ang abono hanggang tumila ang ulan.'
                      : 'Uulan sa araw na ito (${mmOf(w)}, ${w.chance.round()}%). Maaaring maanod ang abono. Ipagpaliban sa ${fmtTl(dry)}.',
                  dry == null
                      ? 'Rain expected that day (${mmOf(w)}, ${w.chance.round()}%). Postpone the fertilizer until the rain stops.'
                      : 'Rain expected that day (${mmOf(w)}, ${w.chance.round()}%). Fertilizer may wash away. Postpone to ${fmt(dry)}.',
                  true,
                );
              }
              return r.withWeather('Maganda ang panahon para mag-abono (walang inaasahang malakas na ulan).', 'Good weather to fertilize (no heavy rain expected).', false);
            case ReminderType.watering:
              if (w.wet) {
                return r.withWeather('Uulan sa araw na ito (${mmOf(w)}). Maaaring hindi na kailangang magdilig.', 'Rain expected (${mmOf(w)}). You may not need to water.', false);
              }
              return r;
            case ReminderType.pest:
              if (w.heavy || (prev?.heavy ?? false)) {
                return r.withWeather('Malakas ang ulan sa paligid ng araw na ito. Tumataas ang panganib ng sakit. Suriing mabuti ang dahon at bunga.',
                    'Heavy rain around this day raises disease risk. Check leaves and fruit closely.', true);
              }
              return r;
            case ReminderType.harvest:
              if (w.wet || (next?.wet ?? false) || (prev?.wet ?? false)) {
                return r.withWeather('May ulan sa o malapit sa araw na ito. Ihanda ang tuyuan at tarpaulin, at pumili ng tuyong araw sa pag-aani.',
                    'Rain on or near this day. Prepare a drying area and tarpaulin, and pick a dry day to harvest.', true);
              }
              return r.withWeather('Maganda ang panahon sa araw na ito para sa pag-aani.', 'Good weather for harvesting on this day.', false);
          }
        }(),
    ];
  }

  /// Mga paalala (abono, pagdidilig, pagbabantay sa peste, pag-aani) mula [pastDays] araw nakaraan hanggang [ahead] araw sa hinaharap.
  static List<Reminder> reminders(
      FarmProfile p, {
        required DateTime now,
        required Drainage drain,
        required WaterSupply water,
        int pastDays = 3,
        int ahead = 14,
      }) {
    final crop = dssCropFor(p.crop);
    if (crop == null) return const [];
    final today = dayOnly(now);
    final from = today.subtract(Duration(days: pastDays));
    final to = today.add(Duration(days: ahead));
    bool inWin(DateTime d) => !d.isBefore(from) && !d.isAfter(to);
    final planted = dayOnly(p.plantedOn);
    final plan = DssPlan.build(crop: crop, soil: p.soil, areaHa: p.areaHa, plantedOn: planted, harvestOn: p.harvestOn);
    final out = <Reminder>[];

    // Abono
    for (final a in plan.fert) {
      if (a.date == null) continue;
      final d = dayOnly(a.date!);
      if (!inWin(d)) continue;
      final qty = '${fertName(a.product, true)}: ${a.bags.toStringAsFixed(a.bags >= 10 ? 0 : 1)} sako';
      final qtyEn = '${fertName(a.product, false)}: ${a.bags.toStringAsFixed(a.bags >= 10 ? 0 : 1)} bags';
      out.add(Reminder(p.id, p.crop, ReminderType.fertilizer, d, 'Mag-abono sa ${crop.nameTl}', 'Fertilize ${crop.nameEn}', '$qty. ${a.noteTl}', '$qtyEn. ${a.noteEn}'));
    }

    // Petsa ng pag-aani
    final DateTime? harvestStart = crop.perennial ? (plan.bearing ? null : plan.firstHarvest) : plan.harvestFrom ?? plan.harvestMid;
    final stop = crop.perennial ? null : dayOnly(plan.harvestMid ?? plan.harvestFrom ?? planted.add(const Duration(days: 100)));
    if (harvestStart != null) {
      final hs = p.harvestOn != null && !crop.perennial ? dayOnly(p.harvestOn!) : dayOnly(harvestStart);
      final prep = hs.subtract(const Duration(days: 7));
      if (inWin(prep)) {
        out.add(Reminder(p.id, p.crop, ReminderType.harvest, prep, 'Maghanda sa pag-aani ng ${crop.nameTl}', 'Prepare to harvest ${crop.nameEn}',
            'Isang linggo na lang. Ihanda ang sako, tao at hahakutan. Bantayan ang panahon.', 'One week to go. Prepare bags, labor and transport. Watch the weather.'));
      }
      if (inWin(hs)) {
        out.add(Reminder(p.id, p.crop, ReminderType.harvest, hs, 'Simula ng pag-aani: ${crop.nameTl}', 'Harvest starts: ${crop.nameEn}',
            'Maaari nang anihin. Suriin muna ang kondisyon ng ani.', 'Ready to harvest. Check the crop condition first.'));
      }
    }

    // Pagdidilig
    final young = today.difference(planted).inDays < 365;
    int? every;
    String wTl = 'Diligan ang tanim.', wEn = 'Water the crop.';
    if (crop.id == 'Rice') {
      every = 7;
      wTl = 'Suriin ang lalim ng tubig sa palayan (mga 2-5 cm). Bawasan bago anihin.';
      wEn = 'Check the water depth in the paddy (about 2-5 cm). Reduce before harvest.';
    } else if (crop.perennial) {
      every = young ? 5 : null;
      wTl = 'Diligan ang batang puno, lalo na kapag walang ulan.';
      wEn = 'Water young trees, especially when there is no rain.';
    } else if (crop.id == 'Cassava') {
      every = today.difference(planted).inDays <= 30 ? 5 : null;
      wTl = 'Diligan ang bagong tanim na kamoteng kahoy kung walang ulan.';
      wEn = 'Water newly planted cassava if there is no rain.';
    } else {
      every = drain == Drainage.fast ? 2 : 3;
      wTl = water == WaterSupply.irrigated
          ? 'Diligan ang tanim (umaga o hapon).'
          : 'Diligan kung walang ulan nitong mga huling araw (umaga o hapon).';
      wEn = water == WaterSupply.irrigated ? 'Water the crop (morning or late afternoon).' : 'Water if there has been no rain lately (morning or late afternoon).';
    }
    if (every != null) {
      final endW = stop == null ? to : stop.subtract(const Duration(days: 7));
      for (var d = planted.add(Duration(days: every)); !d.isAfter(endW) && !d.isAfter(to); d = d.add(Duration(days: every))) {
        if (inWin(d)) out.add(Reminder(p.id, p.crop, ReminderType.watering, d, 'Pagdidilig: ${crop.nameTl}', 'Watering: ${crop.nameEn}', wTl, wEn));
      }
    }

    // Pagbabantay sa peste (lingguhan; dalawang linggo kung pangmatagalan)
    final step = crop.perennial ? 14 : 7;
    final threats = kThreats[crop.id] ?? const <Threat>[];
    final top = threats.isEmpty ? '' : threats.take(2).map((t) => t.nameTl.split(' (').first).join(', ');
    final topEn = threats.isEmpty ? '' : threats.take(2).map((t) => t.nameEn).join(', ');
    final endP = stop ?? to;
    for (var d = planted.add(Duration(days: step)); !d.isAfter(endP) && !d.isAfter(to); d = d.add(Duration(days: step))) {
      if (inWin(d)) {
        out.add(Reminder(p.id, p.crop, ReminderType.pest, d, 'Suriin ang bukid: ${crop.nameTl}', 'Scout the field: ${crop.nameEn}',
            top.isEmpty ? 'Maglakad sa bukid at tingnan ang dahon at bunga.' : 'Bantayan ang: $top. Suriin ang ilang halaman sa iba-ibang bahagi.',
            topEn.isEmpty ? 'Walk the field and check leaves and fruit.' : 'Watch for: $topEn. Check plants in several spots.'));
      }
    }

    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }
}