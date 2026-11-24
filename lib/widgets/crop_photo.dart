import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/crop_info.dart';

Color cropGroupColor(CropGroup g) {
  switch (g) {
    case CropGroup.veg:
      return const Color(0xFF7DBE86);
    case CropGroup.fruit:
      return const Color(0xFFE9C46A);
    case CropGroup.root:
      return const Color(0xFFC9A27E);
    case CropGroup.grain:
      return const Color(0xFFD8CB7A);
  }
}

/// Hinahanap ang litrato sa assets/images/crops/ (o assets/crops/) (png, jpg, jpeg, webp). Hindi mahalaga ang laki ng titik.
/// Tinatanggap na pangalan: slug (hal. string_beans), ID, pangalang Ingles o Tagalog.
class CropPhotos {
  static Future<Map<String, String>>? _future;

  static Future<Map<String, String>> load() => _future ??= _read();

  static String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static Future<Map<String, String>> _read() async {
    final out = <String, String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final a in manifest.listAssets()) {
        if (!a.startsWith('assets/images/crops/') && !a.startsWith('assets/crops/')) continue;
        final low = a.toLowerCase();
        if (!(low.endsWith('.png') || low.endsWith('.jpg') || low.endsWith('.jpeg') || low.endsWith('.webp'))) continue;
        final file = a.substring(a.lastIndexOf('/') + 1);
        out[norm(file.substring(0, file.lastIndexOf('.')))] = a;
      }
    } catch (_) {
      // walang manifest o walang litrato: emoji ang gagamitin
    }
    return out;
  }

  static String getDirectAssetPath(String cropId) {
    final cleanId = cropId.trim().toLowerCase();
    if (cleanId.contains('rice') || cleanId.contains('palay')) return 'assets/images/crops/rice.jpg';
    if (cleanId.contains('coconut') || cleanId.contains('niyog')) return 'assets/images/crops/coconut.jpg';
    if (cleanId.contains('eggplant') || cleanId.contains('talong')) return 'assets/images/crops/eggplant.jpg';
    if (cleanId.contains('squash') || cleanId.contains('kalabasa')) return 'assets/images/crops/squash.jpg';
    if (cleanId.contains('string') || cleanId.contains('sitaw') || cleanId.contains('bean')) return 'assets/images/crops/string_beans.jpg';
    if (cleanId.contains('okra')) return 'assets/images/crops/okra.jpg';
    if (cleanId.contains('pechay') || cleanId.contains('petsay')) return 'assets/images/crops/pechay_tagalog.jpg';
    if (cleanId.contains('chili') || cleanId.contains('sili')) {
      if (cleanId.contains('long') || cleanId.contains('haba') || cleanId.contains('panigang')) return 'assets/images/crops/chili_long.jpg';
      return 'assets/images/crops/chili_hot.jpg';
    }
    if (cleanId.contains('cacao') || cleanId.contains('kakaw')) return 'assets/images/crops/coconut.jpg';
    if (cleanId.contains('cassava') || cleanId.contains('kamoteng kahoy') || cleanId.contains('balinghoy')) return 'assets/images/crops/sweet_potato.jpg';

    return 'assets/images/crops/rice.jpg';
  }

  static String? find(Map<String, String> m, String cropId) {
    final cleanId = cropId.trim().toLowerCase();

    if (cleanId.contains('rice') || cleanId.contains('palay')) return m[norm('rice')] ?? 'assets/images/crops/rice.jpg';
    if (cleanId.contains('coconut') || cleanId.contains('niyog')) return m[norm('coconut')] ?? 'assets/images/crops/coconut.jpg';
    if (cleanId.contains('eggplant') || cleanId.contains('talong')) return m[norm('eggplant')] ?? 'assets/images/crops/eggplant.jpg';
    if (cleanId.contains('squash') || cleanId.contains('kalabasa')) return m[norm('squash')] ?? 'assets/images/crops/squash.jpg';
    if (cleanId.contains('string') || cleanId.contains('sitaw') || cleanId.contains('bean')) return m[norm('string_beans')] ?? 'assets/images/crops/string_beans.jpg';
    if (cleanId.contains('okra')) return m[norm('okra')] ?? 'assets/images/crops/okra.jpg';
    if (cleanId.contains('pechay') || cleanId.contains('petsay')) return m[norm('pechay_tagalog')] ?? m[norm('pechay_baguio')] ?? 'assets/images/crops/pechay_tagalog.jpg';
    if (cleanId.contains('chili') || cleanId.contains('sili')) {
      if (cleanId.contains('long') || cleanId.contains('haba') || cleanId.contains('panigang')) return m[norm('chili_long')] ?? 'assets/images/crops/chili_long.jpg';
      return m[norm('chili_hot')] ?? 'assets/images/crops/chili_hot.jpg';
    }
    if (cleanId.contains('cacao') || cleanId.contains('kakaw')) return m[norm('cacao')] ?? m[norm('coconut')] ?? 'assets/images/crops/coconut.jpg';
    if (cleanId.contains('cassava') || cleanId.contains('kamoteng kahoy') || cleanId.contains('balinghoy')) return m[norm('cassava')] ?? m[norm('sweet_potato')] ?? 'assets/images/crops/sweet_potato.jpg';

    final info = cropInfoFor(cropId);
    final keys = info == null ? [cropId] : [info.slug, info.id, info.nameEn, info.nameTl];
    for (final k in keys) {
      final p = m[norm(k)];
      if (p != null) return p;
    }

    for (final entry in m.entries) {
      if (cleanId.contains(entry.key) || entry.key.contains(cleanId)) {
        return entry.value;
      }
    }

    return getDirectAssetPath(cropId);
  }
}

/// Litrato ng pananim kahit saang tab. Kung walang litrato: [fallback] kung mayroon,
/// kung wala ay emoji sa kulay ng grupo.
class CropPhoto extends StatelessWidget {
  final String cropId;
  final double emojiSize;
  final Widget? fallback;
  const CropPhoto({super.key, required this.cropId, this.emojiSize = 28, this.fallback});

  Widget _emoji() {
    final info = cropInfoFor(cropId);
    final c = info == null ? const Color(0xFF7DBE86) : cropGroupColor(info.group);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.35), c.withValues(alpha: 0.75)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(info?.emoji ?? '🌱', style: TextStyle(fontSize: emojiSize)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fb = fallback ?? _emoji();
    final directPath = CropPhotos.getDirectAssetPath(cropId);

    return FutureBuilder<Map<String, String>>(
      future: CropPhotos.load(),
      builder: (context, snap) {
        final path = snap.hasData ? (CropPhotos.find(snap.data!, cropId) ?? directPath) : directPath;
        return Image.asset(
          path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 800,
          errorBuilder: (context, error, stack) => fb,
        );
      },
    );
  }
}