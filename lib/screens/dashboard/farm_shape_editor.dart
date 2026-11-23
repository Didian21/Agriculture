import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/tr.dart';
import '../../main.dart';
import '../../models/farm_store.dart';
import '../../models/farmer.dart';
import '../../models/pagsanjan_boundary.dart';
import '../../services/account_service.dart';
import '../../widgets/farm_polygon_map.dart';
import '../../widgets/field_background.dart';

/// Buong-screen na pahina para iguhit o baguhin ang pwesto ng taniman sa mapa. Binubuksan mula sa DSS.
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
    final accountService = Provider.of<AccountService>(context);
    final farmerUsername = accountService.activeUserName.trim().toLowerCase();

    final farmer = accountService.farmers.firstWhere(
      (f) => f.username.trim().toLowerCase() == farmerUsername ||
             f.profileName.trim().toLowerCase() == farmerUsername,
      orElse: () => Farmer(id: '', username: farmerUsername, password: '', profileName: farmerUsername, barangay: 'Biñan'),
    );

    final dynamic supabaseFarm = accountService.farms.cast<dynamic>().firstWhere(
      (f) => f != null && (
        f.farmerId == farmer.id ||
        (f.farmerName != null && f.farmerName.trim().isNotEmpty && f.farmerName.trim().toLowerCase() == farmer.profileName.trim().toLowerCase()) ||
        (f.farmerName != null && f.farmerName.trim().isNotEmpty && f.farmerName.trim().toLowerCase() == farmer.username.trim().toLowerCase())
      ),
      orElse: () => null,
    );

    List<LatLng> registeredLandBoundary = [];
    if (supabaseFarm != null && supabaseFarm.boundaryPoints != null) {
      try {
        final List<dynamic> pts = supabaseFarm.boundaryPoints as List<dynamic>;
        registeredLandBoundary = pts.cast<LatLng>().toList();
      } catch (_) {
        if (supabaseFarm.boundaryPoints is List<LatLng>) {
          registeredLandBoundary = supabaseFarm.boundaryPoints as List<LatLng>;
        }
      }
    }

    if (registeredLandBoundary.isEmpty) {
      registeredLandBoundary = _store.current.polygon;
    }

    return Stack(children: [
      const Positioned.fill(child: FieldBackground()),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(tr(context, 'Iguhit ang pwesto kung saan magtatanim', 'Draw planting location plot on map'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
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
                      outerLandBoundary: registeredLandBoundary,
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
                      'Tap the map INSIDE your registered farm land boundary to draw where you plant. Cannot extend outside your land boundary.'),
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
