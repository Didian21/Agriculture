/// Presyo sa bukid (farmgate) mula sa record ng Municipal Agriculture Office (MAO) ng Pagsanjan.
/// Mula sa file na Price_Commodity_Farmgate.xlsx: lingguhang presyo, Mayo hanggang Nobyembre.
/// Bawat buwan ay ang MEDIAN ng mga lingguhang presyo (hindi naaapektuhan ng ilang labis na numero).
/// Walong pananim lang sa 11 ng DSS ang nasa record: wala ang Palay, Cacao, at Kamoteng kahoy.
/// Kapag may bagong datos, palitan lang ang laman ng [kMaoPrices].
library;

/// Presyo ng isang buwan: median, pinakamababa, pinakamataas, at bilang ng lingguhang tala.
class MaoMonth {
  final double median, low, high;
  final int weeks;
  const MaoMonth(this.median, this.low, this.high, this.weeks);
}

class MaoSeries {
  final String maoName; // pangalan sa record ng MAO
  final String unit; // 'kg' o 'pc'
  final List<MaoMonth?> months; // Mayo (index 0) hanggang Nobyembre (index 6)
  const MaoSeries(this.maoName, this.unit, this.months);

  static const firstMonth = 5, lastMonth = 11;

  MaoMonth? at(int month) {
    final i = month - firstMonth;
    if (i < 0 || i >= months.length) return null;
    return months[i];
  }

  /// Buwan na may pinakamataas na median.
  int? get bestMonth {
    int? best;
    double top = -1;
    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      if (m != null && m.median > top) {
        top = m.median;
        best = firstMonth + i;
      }
    }
    return best;
  }

  /// Pinakabagong buwan na may datos.
  int? get latestMonth {
    for (var i = months.length - 1; i >= 0; i--) {
      if (months[i] != null) return firstMonth + i;
    }
    return null;
  }

  int get monthsWithData => months.where((m) => m != null).length;
}

const Map<String, MaoSeries> kMaoPrices = {
  'Eggplant': MaoSeries('Talong', 'kg', [MaoMonth(35.0, 35.0, 35.0, 1), MaoMonth(40.0, 30.0, 55.0, 5), MaoMonth(55.0, 35.0, 70.0, 4), MaoMonth(77.5, 55.0, 100.0, 4), MaoMonth(110.0, 40.0, 120.0, 5), MaoMonth(75.0, 70.0, 80.0, 4), MaoMonth(75.0, 75.0, 75.0, 1)]),
  'Squash': MaoSeries('Kalabasa', 'kg', [MaoMonth(25.0, 25.0, 25.0, 1), MaoMonth(30.0, 20.0, 35.0, 5), MaoMonth(37.5, 30.0, 40.0, 4), MaoMonth(35.0, 30.0, 40.0, 4), MaoMonth(25.0, 12.0, 30.0, 5), MaoMonth(27.5, 20.0, 35.0, 4), MaoMonth(40.0, 40.0, 40.0, 1)]),
  'String beans': MaoSeries('Sitao', 'kg', [MaoMonth(65.0, 65.0, 65.0, 1), MaoMonth(70.0, 50.0, 100.0, 5), MaoMonth(45.0, 40.0, 70.0, 4), MaoMonth(55.0, 30.0, 80.0, 4), MaoMonth(90.0, 70.0, 100.0, 5), MaoMonth(62.5, 60.0, 65.0, 4), MaoMonth(70.0, 70.0, 70.0, 1)]),
  'Okra': MaoSeries('Okra', 'kg', [MaoMonth(30.0, 30.0, 30.0, 1), MaoMonth(40.0, 15.0, 50.0, 5), MaoMonth(25.0, 20.0, 30.0, 4), MaoMonth(32.5, 15.0, 50.0, 4), MaoMonth(70.0, 60.0, 75.0, 5), MaoMonth(67.5, 60.0, 75.0, 4), MaoMonth(55.0, 55.0, 55.0, 1)]),
  'Pechay (Tagalog)': MaoSeries('Petchay (Tagalog)', 'kg', [MaoMonth(70.0, 70.0, 70.0, 1), MaoMonth(70.0, 45.0, 100.0, 5), MaoMonth(32.5, 20.0, 80.0, 4), MaoMonth(60.0, 20.0, 100.0, 4), MaoMonth(100.0, 80.0, 120.0, 5), MaoMonth(85.0, 75.0, 95.0, 4), MaoMonth(65.0, 65.0, 65.0, 1)]),
  'Chili (long)': MaoSeries('Sili (Panigang)', 'kg', [MaoMonth(50.0, 50.0, 50.0, 1), MaoMonth(55.0, 30.0, 60.0, 5), MaoMonth(35.0, 30.0, 45.0, 4), MaoMonth(32.5, 25.0, 40.0, 4), MaoMonth(95.0, 80.0, 120.0, 5), MaoMonth(87.5, 80.0, 100.0, 4), MaoMonth(70.0, 70.0, 70.0, 1)]),
  'Chili (hot)': MaoSeries('Sili (hot)', 'kg', [MaoMonth(70.0, 70.0, 70.0, 1), MaoMonth(110.0, 65.0, 200.0, 5), MaoMonth(57.5, 10.0, 110.0, 4), MaoMonth(37.5, 20.0, 50.0, 4), MaoMonth(100.0, 95.0, 250.0, 5), MaoMonth(205.0, 180.0, 230.0, 4), MaoMonth(175.0, 175.0, 175.0, 1)]),
  'Coconut': MaoSeries('Coconut', 'pc', [MaoMonth(10.0, 10.0, 10.0, 1), MaoMonth(17.5, 10.0, 25.0, 2), MaoMonth(20.0, 7.0, 25.0, 3), MaoMonth(25.0, 25.0, 25.0, 1), null, null, null]),
};

MaoSeries? maoSeriesFor(String cropId) => kMaoPrices[cropId];
