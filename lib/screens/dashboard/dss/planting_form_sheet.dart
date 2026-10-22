import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/crop_data.dart';
import '../../../core/crop_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farm_planting.dart';
import '../../../providers/farm_input_provider.dart';
import '../../../widgets/dss_common.dart';

/// Form: pananim, sukat ng lupa, petsa ng pagtatanim, at (opsyonal) ani.
/// Ibinabalik ang FarmPlanting kapag na-save, o null kapag kinansela.
Future<FarmPlanting?> showPlantingForm(BuildContext context, {FarmPlanting? existing}) {
  return showModalBottomSheet<FarmPlanting>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => _PlantingForm(existing: existing),
  );
}

class _PlantingForm extends StatefulWidget {
  final FarmPlanting? existing;
  const _PlantingForm({this.existing});

  @override
  State<_PlantingForm> createState() => _PlantingFormState();
}

class _PlantingFormState extends State<_PlantingForm> {
  late String _crop;
  late DateTime _date;
  late final TextEditingController _area;
  late final TextEditingController _yield;
  String? _areaError;
  late bool _sqm;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _crop = e?.crop ?? kCropFacts.keys.first;
    _date = e?.plantedOn ?? DateTime.now();
    _sqm = context.read<FarmInputProvider>().useSqm;
    _area = TextEditingController(text: e == null ? '' : DssFmt.areaNumber(e.hectares, sqm: _sqm));
    _yield = TextEditingController(text: e?.lastYieldKg == null ? '' : _trim(e!.lastYieldKg!));
  }

  @override
  void dispose() {
    _area.dispose();
    _yield.dispose();
    super.dispose();
  }

  String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d != null) setState(() => _date = d);
  }

  /// Palitan ang yunit (ha / m²) at i-convert ang nakasulat na numero.
  void _setUnit(bool sqm) {
    if (sqm == _sqm) return;
    final v = _parse(_area.text);
    setState(() {
      if (v != null && v > 0) {
        final ha = _sqm ? v / 10000 : v;
        _area.text = DssFmt.areaNumber(ha, sqm: sqm);
      }
      _sqm = sqm;
      _areaError = null;
    });
    context.read<FarmInputProvider>().setUseSqm(sqm);
  }

  void _save(AppLocalizations t) {
    final v = _parse(_area.text);
    if (v == null || v <= 0) {
      setState(() => _areaError = t.dssAreaInvalid);
      return;
    }
    final ha = _sqm ? v / 10000 : v;
    final rem = context.read<FarmInputProvider>().remainingHectares(excludeId: widget.existing?.id);
    if (rem != null && ha > rem + 0.00001) {
      setState(() => _areaError = t.dssExceeds(DssFmt.area(rem, sqm: _sqm)));
      return;
    }
    final y = _parse(_yield.text);
    Navigator.pop(
      context,
      FarmPlanting(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        crop: _crop,
        hectares: ha,
        plantedOn: _date,
        lastYieldKg: (y != null && y > 0) ? y : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final rem = context.watch<FarmInputProvider>().remainingHectares(excludeId: widget.existing?.id);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.existing == null ? t.dssAddPlanting : t.dssEditPlanting,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Text(t.dssCrop, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kCropFacts.keys)
                  ChoiceChip(
                    label: Text(t.cropLabel(c)),
                    selected: _crop == c,
                    onSelected: (_) => setState(() => _crop = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  ButtonSegment(value: false, label: Text(t.dssUnitHa)),
                  ButtonSegment(value: true, label: Text(t.dssUnitSqm)),
                ],
                selected: {_sqm},
                onSelectionChanged: (s) => _setUnit(s.first),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t.dssLandSize,
                prefixIcon: const Icon(Icons.square_foot_rounded),
                suffixText: _sqm ? 'm²' : 'ha',
                errorText: _areaError,
                errorMaxLines: 3,
                helperText: rem == null ? t.dssUnitNote : t.dssRemaining(DssFmt.area(rem, sqm: _sqm)),
              ),
              onChanged: (_) {
                if (_areaError != null) setState(() => _areaError = null);
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(labelText: t.dssPlantedOn, prefixIcon: const Icon(Icons.event_rounded)),
                child: Text(DssFmt.date(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yield,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t.dssLastYield,
                prefixIcon: const Icon(Icons.scale_rounded),
                suffixText: 'kg',
                helperText: t.dssLastYieldHint,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: () => _save(t), child: Text(t.save)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}