import '../l10n/app_localizations.dart';

/// Pang-format ng mga numero at buwan para sa DSS.
class DssFmt {
  static String kg(double v) {
    if (v >= 1000) {
      final t = v / 1000;
      return '${t >= 100 ? t.toStringAsFixed(0) : t.toStringAsFixed(1)} t';
    }
    return '${v.round()} kg';
  }

  static String group(int n) => _group(n);

  /// Porsyento: walang decimal kung buo, isang decimal kung hindi (hal. 33.3).
  static String percent(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  static String _group(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String peso(double v) => '₱${_group(v.round())}';
  static String pesoKg(double v) => '₱${v.toStringAsFixed(1)}';

  static String _trimNum(double v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '') : s;
  }

  /// Sukat ng lupa (galing sa hektarya) sa napiling yunit: ha o m².
  static String area(double ha, {required bool sqm}) =>
      sqm ? '${_group((ha * 10000).round())} m²' : '${_trimNum(ha)} ha';

  /// Numero lamang para sa input field.
  static String areaNumber(double ha, {required bool sqm}) =>
      sqm ? (ha * 10000).round().toString() : _trimNum(ha);

  static String date(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

extension DssMonths on AppLocalizations {
  List<String> get monthsShort => dssMonthsShort.split(',');
  String monthShort(int m) => monthsShort[(m - 1) % 12];
  String monthList(Iterable<int> months) => months.map(monthShort).join(', ');
}