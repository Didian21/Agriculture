import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../providers/farm_input_provider.dart';
import '../../../widgets/dss_common.dart';

/// Ilagay o baguhin ang KABUUANG sukat ng lupa. Hinahati ito sa mga pananim sa "Add crop".
Future<void> showTotalLandSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => const _TotalLandForm(),
  );
}

class _TotalLandForm extends StatefulWidget {
  const _TotalLandForm();

  @override
  State<_TotalLandForm> createState() => _TotalLandFormState();
}

class _TotalLandFormState extends State<_TotalLandForm> {
  late bool _sqm;
  late final TextEditingController _c;
  String? _error;

  @override
  void initState() {
    super.initState();
    final input = context.read<FarmInputProvider>();
    _sqm = input.useSqm;
    _c = TextEditingController(text: input.totalHectares == null ? '' : DssFmt.areaNumber(input.totalHectares!, sqm: _sqm));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _setUnit(bool sqm) {
    if (sqm == _sqm) return;
    final v = _parse(_c.text);
    setState(() {
      if (v != null && v > 0) {
        final ha = _sqm ? v / 10000 : v;
        _c.text = DssFmt.areaNumber(ha, sqm: sqm);
      }
      _sqm = sqm;
      _error = null;
    });
    context.read<FarmInputProvider>().setUseSqm(sqm);
  }

  void _save(AppLocalizations t) {
    final v = _parse(_c.text);
    if (v == null || v <= 0) {
      setState(() => _error = t.dssAreaInvalid);
      return;
    }
    final ha = _sqm ? v / 10000 : v;
    final input = context.read<FarmInputProvider>();
    if (ha < input.usedHectares - 0.00001) {
      setState(() => _error = t.dssTotalTooSmall(DssFmt.area(input.usedHectares, sqm: _sqm)));
      return;
    }
    input.setTotal(ha);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
            Text(t.dssTotalLand, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(t.dssTotalLandSub, style: const TextStyle(color: AppColors.muted, height: 1.35)),
            const SizedBox(height: 14),
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
              controller: _c,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t.dssTotalLand,
                prefixIcon: const Icon(Icons.landscape_rounded),
                suffixText: _sqm ? 'm²' : 'ha',
                errorText: _error,
                errorMaxLines: 3,
                helperText: t.dssUnitNote,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 18),
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
}