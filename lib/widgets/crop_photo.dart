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

  static String? find(Map<String, String> m, String cropId) {
    final info = cropInfoFor(cropId);
    final keys = info == null ? [cropId] : [info.slug, info.id, info.nameEn, info.nameTl];
    for (final k in keys) {
      final p = m[norm(k)];
      if (p != null) return p;
    }
    return null;
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
    return FutureBuilder<Map<String, String>>(
      future: CropPhotos.load(),
      builder: (context, snap) {
        final path = snap.hasData ? CropPhotos.find(snap.data!, cropId) : null;
        if (path == null) return fb;
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