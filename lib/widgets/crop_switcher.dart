import 'package:flutter/material.dart';

import '../core/dss_catalog.dart';
import '../core/tr.dart';
import '../main.dart';
import '../models/farm_store.dart';
import 'crop_photo.dart';

/// Pamili ng tanim kapag higit sa isa ang tanim ng farmer. Walang lalabas kung isa lang o wala.
/// Ang piniling tanim ang ginagamit ng Home, Aking Bukid at Payo.
class CropSwitcher extends StatelessWidget {
  const CropSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FarmStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.profiles;
        if (list.length < 2) return const SizedBox.shrink();
        final tl = isTl(context);
        final active = store.profile?.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(context, 'Aling tanim ang titingnan?', 'Which crop to view?'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted)),
            const SizedBox(height: 6),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = list[i];
                  final sel = p.id == active;
                  return GestureDetector(
                    onTap: () => store.setActive(p.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.leaf.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: sel ? AppColors.leaf : AppColors.border, width: sel ? 2 : 1),
                      ),
                      child: Row(children: [
                        ClipOval(child: SizedBox(width: 34, height: 34, child: CropPhoto(cropId: p.crop, emojiSize: 16))),
                        const SizedBox(width: 8),
                        Text(dssCropName(p.crop, tl),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: sel ? AppColors.leaf : AppColors.ink)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }
}