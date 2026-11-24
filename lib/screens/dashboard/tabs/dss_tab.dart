import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/dss_catalog.dart';
import '../../../core/dss_recommend.dart';
import '../../../core/tr.dart';
import '../../../dashboard_data.dart';
import '../../../main.dart';
import '../../../models/farm_store.dart';
import '../../../models/farmer.dart' hide FarmRecord;
import '../../../services/account_service.dart';
import '../../../services/crop_calendar.dart';
import '../../../services/dss_planner.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/crop_calendar_card.dart';
import '../../../widgets/crop_photo.dart';
import '../../../widgets/crop_recommend_card.dart';
import '../../../core/price_card.dart';
import '../../../widgets/protection_cards.dart';
import '../farm_shape_editor.dart';

/// DSS: inilalagay ng farmer ang lawak ng lupa, uri ng lupa, pananim at petsa. Pumipili lang, hindi nagta-type ng marami.
/// Resulta: abono, pestisidyo, gastos, ani at kita. Lahat ay tantiya at gabay lamang.
class DssTab extends StatefulWidget {
  final DashboardProvider p;
  const DssTab({super.key, required this.p});

  @override
  State<DssTab> createState() => _DssTabState();
}

class _DssTabState extends State<DssTab> {
  final _store = FarmStore.instance;
  final _areaC = TextEditingController();
  final _priceC = TextEditingController();

  bool _sqm = false;
  SoilType? _soil;
  Drainage _drain = Drainage.unknown;
  WaterSupply _water = WaterSupply.unknown;
  String? _crop;
  DateTime _planted = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _harvestOn;
  double? _price;
  String? _editingId; // id ng tanim na ine-edit (null = bagong tanim)
  int _view = 0; // 0 = Planuhin, 1 = Resulta
  int _step = 0; // aktibong hakbang sa Planuhin
  int _rtab = 0; // aktibong tab sa Resulta
  bool _allocOpen = false;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _heroKey = GlobalKey();

  /// Bumalik sa itaas ng pahina (para makita agad ang resulta o ang susunod na hakbang).
  void _top() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Sa Resulta, magsisimula ang view sa pananim (hindi sa pinaka-itaas ng pahina).
      final ctx = _view == 1 ? _heroKey.currentContext : null;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      } else if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  final List<GlobalKey> _stepKeys = List.generate(6, (_) => GlobalKey());
  // Nasagot na ba ang kondisyon ng lupa at tubig? (kasama ang "Hindi ko alam")
  bool _drainOk = false, _waterOk = false;
  // Nasagot na ba ang petsa ng pagtatanim? (tinatanggap kapag pinindot ang petsa o ang Susunod)
  bool _dateOk = false;
  // Mga sariling numero ng farmer sa gastos (pamalit sa tantiya ng katalogo).
  // Mga susi: seeds, pesticide, labor, other, bags_<abono>, price_<abono>
  final Map<String, double> _costOv = {};
  bool _costDirty = false;
  int _costTick = 0;
  // Totoo kung ang uri ng lupa ay itinakda ng admin sa rehistrasyon ng farmer.
  bool _soilFromAdmin = false;

  /// Hanapin ang susunod na hakbang na kulang sa datos (hindi pa naisasagawa).
  int _nextMissing([int startFrom = 0]) {
    bool missing(int s) {
      switch (s) {
        case 0:
          return _areaHa == null;
        case 1:
          return _soil == null; // hinihintay ang uri ng lupa mula sa admin
        case 2:
          return !_drainOk;
        case 3:
          return !_waterOk;
        case 4:
          return !_dateOk;
        case 5:
          return _crop == null;
      }
      return false;
    }

    for (var s = startFrom; s < 6; s++) {
      if (missing(s)) return s;
    }
    for (var s = 0; s < startFrom && s < 6; s++) {
      if (missing(s)) return s;
    }
    return 5; // pananim (huli)
  }

  /// Lumipat sa hakbang at i-scroll ito sa view para hindi na mag-scroll ang farmer.
  void _go(int step) {
    setState(() => _step = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _stepKeys[step].currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      } else if (_scroll.hasClients) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
    _loadConditions();
    _store.load().then((_) {
      if (!mounted) return;
      final p = _store.profile;
      if (p != null) {
        setState(() {
          _loadProfile(p);
          _view = 1;
        });
      }
    });
  }

  Future<void> _loadConditions() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final d = sp.getString('dss_drain_v1');
      final w = sp.getString('dss_water_v1');
      if (!mounted) return;
      setState(() {
        _drain = Drainage.values.firstWhere((e) => e.name == d, orElse: () => Drainage.unknown);
        _water = WaterSupply.values.firstWhere((e) => e.name == w, orElse: () => WaterSupply.unknown);
        _drainOk = d != null;
        _waterOk = w != null;
      });
    } catch (_) {}
  }

  Future<void> _saveConditions() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('dss_drain_v1', _drain.name);
      await sp.setString('dss_water_v1', _water.name);
    } catch (_) {}
  }

  CostOverride? get _ov {
    if (_costOv.isEmpty) return null;
    final bags = <FertProduct, double>{};
    final price = <FertProduct, double>{};
    for (final f in FertProduct.values) {
      final b = _costOv['bags_${f.name}'];
      if (b != null) bags[f] = b;
      final r = _costOv['price_${f.name}'];
      if (r != null) price[f] = r;
    }
    return CostOverride(
      seeds: _costOv['seeds'],
      pesticide: _costOv['pesticide'],
      labor: _costOv['labor'],
      other: _costOv['other'],
      bags: bags,
      price: price,
    );
  }

  void _setCost(String key, double? v) {
    setState(() {
      if (v == null) {
        _costOv.remove(key);
      } else {
        _costOv[key] = v;
      }
      _costDirty = true;
    });
  }

  void _resetCosts() {
    setState(() {
      _costOv.clear();
      _costDirty = true;
      _costTick++;
    });
  }

  Future<void> _loadCostOv(String id) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString('dss_costov_$id');
      if (raw == null || !mounted || _editingId != id) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _costOv
          ..clear()
          ..addAll({for (final e in m.entries) e.key: (e.value as num).toDouble()});
        _costDirty = false;
        _costTick++;
      });
    } catch (_) {}
  }

  Future<void> _saveCostOv(String id) async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (_costOv.isEmpty) {
        await sp.remove('dss_costov_$id');
      } else {
        await sp.setString('dss_costov_$id', jsonEncode(_costOv));
      }
    } catch (_) {}
  }

  void _loadProfile(FarmProfile p) {
    _editingId = p.id;
    _costOv.clear();
    _costDirty = false;
    _costTick++;
    _loadCostOv(p.id);
    _soil = p.soil;
    _crop = p.crop;
    _planted = p.plantedOn;
    _dateOk = true;
    _harvestOn = null; // awtomatiko at hindi na binabago ang petsa ng ani
    _price = p.price;
    _sqm = false;
    _areaC.text = _fmtNum(p.areaHa);
    _priceC.text = p.price == null ? '' : _fmtNum(p.price!);
  }

  /// Magsimula ng bagong tanim (ang uri ng lupa ay iniiwan para mas mabilis).
  void _newEntry() {
    setState(() {
      _editingId = null;
      _crop = null;
      _costOv.clear();
      _costDirty = false;
      _costTick++;
      _harvestOn = null;
      _dateOk = false;
      _price = null;
      _priceC.clear();
      _areaC.clear();
      _sqm = false;
      _view = 0;
      _step = _nextMissing(0);
      final n = DateTime.now();
      _planted = DateTime(n.year, n.month, n.day);
    });
  }

  Future<void> _delete(FarmProfile p) async {
    final tl = isTl(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Tanggalin ang tanim?', 'Remove this crop?')),
        content: Text(dssCropName(p.crop, tl)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ctx, 'Huwag', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(ctx, 'Tanggalin', 'Remove'))),
        ],
      ),
    );
    if (ok != true) return;
    await _store.removeProfile(p.id);
    if (!mounted) return;
    setState(() {
      if (_editingId == p.id) {
        final next = _store.profile;
        if (next != null) {
          _loadProfile(next);
        } else {
          _newEntry();
        }
      }
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    _areaC.dispose();
    _priceC.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static String _fmtNum(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double? get _areaHa {
    final v = double.tryParse(_areaC.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return _sqm ? v / 10000 : v;
  }

  DssPlan? get _plan {
    final c = _crop == null ? null : dssCropFor(_crop!);
    final a = _areaHa;
    if (c == null || _soil == null || a == null) return null;
    return DssPlan.build(crop: c, soil: _soil!, areaHa: a, plantedOn: _planted, harvestOn: _harvestOn, userPrice: _price, costOv: _ov);
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Petsa ng pagtatanim: mula ngayon hanggang isang taon pa lang.
  Future<void> _pickPlanted() async {
    final today = _today();
    final d = await showDatePicker(
      context: context,
      initialDate: _planted.isBefore(today) ? today : _planted,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: tr(context, 'Kailan magtatanim?', 'When will you plant?'),
    );
    if (d != null) {
      setState(() {
        _planted = d;
        _dateOk = true;
        _crop = null; // kailangang suriin ulit ang pananim para sa bagong petsa
        _costOv.clear();
        _costTick++;
      });
      _go(_nextMissing(5));
    }
  }

  void _setPlantedIn(int days) {
    setState(() {
      _planted = _today().add(Duration(days: days));
      _dateOk = true;
      _crop = null;
      _costOv.clear();
      _costTick++;
    });
    _go(_nextMissing(5));
  }

  /// Uri ng lupa na itinakda ng admin para sa bukid ng farmer (Supabase). Null kung wala pa.
  SoilType? _registeredSoil(BuildContext context) {
    final accountService = Provider.of<AccountService>(context);
    final username = widget.p.currentUsername ?? '';
    final key = username.trim().toLowerCase();
    final farmer = accountService.farmers.firstWhere(
          (f) => f.username.trim().toLowerCase() == key || f.profileName.trim().toLowerCase() == key || f.contactNumber == username,
      orElse: () => Farmer(id: '', username: username, password: '', profileName: username, barangay: ''),
    );
    final dynamic farm = accountService.farms.cast<dynamic>().firstWhere(
          (f) =>
      f != null &&
          (f.farmerId == farmer.id ||
              (f.farmerName != null && f.farmerName.trim().isNotEmpty && f.farmerName.trim().toLowerCase() == farmer.profileName.trim().toLowerCase()) ||
              (f.farmerName != null && f.farmerName.trim().isNotEmpty && f.farmerName.trim().toLowerCase() == farmer.username.trim().toLowerCase())),
      orElse: () => null,
    );
    if (farm == null) return null;
    dynamic raw;
    for (final read in <dynamic Function()>[() => farm.soilType, () => farm.soil, () => farm.soilTypeName]) {
      try {
        raw = read();
      } catch (_) {
        raw = null;
      }
      if (raw != null) break;
    }
    return _parseSoil(raw);
  }

  static SoilType? _parseSoil(dynamic raw) {
    if (raw == null) return null;
    if (raw is SoilType) return raw == SoilType.unknown ? null : raw;
    final t = raw.toString().trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (t.isEmpty) return null;
    if (t.contains('clayloam') || t.contains('clay loam') || t.contains('malagkit na mabuhaghag')) return SoilType.clayLoam;
    if (t.contains('sandyloam') || t.contains('sandy loam') || t.contains('mabuhangin na mabuhaghag')) return SoilType.sandyLoam;
    if (t.contains('clay') || t.contains('luwad')) return SoilType.clay;
    if (t.contains('sandy') || t.contains('mabuhangin')) return SoilType.sandy;
    if (t.contains('loam') || t.contains('mabuhaghag')) return SoilType.loam;
    return null;
  }

  // Totoo kung ang kabuuang lupa ay galing sa rehistrasyon ng account (Supabase).
  bool _fromRegistration = false;

  /// Sukat ng lupa (ha) na nakarehistro sa account ng farmer. Null kung wala.
  double? _registeredHectares(BuildContext context) {
    final accountService = Provider.of<AccountService>(context);
    final username = widget.p.currentUsername ?? '';
    final key = username.trim().toLowerCase();
    final farmer = accountService.farmers.firstWhere(
          (f) => f.username.trim().toLowerCase() == key || f.profileName.trim().toLowerCase() == key || f.contactNumber == username,
      orElse: () => Farmer(id: '', username: username, password: '', profileName: username, barangay: ''),
    );
    final dynamic farm = accountService.farms.cast<dynamic>().firstWhere(
          (f) =>
      f != null &&
          (f.farmerId == farmer.id ||
              (f.farmerName != null && f.farmerName.trim().isNotEmpty && f.farmerName.trim().toLowerCase() == farmer.profileName.trim().toLowerCase()) ||
              (f.farmerName != null && f.farmerName.trim().isNotEmpty && f.farmerName.trim().toLowerCase() == farmer.username.trim().toLowerCase())),
      orElse: () => null,
    );
    if (farm == null || farm.landAreaHectares == null) return null;
    final v = (farm.landAreaHectares as num).toDouble();
    return v > 0 ? v : null;
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FarmShapeEditor()));
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final a = _areaHa;
    if (_crop == null || _soil == null || a == null) return;
    final id = _editingId ?? DateTime.now().microsecondsSinceEpoch.toString();
    await _store.saveProfile(FarmProfile(id: id, crop: _crop!, soil: _soil!, areaHa: a, plantedOn: _planted, harvestOn: _harvestOn, price: _price));
    if (!mounted) return;
    setState(() => _editingId = id);
    await _saveCostOv(id);
    if (mounted) setState(() => _costDirty = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr(context, 'Na-save ang tanim. Makikita na ito sa Home at Aking Bukid.', 'Crop saved. You can now see it in Home and My Farm.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    final plan = _plan;
    final adminSoil = _registeredSoil(context);
    _soilFromAdmin = adminSoil != null;
    if (adminSoil != null) _soil = adminSoil;
    final registeredHa = _registeredHectares(context);
    _fromRegistration = registeredHa != null;
    final total = registeredHa ?? _store.totalHa;
    final others = _store.usedHa(exceptId: _editingId);
    final avail = total == null ? null : total - others;
    final areaNow = _areaHa;
    final tooBig = total != null && areaNow != null && others + areaNow > total * 1.02;

    final list = AnimatedTabList(controller: _scroll, items: [
      TabHeader(
        title: 'DSS',
        subtitle: tr(context, 'Planuhin ang tanim: pananim, abono, gastos at kita', 'Plan your crop: crop, fertilizer, cost and income'),
      ),
      const SizedBox(height: 12),

      // Mga tanim (siksik)
      _farmStrip(context, total),
      const SizedBox(height: 12),

      // Planuhin / Resulta
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, icon: const Icon(Icons.edit_note_rounded), label: Text(tr(context, 'Planuhin', 'Plan'))),
            ButtonSegment(value: 1, icon: const Icon(Icons.analytics_rounded), label: Text(tr(context, 'Resulta', 'Results'))),
          ],
          selected: {_view},
          onSelectionChanged: (s) {
            if (s.first == 1 && plan == null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(tr(context, 'Ilagay muna ang lawak, uri ng lupa at pananim.', 'Enter the land size, soil type and crop first.')),
              ));
              return;
            }
            setState(() => _view = s.first);
            _top();
          },
        ),
      ),
      const SizedBox(height: 12),

      if (_view == 0) ...[
        // 1. Lawak
        _WizStep(
          key: _stepKeys[0],
          number: 1,
          title: tr(context, 'Lawak para sa tanim na ito', 'Land for this crop'),
          summary: areaNow == null ? tr(context, 'Ilagay ang lawak', 'Enter the size') : '${_fmtNum(areaNow)} ha',
          done: areaNow != null,
          active: _step == 0,
          onTap: () => _go(0),
          onNext: () => _go(_nextMissing(1)),
          nextEnabled: areaNow != null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _areaC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_areaHa != null) _go(_nextMissing(1));
                  },
                  decoration: InputDecoration(
                    hintText: _sqm ? tr(context, 'hal. 5000', 'e.g. 5000') : tr(context, 'hal. 1.5', 'e.g. 1.5'),
                    suffixText: _sqm ? 'm²' : 'ha',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [ButtonSegment(value: false, label: Text('ha')), ButtonSegment(value: true, label: Text('m²'))],
                selected: {_sqm},
                onSelectionChanged: (s) {
                  final a = _areaHa;
                  setState(() {
                    _sqm = s.first;
                    if (a != null) _areaC.text = _fmtNum(_sqm ? a * 10000 : a);
                  });
                },
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 4, children: [
              if (total != null && others > 0 && avail! > 0.005)
                ActionChip(
                  avatar: const Icon(Icons.straighten_rounded, size: 16),
                  label: Text(tr(context, 'Gamitin ang natitirang lupa (${avail.toStringAsFixed(2)} ha)', 'Use remaining land (${avail.toStringAsFixed(2)} ha)')),
                  onPressed: () {
                    setState(() {
                      _areaC.text = _sqm ? _fmtNum(avail * 10000) : avail.toStringAsFixed(2);
                    });
                    _go(_nextMissing(1));
                  },
                )
              else if (total != null && others == 0)
                ActionChip(
                  avatar: const Icon(Icons.straighten_rounded, size: 16),
                  label: Text(tr(context, 'Gamitin ang kabuuang lupa (${total.toStringAsFixed(2)} ha)', 'Use all the land (${total.toStringAsFixed(2)} ha)')),
                  onPressed: () {
                    setState(() {
                      _areaC.text = _sqm ? _fmtNum(total * 10000) : total.toStringAsFixed(2);
                    });
                    _go(_nextMissing(1));
                  },
                ),
              ActionChip(
                avatar: const Icon(Icons.edit_location_alt_rounded, size: 16),
                label: Text(_store.isCustom
                    ? tr(context, 'Baguhin ang pwesto ng taniman', 'Edit planting location plot')
                    : tr(context, 'Iguhit ang pwesto kung saan magtatanim', 'Draw planting location plot on map')),
                onPressed: _openEditor,
              ),
            ]),
            if (tooBig)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  tr(context, 'Lampas ito sa kabuuang lupa (${total.toStringAsFixed(2)} ha), kasama ang iba pang tanim.',
                      'This is more than your total land (${total.toStringAsFixed(2)} ha), counting your other crops.'),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFC0792E), fontWeight: FontWeight.w700, height: 1.3),
                ),
              ),
            Text(
              tr(context, 'Ang pwesto ng tanim na iginuhit ay makikita sa Aking Bukid.', 'The planting location plot drawn on the map appears in My Farm.'),
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
            ),
          ]),
        ),
        // 2. Uri at Kondisyon ng Lupa (Soil Condition & Technician Assessed Option)
        _WizStep(
          key: _stepKeys[1],
          number: 2,
          title: tr(context, 'Uri at Kondisyon ng Lupa', 'Soil Type & Condition'),
          summary: _soil == null
              ? tr(context, 'Pumili ng uri ng lupa', 'Choose soil type')
              : (_soilFromAdmin ? '🔬 Verified by Technician: ${soilName(_soil!, tl)}' : soilName(_soil!, tl)),
          done: _soil != null,
          active: _step == 1,
          onTap: () => _go(1),
          onBack: () => _go(0),
          onNext: () => _go(_nextMissing(2)),
          nextEnabled: _soil != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context,
                    'Pumili ng uri o kondisyon ng lupa ng inyong bukid, o gamitin ang nasuri ng Agricultural Technician:',
                    'Choose the soil type or condition of your farm, or use the assessment from the Agricultural Technician:'),
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),

              // OPTION A: TECHNICIAN FIELD INSPECTION VERIFIED SOIL TYPE (IF AVAILABLE)
              Builder(builder: (ctx) {
                final adminSoil = _registeredSoil(ctx);
                if (adminSoil == null) return const SizedBox.shrink();

                final isSel = _soil == adminSoil && _soilFromAdmin;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: isSel ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _soil = adminSoil;
                          _soilFromAdmin = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? const Color(0xFF16A34A) : const Color(0xFFBFDBFE), width: isSel ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tl ? '🔬 Galing sa Technician (Field Visit): ${soilName(adminSoil, tl)}' : '🔬 Verified by Technician: ${soilName(adminSoil, tl)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF15803D)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tr(ctx, 'Uri ng lupa na nasuri at ibinigay ng MAO Agricultural Technician sa kaniyang Field Inspection Visit.', 'Soil type assessed and set by the MAO Agricultural Technician during field inspection visit.'),
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel) const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // OPTION B: MANUAL CHOICES (CLAY LOAM, SANDY LOAM, CLAY SOIL, LOAM SOIL, SILTY CLAY, SANDY SOIL)
              ...[
                {
                  'type': SoilType.clayLoam,
                  'icon': '🧱',
                  'titleTl': 'Clay Loam Soil (Lupang Malagkit na Mabuhaghag)',
                  'titleEn': 'Clay Loam Soil',
                  'descTl': 'Matagal mag-imbak ng tubig at sustansya, napakamainam para sa Palay at Gulay.',
                  'descEn': 'Retains water and nutrients well, highly suitable for Rice and Vegetables.',
                },
                {
                  'type': SoilType.sandyLoam,
                  'icon': '🌧️',
                  'titleTl': 'Sandy Loam Soil (Lupang Buhangin na Mabuhaghag)',
                  'titleEn': 'Sandy Loam Soil',
                  'descTl': 'Mabilis patuyuin at maganda ang bentilasyon, angkop sa Mais at Gulay.',
                  'descEn': 'Well-drained with good aeration, ideal for Corn and Vegetables.',
                },
                {
                  'type': SoilType.clay,
                  'icon': '⚪',
                  'titleTl': 'Clay Soil (Lupang Luwad / Malagkit)',
                  'titleEn': 'Clay Soil',
                  'descTl': 'Napakalagkit kapag basa, matagal humawi ang tubig; napakamainam sa Palay.',
                  'descEn': 'Very sticky when wet, holds water well; best suited for Paddy Rice.',
                },
                {
                  'type': SoilType.loam,
                  'icon': '🪴',
                  'titleTl': 'Loam Soil (Lupang Mabuhaghag)',
                  'titleEn': 'Loam Soil',
                  'descTl': 'Pinakamainam at balanseng uri ng lupa para sa halos lahat ng pananim.',
                  'descEn': 'Best balanced soil type with optimal organic matter for most crops.',
                },
                {
                  'type': SoilType.sandyLoam,
                  'icon': '🍂',
                  'titleTl': 'Silty Clay Soil (Lupang Pula na Luwad / Silt)',
                  'titleEn': 'Silty Clay Soil',
                  'descTl': 'Mataas ang sustansya at maayos na nagpapanatili ng moist sa halaman.',
                  'descEn': 'Rich in fine silt particles with high moisture retention capacity.',
                },
                {
                  'type': SoilType.sandy,
                  'icon': '🌾',
                  'titleTl': 'Sandy Soil (Lupang Buhangin)',
                  'titleEn': 'Sandy Soil',
                  'descTl': 'Mabilis patuyuin ang tubig, mainam para sa mga ugat na gulay at pakwan.',
                  'descEn': 'Drains water quickly, ideal for root crops and melons.',
                },
              ].map((opt) {
                final st = opt['type'] as SoilType;
                final isSel = _soil == st && !_soilFromAdmin;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSel ? const Color(0xFFE0F2FE) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _soil = st;
                          _soilFromAdmin = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? const Color(0xFF0284C7) : Colors.grey.shade300, width: isSel ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Text(opt['icon'] as String, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tl ? (opt['titleTl'] as String) : (opt['titleEn'] as String),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSel ? const Color(0xFF0369A1) : Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tl ? (opt['descTl'] as String) : (opt['descEn'] as String),
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel) const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        // 3. Kondisyon ng lupa (agos ng tubig)
        _WizStep(
          key: _stepKeys[2],
          number: 3,
          title: tr(context, 'Kondisyon ng lupa', 'Soil condition'),
          summary: _drainOk ? drainName(_drain, tl) : tr(context, 'Pumili ng kondisyon ng lupa', 'Choose the soil condition'),
          done: _drainOk,
          active: _step == 2,
          onTap: () => _go(2),
          onBack: () => _go(1),
          onNext: () => _go(_nextMissing(3)),
          nextEnabled: _drainOk,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(context, 'Paano umaagos ang tubig sa lupa?', 'How does water drain in the soil?'),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final d in kDrainOrder)
                ChoiceChip(
                  label: Text(drainName(d, tl)),
                  selected: _drainOk && _drain == d,
                  selectedColor: AppColors.leaf.withValues(alpha: 0.2),
                  onSelected: (_) {
                    setState(() {
                      _drain = d;
                      _drainOk = true;
                    });
                    _saveConditions();
                    _go(_nextMissing(3));
                  },
                ),
            ]),
            if (drainHint(_drain, tl).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(drainHint(_drain, tl), style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35)),
            ],
          ]),
        ),
        // 4. Kondisyon ng tubig (suplay)
        _WizStep(
          key: _stepKeys[3],
          number: 4,
          title: tr(context, 'Suplay ng tubig', 'Water supply'),
          summary: _waterOk ? waterName(_water, tl) : tr(context, 'Pumili ng suplay ng tubig', 'Choose the water supply'),
          done: _waterOk,
          active: _step == 3,
          onTap: () => _go(3),
          onBack: () => _go(2),
          onNext: () => _go(_nextMissing(4)),
          nextEnabled: _waterOk,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(context, 'Saan galing ang tubig ng inyong tanim?', 'Where does your crop get its water?'),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final w in kWaterOrder)
                ChoiceChip(
                  label: Text(waterName(w, tl)),
                  selected: _waterOk && _water == w,
                  selectedColor: AppColors.leaf.withValues(alpha: 0.2),
                  onSelected: (_) {
                    setState(() {
                      _water = w;
                      _waterOk = true;
                    });
                    _saveConditions();
                    _go(_nextMissing(4));
                  },
                ),
            ]),
          ]),
        ),
        // 5. Petsa ng pagtatanim (mula ngayon pataas)
        _WizStep(
          key: _stepKeys[4],
          number: 5,
          title: tr(context, 'Petsa ng pagtatanim', 'Planting date'),
          summary: _dateOk ? DateFormat.yMMMd(locale).format(_planted) : tr(context, 'Pumili ng petsa', 'Choose a date'),
          done: _dateOk,
          active: _step == 4,
          onTap: () => _go(4),
          onBack: () => _go(3),
          onNext: () {
            setState(() => _dateOk = true);
            _go(_nextMissing(5));
          },
          nextEnabled: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(context, 'Kailan ninyo balak magtanim?', 'When do you plan to plant?'),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              ActionChip(label: Text(tr(context, 'Ngayon', 'Today')), onPressed: () => _setPlantedIn(0)),
              ActionChip(label: Text(tr(context, 'Sa 1 linggo', 'In 1 week')), onPressed: () => _setPlantedIn(7)),
              ActionChip(label: Text(tr(context, 'Sa 2 linggo', 'In 2 weeks')), onPressed: () => _setPlantedIn(14)),
              ActionChip(label: Text(tr(context, 'Sa 1 buwan', 'In 1 month')), onPressed: () => _setPlantedIn(30)),
              ActionChip(label: Text(tr(context, 'Sa 2 buwan', 'In 2 months')), onPressed: () => _setPlantedIn(60)),
              ActionChip(label: Text(tr(context, 'Sa 3 buwan', 'In 3 months')), onPressed: () => _setPlantedIn(90)),
            ]),
            const SizedBox(height: 10),
            _DateRow(
              label: tr(context, 'Petsa ng pagtatanim', 'Planting date'),
              value: DateFormat.yMMMd(locale).format(_planted),
              hint: tr(context, 'Pindutin para pumili ng ibang petsa (mula ngayon hanggang isang taon).', 'Tap to pick another date (from today up to one year).'),
              onTap: _pickPlanted,
            ),
            const SizedBox(height: 8),
            Text(
              tr(context, 'Pagkatapos nito, susuriin ng system ang angkop na pananim para sa buwang ito (agroclimatic) bago magmungkahi. Ang petsa ng ani ay awtomatiko at hindi na mababago.',
                  'After this, the system checks which crops suit this month (agroclimatic) before recommending. The harvest date is automatic and cannot be changed.'),
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.35),
            ),
          ]),
        ),
        // 6. Pananim (Mungkahi): huli, pagkatapos ng lupa, tubig, at petsa (agroclimatic)
        _WizStep(
          key: _stepKeys[5],
          number: 6,
          title: tr(context, 'Pumili ng pananim', 'Choose a crop'),
          summary: _crop == null ? tr(context, 'Tingnan ang mungkahi', 'See recommendations') : dssCropName(_crop!, tl),
          done: _crop != null,
          active: _step == 5,
          onTap: () {
            final miss = _nextMissing(0);
            if (miss != 5) {
              _go(miss);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(tr(context, 'Sagutan muna ang mga naunang hakbang.', 'Please answer the earlier steps first.')),
              ));
              return;
            }
            _go(5);
          },
          onBack: () => _go(4),
          onNext: () {
            if (plan == null) {
              _go(_nextMissing(0));
              return;
            }
            setState(() => _view = 1);
            _top();
          },
          nextLabel: tr(context, 'Tingnan ang resulta', 'See results'),
          nextEnabled: _crop != null,
          bare: _soil != null && _nextMissing(0) == 5,
          child: (_soil == null || _nextMissing(0) != 5)
              ? Text(tr(context, 'Sagutan muna ang lawak, lupa (mula sa admin), kondisyon, tubig, at petsa para lumabas ang Mungkahi ng Pananim.', 'Answer the size, soil (from the admin), conditions, water and date first to see Crop Recommendations.'),
              style: const TextStyle(fontSize: 12, color: AppColors.muted))
              : CropRecommendCard(
            soil: _soil!,
            drain: _drain,
            water: _water,
            areaHa: areaNow,
            plantedOn: _planted,
            selected: _crop,
            onPick: (id) {
              setState(() {
                _crop = id;
                _harvestOn = null;
                _costOv.clear();
                _costTick++;
              });
              if (_plan != null) {
                setState(() => _view = 1);
              }
              _top();
            },
          ),
        ),
      ] else if (plan == null)
        const _EmptyResult()
      else ...[
          KeyedSubtree(key: _heroKey, child: _resultHero(context, plan, tl, locale)),
          const SizedBox(height: 12),
          _resultPanel(context, plan, tl, locale),
        ],
      const SizedBox(height: 24),
    ]);
    return Column(children: [
      Expanded(child: list),
      if (plan != null) _saveBar(context, plan),
    ]);
  }

  // ----- Siksik na listahan ng mga tanim -----
  Widget _farmStrip(BuildContext context, double? total) {
    final tl = isTl(context);
    final used = _store.usedHa();
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.agriculture_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(tr(context, 'Aking mga tanim', 'My crops'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900))),
          Text(
            total == null ? '${used.toStringAsFixed(2)} ha' : '${used.toStringAsFixed(2)} / ${total.toStringAsFixed(2)} ha',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final pr in _store.profiles)
            InputChip(
              label: Text('${dssCropName(pr.crop, tl)} · ${_fmtNum(pr.areaHa)} ha'),
              selected: pr.id == _editingId,
              selectedColor: AppColors.leaf.withValues(alpha: 0.2),
              showCheckmark: false,
              onPressed: () {
                setState(() {
                  _loadProfile(pr);
                  _view = 1;
                });
                _top();
              },
              onDeleted: () => _delete(pr),
            ),
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 18),
            label: Text(tr(context, 'Bagong tanim', 'New crop')),
            onPressed: () {
              _newEntry();
              _top();
            },
          ),
        ]),
        if (_store.hasProfile)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _allocOpen = !_allocOpen),
              icon: Icon(_allocOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
              label: Text(tr(context, 'Paghahati ng lupa at kabuuang kita', 'Land split and total income')),
            ),
          ),
        if (_allocOpen) ...[
          _AllocationCard(store: _store, total: total, fromRegistration: _fromRegistration),
          const SizedBox(height: 12),
          if (_store.hasProfile)
            _MyCropsCard(
              profiles: _store.profiles,
              editingId: _editingId,
              polyHa: total ?? 0,
              onPick: (pr) {
                setState(() {
                  _loadProfile(pr);
                  _view = 1;
                });
                _top();
              },
              onDelete: _delete,
              onAdd: _newEntry,
            ),
        ],
      ]),
    );
  }

  // ----- Pangunahing card ng resulta: pananim, lawak, lupa, petsa at I-save -----
  Widget _resultHero(BuildContext context, DssPlan plan, bool tl, String locale) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: CropPhoto(cropId: plan.crop.id, emojiSize: 30)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(context, 'Resulta para sa', 'Results for'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
              Text(tl ? plan.crop.nameTl : plan.crop.nameEn,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(
                '${_fmtNum(plan.areaHa)} ha · ${soilName(plan.soil, tl)}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
              Text(
                tr(context, 'Itanim: ${DateFormat.yMMMd(locale).format(_planted)}', 'Planting: ${DateFormat.yMMMd(locale).format(_planted)}'),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              Text(
                plan.perennial
                    ? (plan.bearing
                    ? tr(context, 'Namumunga na', 'Already bearing')
                    : tr(context, 'Unang ani: ~${DateFormat.yMMM(locale).format(plan.firstHarvest!)}', 'First harvest: ~${DateFormat.yMMM(locale).format(plan.firstHarvest!)}'))
                    : (plan.harvestMid == null
                    ? ''
                    : tr(context, 'Inaasahang ani: ${DateFormat.yMMMd(locale).format(plan.harvestMid!)}', 'Expected harvest: ${DateFormat.yMMMd(locale).format(plan.harvestMid!)}')),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.leaf),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _view = 0;
              _step = 4;
            });
            _top();
          },
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: Text(tr(context, 'Baguhin ang pagpili', 'Change inputs')),
        ),
      ]),
    );
  }

  // ----- Mga chip ng resulta -----
  List<(IconData, String)> _tabItems(BuildContext context) => [
    (Icons.dashboard_rounded, tr(context, 'Buod', 'Summary')),
    (Icons.calendar_month_rounded, tr(context, 'Kalendaryo', 'Calendar')),
    (Icons.grass_rounded, tr(context, 'Abono', 'Fertilizer')),
    (Icons.bug_report_rounded, tr(context, 'Peste', 'Pests')),
    (Icons.receipt_long_rounded, tr(context, 'Gastos', 'Cost')),
    (Icons.sell_rounded, tr(context, 'Presyo', 'Price')),
  ];

  /// Mga tab na parang folder: berdeng guhit lang sa itaas ang may kulay. Ang napiling tab ay kapareho ng kulay
  /// ng nilalaman sa ilalim at magkadikit sila, kaya iisang piraso.
  Widget _resultPanel(BuildContext context, DssPlan plan, bool tl, String locale) {
    final items = _tabItems(context);
    const c = AppColors.leaf; // iisang kulay (berde) para sa lahat ng tab
    final panelBg = Color.alphaBlend(AppColors.leaf.withValues(alpha: 0.05), Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x141B5E20), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        // Hanay ng tab
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _rtab = i);
                    _top();
                  },
                  child: Container(
                    height: 54,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: _rtab == i ? panelBg : Colors.white.withValues(alpha: 0.14),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(items[i].$1, size: 20, color: _rtab == i ? c : Colors.white),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[i].$2,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: _rtab == i ? FontWeight.w900 : FontWeight.w700,
                            color: _rtab == i ? c : Colors.white,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        // Nilalaman (magkadikit sa napiling tab)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 2),
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _resultBody(context, plan, tl, locale)),
        ),
      ]),
    );
  }

  bool _isDirty(DssPlan plan) {
    FarmProfile? saved;
    for (final x in _store.profiles) {
      if (x.id == _editingId) saved = x;
    }
    if (saved == null) return true;
    if (_costDirty) return true;
    bool sameDay(DateTime? a, DateTime? b) => (a == null || b == null) ? a == b : dayOnly(a) == dayOnly(b);
    return saved.crop != plan.crop.id ||
        saved.soil != plan.soil ||
        (saved.areaHa - plan.areaHa).abs() > 1e-6 ||
        !sameDay(saved.plantedOn, _planted) ||
        !sameDay(saved.harvestOn, _harvestOn) ||
        saved.price != _price;
  }

  /// Buton na laging nasa ibaba ng DSS (sa lahat ng tab ng Resulta).
  Widget _saveBar(BuildContext context, DssPlan plan) {
    final saved = _editingId != null && _store.profiles.any((x) => x.id == _editingId);
    final dirty = _isDirty(plan);
    final label = !saved
        ? tr(context, 'I-save ang tanim na ito', 'Save this crop')
        : dirty
        ? tr(context, 'I-update ang tanim na ito', 'Update this crop')
        : tr(context, 'Naka-save na', 'Saved');
    final icon = !saved ? Icons.bookmark_add_rounded : (dirty ? Icons.sync_rounded : Icons.check_circle_rounded);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: dirty ? _save : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.leaf,
            disabledBackgroundColor: AppColors.leaf.withValues(alpha: 0.15),
            disabledForegroundColor: AppColors.leaf,
          ),
          icon: Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ),
    );
  }

  List<Widget> _resultBody(BuildContext context, DssPlan plan, bool tl, String locale) {
    switch (_rtab) {
      case 1:
        return [
          CropCalendarCard(
            rain: widget.p.weather == null
                ? null
                : {for (final d in widget.p.weather!.daily) dayOnly(d.date): DayRain(d.rainMm, d.rainChance)},
            profile: FarmProfile(
              id: _editingId ?? 'draft',
              crop: plan.crop.id,
              soil: plan.soil,
              areaHa: plan.areaHa,
              plantedOn: _planted,
              harvestOn: _harvestOn,
              price: _price,
            ),
          ),
          const SizedBox(height: 12),
        ];
      case 2:
        return [FertilizerAdviceCard(plan: plan, drain: _drain, water: _water), const SizedBox(height: 12)];
      case 3:
        return [PestAdviceCard(plan: plan), const SizedBox(height: 12), const SafetyCard(), const SizedBox(height: 12)];
      case 4:
        return [
          _CostInputs(
            plan: plan,
            base: DssPlan.build(crop: plan.crop, soil: plan.soil, areaHa: plan.areaHa, plantedOn: plan.plantedOn, harvestOn: _harvestOn, userPrice: _price),
            ov: _costOv,
            tick: _costTick,
            onChange: _setCost,
            onReset: _resetCosts,
          ),
          const SizedBox(height: 12),
        ];
      case 5:
        return [
          PriceAdviceCard(
            cropId: plan.crop.id,
            cropNameTl: plan.crop.nameTl,
            cropNameEn: plan.crop.nameEn,
            harvestMonth: plan.harvestMid?.month,
            usedPrice: _price,
            onUse: (v) => setState(() {
              _price = v;
              _priceC.text = _fmtNum(v);
            }),
          ),
          const SizedBox(height: 12),
        ];
      default:
        return _results(context, plan, tl, locale);
    }
  }

  List<Widget> _results(BuildContext context, DssPlan plan, bool tl, String locale) {
    final nf = NumberFormat.decimalPattern(locale);
    String peso(double v) => '${v < 0 ? '-' : ''}₱${nf.format(v.abs().round())}';
    final unit = plan.unit == 'pc' ? tr(context, 'niyog', 'nuts') : 'kg';
    final perYear = plan.perennial ? tr(context, ' bawat taon', ' per year') : '';

    return [
      // Buod
      Row(children: [
        Expanded(
          child: _Metric(
            icon: Icons.scale_rounded,
            color: AppColors.leaf,
            label: tr(context, 'Inaasahang ani$perYear', 'Expected yield$perYear'),
            value: '${nf.format(plan.yMid.round())} $unit',
            sub: '${nf.format(plan.yLow.round())} - ${nf.format(plan.yHigh.round())}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            icon: Icons.payments_rounded,
            color: const Color(0xFFC0792E),
            label: tr(context, 'Gastos$perYear', 'Cost$perYear'),
            value: peso(plan.totalCost),
            sub: tr(context, 'Tantiya', 'Estimate'),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: _Metric(
            icon: Icons.trending_up_rounded,
            color: AppColors.rain,
            label: tr(context, 'Posibleng kita$perYear', 'Possible income$perYear'),
            value: peso(plan.incMid),
            sub: '${peso(plan.incLow)} - ${peso(plan.incHigh)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            icon: Icons.savings_rounded,
            color: plan.netMid >= 0 ? AppColors.leaf : Colors.redAccent,
            label: tr(context, 'Tubo$perYear', 'Net profit$perYear'),
            value: peso(plan.netMid),
            sub: '${peso(plan.netLow)} - ${peso(plan.netHigh)}',
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Presyo
      GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr(context, 'Presyong ginamit sa kuwenta', 'Price used in the calculation'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.muted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _priceC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState(() => _price = double.tryParse(v.trim().replaceAll(',', '.'))),
                decoration: InputDecoration(
                  hintText: plan.price.toStringAsFixed(2),
                  prefixText: '₱ ',
                  suffixText: plan.unit == 'pc' ? tr(context, '/piraso', '/piece') : '/kg',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (_price != null)
              IconButton(
                tooltip: tr(context, 'Ibalik sa awtomatiko', 'Reset to automatic'),
                onPressed: () => setState(() {
                  _price = null;
                  _priceC.clear();
                }),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
          ]),
          const SizedBox(height: 6),
          Text(
            plan.priceFromUser
                ? tr(context, 'Presyong inilagay ninyo.', 'Price entered by you.')
                : plan.priceReal
                ? tr(context, 'Presyo sa bukid mula sa Tanggapan ng Pambayang Agrikultura para sa buwan ng ani.', 'Farmgate price from the Municipal Agriculture Office for the harvest month.')
                : (tl ? plan.crop.priceNoteTl : plan.crop.priceNoteEn).isNotEmpty
                ? (tl ? plan.crop.priceNoteTl : plan.crop.priceNoteEn)
                : tr(context, 'Karaniwang presyo (tantiya). Ilagay ang presyo sa inyong lugar.', 'Typical price (estimate). Enter the price in your area.'),
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Angkop ba?
      _FitCard(plan: plan),
    ];
  }
}

// ---------------------------------------------------------------------------

const _kAllocColors = [
  Color(0xFF4C9F70),
  Color(0xFFE0A100),
  Color(0xFF2E86C1),
  Color(0xFFC0792E),
  Color(0xFF8E6BBF),
  Color(0xFFD35400),
  Color(0xFF1ABC9C),
  Color(0xFF7F8C8D),
];

/// Paghahati ng lupa: ilang ektarya ang para sa bawat tanim, at kung ilan ang natitira.
class _AllocationCard extends StatelessWidget {
  final FarmStore store;
  final double? total; // kabuuang lupa (ha): mula sa rehistrasyon ng account
  final bool fromRegistration;
  const _AllocationCard({required this.store, required this.total, required this.fromRegistration});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final total = this.total; // lokal na kopya para ma-promote bilang hindi null
    final profiles = store.profiles;
    final used = store.usedHa();
    final base = total == null ? used : (used > total ? used : total);
    final left = total == null ? null : total - used;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pie_chart_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr(context, 'Paghahati ng lupa', 'Land allocation'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          tr(context, 'Hatiin ang inyong lupa sa mga pananim, halimbawa 1 ha sa palay at 0.5 ha sa talong.',
              'Split your land among crops, for example 1 ha for rice and 0.5 ha for eggplant.'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Icon(fromRegistration ? Icons.verified_user_rounded : Icons.map_rounded, size: 18, color: AppColors.leaf),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              total == null
                  ? tr(context, 'Wala pang nakarehistrong sukat ng lupa sa inyong account.', 'No land size is registered on your account yet.')
                  : fromRegistration
                  ? tr(context, 'Kabuuang lupa: ${total.toStringAsFixed(2)} ha (ayon sa rehistrasyon ng account)', 'Total land: ${total.toStringAsFixed(2)} ha (from your account registration)')
                  : tr(context, 'Kabuuang lupa: ${total.toStringAsFixed(2)} ha (mula sa iginuhit na pwesto)', 'Total land: ${total.toStringAsFixed(2)} ha (from the drawn plot)'),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            tr(context, 'Ang sukat ng lupa ay binabago sa account o sa MAO, hindi sa app na ito.', 'The land size is changed on the account or with the MAO, not in this app.'),
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 12),
        if (profiles.isEmpty)
          Text(tr(context, 'Wala pang naka-save na tanim. I-save ang una sa ibaba.', 'No saved crops yet. Save your first one below.'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted))
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(children: [
                for (var i = 0; i < profiles.length; i++)
                  if (profiles[i].areaHa > 0)
                    Expanded(
                      flex: (profiles[i].areaHa / base * 1000).round().clamp(1, 1000),
                      child: Container(color: _kAllocColors[i % _kAllocColors.length]),
                    ),
                if (left != null && left > 0.0005)
                  Expanded(flex: (left / base * 1000).round().clamp(1, 1000), child: Container(color: AppColors.border)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < profiles.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: _kAllocColors[i % _kAllocColors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(dssCropName(profiles[i].crop, tl), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                Text(
                  '${profiles[i].areaHa.toStringAsFixed(2)} ha${total != null && total > 0 ? ' · ${(profiles[i].areaHa / total * 100).round()}%' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ]),
            ),
          if (left != null) ...[
            const Divider(height: 18),
            Row(children: [
              Expanded(
                child: Text(
                  left >= -0.005 ? tr(context, 'Natitirang lupa', 'Land left') : tr(context, 'Lampas sa lupa', 'Over the land'),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${left.abs().toStringAsFixed(2)} ha',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: left >= -0.005 ? AppColors.leaf : Colors.redAccent),
              ),
            ]),
          ],
        ],
      ]),
    );
  }
}

class _MyCropsCard extends StatelessWidget {
  final List<FarmProfile> profiles;
  final String? editingId;
  final double polyHa; // 0 kung walang iginuhit na hugis
  final ValueChanged<FarmProfile> onPick;
  final ValueChanged<FarmProfile> onDelete;
  final VoidCallback onAdd;
  const _MyCropsCard({
    required this.profiles,
    required this.editingId,
    required this.polyHa,
    required this.onPick,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    final nf = NumberFormat.decimalPattern(locale);
    String peso(double v) => '${v < 0 ? '-' : ''}₱${nf.format(v.abs().round())}';

    var area = 0.0, cost = 0.0, income = 0.0;
    for (final p in profiles) {
      final c = dssCropFor(p.crop);
      area += p.areaHa;
      if (c != null && p.areaHa > 0) {
        final pl = DssPlan.build(crop: c, soil: p.soil, areaHa: p.areaHa, plantedOn: p.plantedOn, harvestOn: p.harvestOn, userPrice: p.price);
        cost += pl.totalCost;
        income += pl.incMid;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.agriculture_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(tr(context, 'Mga tanim ko (${profiles.length})', 'My crops (${profiles.length})'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 10),
        for (final p in profiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onPick(p),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                decoration: BoxDecoration(
                  color: p.id == editingId ? AppColors.leaf.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.id == editingId ? AppColors.leaf : AppColors.border, width: p.id == editingId ? 2 : 1),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 44, height: 44, child: CropPhoto(cropId: p.crop, emojiSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(dssCropName(p.crop, tl), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      Text(
                        '${p.areaHa.toStringAsFixed(2)} ha · ${soilName(p.soil, tl)} · ${DateFormat.MMMd(locale).format(p.plantedOn)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                      ),
                    ]),
                  ),
                  IconButton(
                    tooltip: tr(context, 'Tanggalin', 'Remove'),
                    onPressed: () => onDelete(p),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ]),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(tr(context, 'Magdagdag ng tanim', 'Add a crop')),
          ),
        ),
        if (profiles.length > 1) ...[
          const Divider(height: 22),
          Text(tr(context, 'Kabuuan ng lahat ng tanim', 'Total of all crops'),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
          const SizedBox(height: 6),
          _TotalRow(tr(context, 'Lawak', 'Area'), '${area.toStringAsFixed(2)} ha${polyHa > 0 ? ' / ${polyHa.toStringAsFixed(2)} ha' : ''}'),
          _TotalRow(tr(context, 'Gastos', 'Cost'), peso(cost)),
          _TotalRow(tr(context, 'Posibleng kita', 'Possible income'), peso(income)),
          _TotalRow(tr(context, 'Tubo', 'Net profit'), peso(income - cost), bold: true, color: income - cost >= 0 ? AppColors.leaf : Colors.redAccent),
          const SizedBox(height: 4),
          Text(
            tr(context, 'Pinagsama ang bawat tanim. Magkakaiba ang haba ng panahon ng bawat isa (ang niyog at kakaw ay taunan).',
                'Combined from each crop. Each crop has a different growing time (coconut and cacao are yearly).'),
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.3),
          ),
        ],
      ]),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _TotalRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w900 : FontWeight.w600))),
        Text(value, style: TextStyle(fontSize: bold ? 15 : 13.5, fontWeight: FontWeight.w900, color: color ?? AppColors.ink)),
      ]),
    );
  }
}

class _WizStep extends StatelessWidget {
  final int number;
  final String title, summary;
  final bool done, active, nextEnabled, bare;
  final VoidCallback onTap;
  final VoidCallback? onBack, onNext;
  final String? nextLabel;
  final Widget child;
  const _WizStep({
    super.key,
    required this.number,
    required this.title,
    required this.summary,
    required this.done,
    required this.active,
    required this.onTap,
    required this.child,
    this.onBack,
    this.onNext,
    this.nextEnabled = true,
    this.nextLabel,
    this.bare = false,
  });

  Widget _badge() => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: done && !active ? AppColors.leaf.withValues(alpha: 0.85) : AppColors.leaf, shape: BoxShape.circle),
    child: done && !active
        ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
        : Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5)),
  );

  Widget _buttons(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(children: [
      if (onBack != null)
        OutlinedButton(onPressed: onBack, child: Text(tr(context, 'Bumalik', 'Back'))),
      if (onBack != null) const SizedBox(width: 10),
      Expanded(
        child: FilledButton(
          onPressed: nextEnabled ? onNext : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
          child: Text(nextLabel ?? tr(context, 'Susunod', 'Next')),
        ),
      ),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                _badge(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    const SizedBox(height: 1),
                    Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ]),
                ),
                const Icon(Icons.edit_rounded, size: 18, color: AppColors.muted),
              ]),
            ),
          ),
        ),
      );
    }
    if (bare) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Row(children: [
              _badge(),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
            ]),
          ),
          child,
          _buttons(context),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _badge(),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink))),
          ]),
          const SizedBox(height: 12),
          child,
          _buttons(context),
        ]),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label, value;
  final String? hint;
  final VoidCallback? onTap;
  const _DateRow({required this.label, required this.value, this.hint, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(onTap != null ? Icons.event_rounded : Icons.event_available_rounded, size: 20, color: AppColors.leaf),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
              if (hint != null) Text(hint!, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
            ]),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        const Icon(Icons.touch_app_rounded, color: AppColors.leaf, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tr(context, 'Ilagay ang lawak, pumili ng uri ng lupa at pananim. Lalabas dito ang payo sa abono at peste, gastos, ani at kita.',
                'Enter the size, then choose a soil type and crop. Fertilizer and pest advice, cost, yield and income will appear here.'),
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
          ),
        ),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value, sub;
  const _Metric({required this.icon, required this.color, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(label, maxLines: 2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.muted, height: 1.15))),
        ]),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, height: 1.1)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ),
      ]),
    );
  }
}

Color _suitColor(Suit s) {
  switch (s) {
    case Suit.good:
      return AppColors.leaf;
    case Suit.fair:
      return const Color(0xFFD9A400);
    case Suit.poor:
      return Colors.redAccent;
    case Suit.unknown:
      return AppColors.muted;
  }
}

class _FitCard extends StatelessWidget {
  final DssPlan plan;
  const _FitCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final locale = Localizations.localeOf(context).languageCode;
    String soilLabel() {
      switch (plan.soilFit) {
        case Suit.good:
          return tr(context, 'Angkop ang lupa', 'Soil is suitable');
        case Suit.fair:
          return tr(context, 'Puwede ang lupa', 'Soil is acceptable');
        case Suit.poor:
          return tr(context, 'Hindi gaanong angkop ang lupa', 'Soil is not well suited');
        case Suit.unknown:
          return tr(context, 'Hindi alam ang lupa', 'Soil unknown');
      }
    }

    String seasonLabel() {
      final m = DateFormat.MMMM(locale).format(plan.plantedOn);
      switch (plan.seasonFit) {
        case Suit.good:
          return tr(context, 'Magandang buwan ng pagtatanim ($m)', 'Good planting month ($m)');
        case Suit.fair:
          return tr(context, 'Puwede pang magtanim ($m)', 'Possible planting month ($m)');
        case Suit.poor:
          return tr(context, 'Hindi ito panahon ng pagtatanim ($m)', 'Off-season planting month ($m)');
        case Suit.unknown:
          return '';
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.fact_check_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Text(tr(context, 'Angkop ba ang pananim?', 'Is the crop a good fit?'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          Pill(soilLabel(), _suitColor(plan.soilFit), icon: Icons.layers_rounded),
          if (plan.seasonFit != Suit.unknown) Pill(seasonLabel(), _suitColor(plan.seasonFit), icon: Icons.calendar_month_rounded),
        ]),
        const SizedBox(height: 10),
        Text(plan.soilAdvice(tl), style: const TextStyle(fontSize: 12.5, height: 1.4)),
      ]),
    );
  }
}

/// Gastos bilang INPUT: panimulang tantiya mula sa katalogo na puwedeng palitan ng farmer ng aktwal niyang gastos.
/// Ang kabuuang gastos, kita, at tubo ay awtomatikong nagbabago.
class _CostInputs extends StatefulWidget {
  final DssPlan plan; // kasama ang mga pagbabago ng farmer
  final DssPlan base; // tantiya lang (walang pagbabago)
  final Map<String, double> ov;
  final int tick; // tumataas kapag kailangang i-reset ang mga laman ng input
  final void Function(String key, double? value) onChange;
  final VoidCallback onReset;
  const _CostInputs({required this.plan, required this.base, required this.ov, required this.tick, required this.onChange, required this.onReset});

  @override
  State<_CostInputs> createState() => _CostInputsState();
}

class _CostInputsState extends State<_CostInputs> {
  final Map<String, TextEditingController> _c = {};
  String _sig = '';

  String get _signature => '${widget.base.crop.id}|${widget.base.areaHa.toStringAsFixed(4)}|${widget.tick}';

  static String _fmt(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

  Map<String, double> get _defaults {
    final area = widget.base.areaHa;
    final c = widget.base.crop.cost;
    final d = <String, double>{
      'seeds': c.seeds * area,
      'pesticide': c.pesticide * area,
      'labor': c.labor * area,
      'other': c.other * area,
    };
    for (final e in _fertTotals.entries) {
      d['bags_${e.key.name}'] = e.value;
      d['price_${e.key.name}'] = kFertPrice[e.key] ?? 0;
    }
    return d;
  }

  Map<FertProduct, double> get _fertTotals {
    final t = <FertProduct, double>{};
    for (final a in widget.base.fert) {
      t[a.product] = (t[a.product] ?? 0) + a.bags;
    }
    return t;
  }

  void _rebuild() {
    for (final c in _c.values) {
      c.dispose();
    }
    _c.clear();
    final d = _defaults;
    for (final e in d.entries) {
      _c[e.key] = TextEditingController(text: _fmt(widget.ov[e.key] ?? e.value));
    }
    _sig = _signature;
  }

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant _CostInputs old) {
    super.didUpdateWidget(old);
    if (_sig != _signature) _rebuild();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _edit(String key, String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    widget.onChange(key, (text.trim().isEmpty || v == null || v < 0) ? null : v);
  }

  Widget _field(BuildContext context, String key, String label, {String? prefix, String? suffix}) {
    final d = _defaults[key] ?? 0;
    final locale = Localizations.localeOf(context).languageCode;
    final nf = NumberFormat.decimalPattern(locale);
    final edited = widget.ov.containsKey(key);
    return TextField(
      controller: _c[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (t) => _edit(key, t),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        helperText: edited
            ? tr(context, 'Binago. Tantiya: ${prefix ?? ''}${nf.format(d.round())}', 'Changed. Estimate: ${prefix ?? ''}${nf.format(d.round())}')
            : tr(context, 'Tantiya: ${prefix ?? ''}${nf.format(d.round())}', 'Estimate: ${prefix ?? ''}${nf.format(d.round())}'),
        helperStyle: TextStyle(fontSize: 11, color: edited ? AppColors.leaf : AppColors.muted, fontWeight: edited ? FontWeight.w800 : FontWeight.w500),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Map<String, String> _getPesticideDetailsForCrop(DssCrop crop, bool tl) {
    final cropId = crop.id.toLowerCase();
    final cropName = crop.name(tl);

    if (cropId.contains('rice') || cropId.contains('palay')) {
      return {
        'name': 'FPA Chlorantraniliprole / Botanical Neem Extract',
        'target': tl ? 'Laban sa Rice Stem Borer, Leaf Folder, at Brown Planthopper' : 'Target: Rice Stem Borer, Leaf Folder, & Brown Planthopper',
        'rate': tl ? '₱1,800.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,800.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('eggplant') || cropId.contains('talong')) {
      return {
        'name': 'FPA Cartap Hydrochloride / Emamectin Benzoate',
        'target': tl ? 'Laban sa Eggplant Fruit & Shoot Borer (FSB) at Thrips' : 'Target: Eggplant Fruit & Shoot Borer (FSB) & Thrips',
        'rate': tl ? '₱2,500.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱2,500.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('squash') || cropId.contains('kalabasa')) {
      return {
        'name': 'FPA Copper Hydroxide & Botanical Insecticidal Soap',
        'target': tl ? 'Laban sa Squash Beetle, Aphids, at Powdery Mildew' : 'Target: Squash Beetle, Aphids, & Powdery Mildew',
        'rate': tl ? '₱1,500.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,500.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('string') || cropId.contains('sitaw') || cropId.contains('bean')) {
      return {
        'name': 'FPA Deltamethrin / Botanical Insecticidal Spray',
        'target': tl ? 'Laban sa Pod Borer, Aphids, at Bean Fly' : 'Target: Pod Borer, Aphids, & Bean Fly',
        'rate': tl ? '₱1,600.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,600.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('okra')) {
      return {
        'name': 'FPA Malathion & Biological Neem Extract Spray',
        'target': tl ? 'Laban sa Stink Bug, Cotton Stainer, at Root-Knot Nematodes' : 'Target: Stink Bug, Cotton Stainer, & Root-Knot Nematodes',
        'rate': tl ? '₱1,400.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,400.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('pechay')) {
      return {
        'name': 'FPA Bacillus Thuringiensis (BT) & Neem Extract',
        'target': tl ? 'Laban sa Diamondback Moth, Flea Beetle, at Leafminer' : 'Target: Diamondback Moth, Flea Beetle, & Leafminer',
        'rate': tl ? '₱1,300.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,300.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('chili') || cropId.contains('sili')) {
      return {
        'name': 'FPA Imidacloprid / Lambda-Cyhalothrin & Sulfur Spray',
        'target': tl ? 'Laban sa Chili Thrips, Mites, Fruit Fly, at Anthracnose' : 'Target: Chili Thrips, Mites, Fruit Fly, & Anthracnose',
        'rate': tl ? '₱2,100.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱2,100.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('coconut') || cropId.contains('niyog')) {
      return {
        'name': 'FPA Approved Biological Pest Control & Metarhizium Fungus',
        'target': tl ? 'Laban sa Coconut Scale Insect (CSI) at Rhinoceros Beetle (Uwang)' : 'Target: Coconut Scale Insect (CSI) & Rhinoceros Beetle (Uwang)',
        'rate': tl ? '₱1,500.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,500.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('cacao') || cropId.contains('kakaw')) {
      return {
        'name': 'FPA Copper Oxychloride & Botanical Spray',
        'target': tl ? 'Laban sa Cacao Pod Borer, Black Pod Rot, at Helopeltis' : 'Target: Cacao Pod Borer, Black Pod Rot, & Helopeltis',
        'rate': tl ? '₱1,900.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,900.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else if (cropId.contains('cassava') || cropId.contains('kamoteng kahoy') || cropId.contains('balinghoy')) {
      return {
        'name': 'FPA Approved Mealybug Biocontrol & Potassium Soap Spray',
        'target': tl ? 'Laban sa Cassava Mealybug, Spider Mites, at Bacterial Blight' : 'Target: Cassava Mealybug, Spider Mites, & Bacterial Blight',
        'rate': tl ? '₱1,100.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,100.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    } else {
      return {
        'name': 'FPA Approved General Crop Protection Spray ($cropName)',
        'target': tl ? 'Laban sa karaniwang insect pests at fungal diseases ng $cropName' : 'Target: Common insect pests & fungal diseases of $cropName',
        'rate': tl ? '₱1,500.00 / ektarya (FPA Laguna Retail Survey 2026)' : '₱1,500.00 / hectare (FPA Laguna Retail Survey 2026)',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final tl = isTl(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final nf = NumberFormat.decimalPattern(locale);
    String peso(double v) => '${v < 0 ? '-' : ''}₱${nf.format(v.abs().round())}';
    final plan = widget.plan;
    final area = plan.areaHa.toStringAsFixed(2);
    final fertTotals = _fertTotals;
    final extra = plan.costs.length > 5 ? plan.costs.sublist(5) : const <CostLine>[];
    final fertAmount = plan.costs.isEmpty ? 0.0 : plan.costs.first.amount;
    final net = plan.netMid;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_rounded, color: AppColors.leaf, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              plan.perennial ? tr(context, 'Gastos bawat taon (ilagay ang aktwal)', 'Cost per year (enter your actual)') : tr(context, 'Gastos sa produksyon (ilagay ang aktwal)', 'Production cost (enter your actual)'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          tr(context, 'Panimulang tantiya ang nasa mga kahon para sa $area ha. Palitan ito ng aktwal ninyong gastos at awtomatikong magbabago ang kabuuan, kita, at tubo.',
              'The boxes start with an estimate for $area ha. Replace it with your actual costs and the total, income and profit update automatically.'),
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 14),

        // FPA LAGUNA OFFICIAL BENCHMARK SECTION (FERTILIZER & PESTICIDES - MAGKASUNOD AT NON-EDITABLE)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        tr(context, 'FPA Laguna Official Benchmark Rates', 'FPA Laguna Official Benchmark Rates'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('FPA Laguna Verified', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 1. FERTILIZER (ABONO)
              Text(tr(context, '🧪 Abono / Fertilizer (FPA Laguna Rates)', '🧪 Fertilizer (FPA Laguna Rates)'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              for (final e in fertTotals.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('• ${fertName(e.key, tl)} (${_fmt(e.value)} sako @ ${peso(kFertPrice[e.key] ?? 0)}/sako)', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                      Text(peso((e.value) * (kFertPrice[e.key] ?? 0)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr(context, 'Kabuuang Abono:', 'Total Fertilizer:'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  Text(peso(fertAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                ],
              ),

              const Divider(height: 18, color: Color(0xFFBBF7D0)),

              // 2. PESTICIDE (PESTISIDYO - MAGKASUNOD SA FERTILIZER WITH CROP DETAILED PRODUCT INFO & ACCURATE TOTAL)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr(context, '🐛 Pestisidyo at Pamatay-peste (FPA Laguna Rate):', '🐛 Pesticides (FPA Laguna Rate):'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      Text(peso(widget.base.crop.cost.pesticide * plan.areaHa), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Builder(builder: (ctx) {
                    final pInfo = _getPesticideDetailsForCrop(plan.crop, tl);
                    final pestRatePerHa = widget.base.crop.cost.pesticide;
                    final totalPestCost = pestRatePerHa * plan.areaHa;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• Product: ${pInfo['name']}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ),
                              Text(
                                peso(totalPestCost),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '  ${pInfo['target']}',
                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tl
                                ? '  Kuwenta: ₱${nf.format(pestRatePerHa.round())}/ha × ${plan.areaHa.toStringAsFixed(2)} ha = ${peso(totalPestCost)}'
                                : '  Calculation: ₱${nf.format(pestRatePerHa.round())}/ha × ${plan.areaHa.toStringAsFixed(2)} ha = ${peso(totalPestCost)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // CUSTOMIZABLE / EDITABLE INPUTS SECTION (BINHI, LABOR, OTHERS)
        Text(
          tr(context, '⚙️ Baguhin ang Iba pang Gastos (kabuuan para sa $area ha)', '⚙️ Customize Other Costs (total for $area ha)'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          tr(context, 'I-type ang inyong aktwal na gastos sa Binhi, Lakas-paggawa, at Iba pa para awtomatikong mag-recalculate ang kabuuang tubo at kita.',
              'Type your actual costs for Seeds, Labor, and Others to automatically recalculate profit and net income.'),
          style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
        ),
        const SizedBox(height: 12),

        if (_c.containsKey('seeds')) ...[
          _field(context, 'seeds', tr(context, '🌱 Binhi / Pantanim', '🌱 Seeds / Planting Material'), prefix: '₱'),
          const SizedBox(height: 10),
          _field(context, 'labor', tr(context, '👨‍🌾 Lakas-paggawa at Pag-aararo', '👨‍🌾 Labor & Land Preparation'), prefix: '₱'),
          const SizedBox(height: 10),
          _field(context, 'other', tr(context, '📦 Iba pa (Patubig, Hakot, Upa, Fuel, atbp.)', '📦 Others (Irrigation, Hauling, Fuel, Rentals, etc.)'), prefix: '₱'),
        ],
        for (final l in extra)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              Expanded(child: Text(l.label(tl), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
              Text(peso(l.amount), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
            ]),
          ),
        const Divider(height: 24),

        // Buod na awtomatikong nagbabago
        _sumRow(context, tr(context, 'Kabuuang gastos', 'Total cost'), peso(plan.totalCost), strong: true),
        _sumRow(context, tr(context, 'Posibleng kita (katamtaman)', 'Possible income (typical)'), peso(plan.incMid)),
        _sumRow(context, tr(context, 'Tubo (katamtaman)', 'Profit (typical)'), peso(net), strong: true, color: net >= 0 ? AppColors.leaf : const Color(0xFFC0503E)),
        if (widget.ov.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onReset,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(tr(context, 'Ibalik sa tantiya', 'Reset to estimate')),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _sumRow(BuildContext context, String label, String value, {bool strong = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: strong ? 14 : 13, fontWeight: strong ? FontWeight.w900 : FontWeight.w700))),
        Text(value, style: TextStyle(fontSize: strong ? 16 : 13.5, fontWeight: FontWeight.w900, color: color ?? AppColors.ink)),
      ]),
    );
  }
}