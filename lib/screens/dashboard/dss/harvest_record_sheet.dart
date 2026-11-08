import 'package:flutter/material.dart';

import '../../../core/crop_data.dart';
import '../../../core/crop_l10n.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farm_planting.dart';
import '../../../models/harvest_record.dart';
import '../../../services/dss_service.dart';
import '../../../widgets/dss_common.dart';

/// Itala ang ani ng isang tanim: petsa, totoong kg, presyong naibenta at gastos.
/// Ibinabalik ang HarvestRecord kapag na-save, o null kapag kinansela.
Future<HarvestRecord?> showHarvestRecordSheet(BuildContext context, FarmPlanting planting, {double? historyKgPerHa}) {
  return showModalBottomSheet<HarvestRecord>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => _HarvestForm(planting: planting, historyKgPerHa: historyKgPerHa),
  );
}

class _HarvestForm extends StatefulWidget {
  final FarmPlanting planting;
  final double? historyKgPerHa;
  const _HarvestForm({required this.planting, this.historyKgPerHa});

  @override
  State<_HarvestForm> createState() => _HarvestFormState();
}

class _HarvestFormState extends State<_HarvestForm> {
  late DateTime _date;
  late final TextEditingController _kg;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  String? _kgError;
  String? _priceError;
  double? _hint; // hulang presyo kada kg

  @override
  void initState() {
    super.initState();
    final p = widget.planting;
    final today = DateTime.now();
    _date = today.isBefore(p.plantedOn) ? p.plantedOn : today;
    final est = DssService.estimate(p, historyKgPerHa: widget.historyKgPerHa);
    _hint = factsFor(p.crop)?.basePrice == null ? null : est?.priceMid;
    _kg = TextEditingController(text: est == null ? '' : est.kgMid.round().toString());
    _price = TextEditingController(text: _hint == null ? '' : _hint!.toStringAsFixed(1));
    _cost = TextEditingController(text: p.costPhp == null ? '' : _trim(p.costPhp!));
  }

  @override
  void dispose() {
    _kg.dispose();
    _price.dispose();
    _cost.dispose();
    super.dispose();
  }

  String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final p = widget.planting;
    final now = DateTime.now();
    final last = now.isBefore(p.plantedOn) ? p.plantedOn : now;
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(last) ? last : _date,
      firstDate: p.plantedOn,
      lastDate: last,
    );
    if (d != null) setState(() => _date = d);
  }

  void _save(AppLocalizations t) {
    final kg = _parse(_kg.text);
    final price = _parse(_price.text);
    var bad = false;
    if (kg == null || kg <= 0) {
      _kgError = t.dssAreaInvalid;
      bad = true;
    }
    if (price == null || price <= 0) {
      _priceError = t.dssAreaInvalid;
      bad = true;
    }
    if (bad) {
      setState(() {});
      return;
    }
    final cost = _parse(_cost.text);
    final p = widget.planting;
    Navigator.pop(
      context,
      HarvestRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        crop: p.crop,
        hectares: p.hectares,
        plantedOn: p.plantedOn,
        harvestedOn: _date,
        yieldKg: kg!,
        pricePerKg: price!,
        costPhp: (cost != null && cost > 0) ? cost : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final kg = _parse(_kg.text);
    final price = _parse(_price.text);
    final cost = _parse(_cost.text);
    final income = (kg != null && price != null && kg > 0 && price > 0) ? kg * price : null;
    final profit = (income != null && cost != null && cost > 0) ? income - cost : null;

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
            Text(t.dssRecordTitle(t.cropLabel(widget.planting.crop)),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(t.dssRecordSub, style: const TextStyle(color: AppColors.muted, height: 1.35)),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(labelText: t.dssHarvestedOn, prefixIcon: const Icon(Icons.event_available_rounded)),
                child: Text(DssFmt.date(_date), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kg,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _kgError = null),
              decoration: InputDecoration(
                labelText: t.dssActualYield,
                prefixIcon: const Icon(Icons.scale_rounded),
                suffixText: 'kg',
                errorText: _kgError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _priceError = null),
              decoration: InputDecoration(
                labelText: t.dssSoldPrice,
                prefixIcon: const Icon(Icons.sell_rounded),
                prefixText: '₱ ',
                suffixText: '/ kg',
                errorText: _priceError,
                helperText: _hint == null ? null : t.dssSoldPriceHint(DssFmt.pesoKg(_hint!)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: t.dssCost,
                prefixIcon: const Icon(Icons.payments_outlined),
                prefixText: '₱ ',
              ),
            ),
            if (income != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  _row(t.dssRecIncome, DssFmt.peso(income), AppColors.ink),
                  if (profit != null) ...[
                    const SizedBox(height: 6),
                    _row(t.dssRecProfit, '${profit < 0 ? '-' : ''}${DssFmt.peso(profit.abs())}',
                        profit >= 0 ? AppColors.leaf : AppColors.soil),
                  ],
                ]),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => _save(t), child: Text(t.save))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, Color c) => Row(children: [
    Expanded(child: Text(k, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
    Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: c)),
  ]);
}