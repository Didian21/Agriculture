import 'package:flutter/material.dart';

import '../../core/tr.dart';
import '../../main.dart';
import '../../models/farm_store.dart';
import '../../models/pagsanjan_boundary.dart';
import '../../widgets/farm_polygon_map.dart';
import '../../widgets/field_background.dart';

/// Buong-screen na pahina para iguhit o baguhin ang hugis ng bukid. Binubuksan mula sa DSS.
/// Ang hugis na ise-save dito ay makikita sa Aking Bukid (view lang doon).
class FarmShapeEditor extends StatefulWidget {
  const FarmShapeEditor({super.key});

  @override
  State<FarmShapeEditor> createState() => _FarmShapeEditorState();
}

class _FarmShapeEditorState extends State<FarmShapeEditor> {
  final _store = FarmStore.instance;
  late final Future<PagsanjanBoundary?> _boundary = PagsanjanBoundary.load();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: FieldBackground()),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr(context, 'Iguhit ang sukat ng taniman sa mapa', 'Draw crop area on map'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            // Ang edit mode ay nagdadagdag ng 60 sa taas ng mapa.
            final h = (box.maxHeight - 110).clamp(260.0, 900.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FutureBuilder<PagsanjanBoundary?>(
                  future: _boundary,
                  builder: (context, bs) => ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) => FarmPolygonMap(
                      farm: _store.current,
                      outerLandBoundary: _store.current.polygon,
                      height: h - 60,
                      startEditing: true,
                      boundary: bs.data,
                      onSave: (poly, home) => _store.save(poly, home),
                      onReset: _store.isCustom ? () => _store.reset() : null,
                      onClose: () {
                        if (mounted) Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(context,
                      'Pindutin ang mapa sa LOOB ng iyong rehistradong bukid para iguhit ang pwesto at sukat ng iyong itatanim. Bawal lumagpas sa boundary ng iyong lupa.',
                      'Tap the map INSIDE your registered farm boundary to draw where you plant. Cannot extend outside your land boundary.'),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ]),
            );
          }),
        ),
      ),
    ]);
  }
}