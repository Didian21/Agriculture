import 'package:flutter/material.dart';

import '../models/planting_guide.dart';

/// Larawan ng pananim. Kapag wala pang file, icon ang ipinapakita.
class CropImage extends StatelessWidget {
  final PlantingGuide guide;
  const CropImage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      guide.image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 800,
      errorBuilder: (_, __, ___) => Container(
        color: guide.color.withValues(alpha: 0.15),
        alignment: Alignment.center,
        child: Icon(guide.icon, size: 40, color: guide.color),
      ),
    );
  }
}