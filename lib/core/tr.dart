import 'package:flutter/widgets.dart';

/// Tagalog ba ang gamit na wika ngayon?
bool isTl(BuildContext context) => Localizations.localeOf(context).languageCode == 'tl';

/// Pumipili ng teksto ayon sa wika: [tl] para sa Tagalog, [en] para sa English.
String tr(BuildContext context, String tl, String en) => isTl(context) ? tl : en;