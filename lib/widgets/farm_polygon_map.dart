import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/tr.dart';
import '../main.dart';
import '../models/farm_record.dart';
import '../models/pagsanjan_boundary.dart';

/// Mapa ng sariling bukid (satellite) na pwedeng i-zoom at i-edit.
/// Edit mode: pindutin ang mapa para magdagdag ng sulok, hilahin ang puting bilog para ilipat,
/// pindutin nang matagal ang sulok para tanggalin.
/// Imahe: Esri World Imagery (kailangan ng internet; may kasamang attribution).
class FarmPolygonMap extends StatefulWidget {
  final FarmRecord farm;
  final double height;

  /// Tinatawag kapag pinindot ang "I-save" sa edit mode.
  final void Function(List<LatLng> polygon, LatLng home)? onSave;

  /// Tinatawag kapag pinindot ang "Ibalik sa dati" (alisin ang custom na hugis).
  final VoidCallback? onReset;

  /// Hangganan ng Pagsanjan (kung mayroon): iginuguhit at nililimitahan ang mapa dito.
  final PagsanjanBoundary? boundary;

  /// Rehistradong Boundary ng Lupa mula sa Supabase (kung mayroon).
  final List<LatLng> outerLandBoundary;

  /// Magsimula agad sa edit mode (para sa pahina ng pag-guhit).
  final bool startEditing;

  /// Tinatawag pagkatapos mag-save, mag-cancel o mag-reset sa edit mode.
  final VoidCallback? onClose;

  const FarmPolygonMap({
    super.key,
    required this.farm,
    this.height = 300,
    this.outerLandBoundary = const [],
    this.onSave,
    this.onReset,
    this.boundary,
    this.startEditing = false,
    this.onClose,
  });

  @override
  State<FarmPolygonMap> createState() => _FarmPolygonMapState();
}

class _FarmPolygonMapState extends State<FarmPolygonMap> {
  final MapController _map = MapController();
  bool _editing = false;
  List<LatLng> _draft = [];
  final List<List<LatLng>> _history = [];

  bool get _canEdit => widget.onSave != null;

  bool _isPointInPoly(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return true;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      if ((pi.longitude > point.longitude) != (pj.longitude > point.longitude) &&
          (point.latitude < (pj.latitude - pi.latitude) * (point.longitude - pi.longitude) / (pj.longitude - pi.longitude) + pi.latitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  bool get _isOutsideOuterBoundary {
    final outer = widget.outerLandBoundary.isNotEmpty ? widget.outerLandBoundary : widget.farm.polygon;
    if (outer.length < 3 || _draft.isEmpty) return false;
    for (final p in _draft) {
      if (!_isPointInPoly(p, outer)) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.startEditing && widget.onSave != null) {
      _editing = true;
      _draft = []; // Starts clean with no initial sample pinpoints!
    }
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _draft = []; // Starts clean with no initial sample pinpoints!
      _history.clear();
    });
  }

  void _pushHistory() => _history.add(List.of(_draft));

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _draft = _history.removeLast();
    });
  }

  void _cancel() {
    setState(() => _editing = false);
    widget.onClose?.call();
  }

  void _save() {
    if (_draft.length < 3) return;
    final fallbackHome = _draft.isNotEmpty ? _draft.first : widget.farm.home;
    widget.onSave!(List.of(_draft), fallbackHome);
    setState(() => _editing = false);
    widget.onClose?.call();
  }

  void _zoom(double d) {
    final cam = _map.camera;
    _map.move(cam.center, (cam.zoom + d).clamp(12.0, 22.0));
  }

  void _fit() {
    final pts = _editing ? _draft : widget.farm.polygon;
    if (pts.length < 2) return;
    _map.fitCamera(CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(36), maxZoom: 19));
  }

  /// Magdagdag ng sulok sa pinakamalapit na gilid.
  void _addPoint(LatLng p) {
    _pushHistory();
    setState(() {
      if (_draft.length < 3) {
        _draft.add(p);
        return;
      }
      final k = math.cos(p.latitude * math.pi / 180);
      double d(LatLng a, LatLng b) {
        final ax = a.longitude * k, ay = a.latitude, bx = b.longitude * k, by = b.latitude;
        final px = p.longitude * k, py = p.latitude;
        final dx = bx - ax, dy = by - ay;
        final len2 = dx * dx + dy * dy;
        final t = len2 == 0 ? 0.0 : (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
        final cx = ax + t * dx, cy = ay + t * dy;
        return (px - cx) * (px - cx) + (py - cy) * (py - cy);
      }

      var best = 0;
      var bestD = double.infinity;
      for (var i = 0; i < _draft.length; i++) {
        final dd = d(_draft[i], _draft[(i + 1) % _draft.length]);
        if (dd < bestD) {
          bestD = dd;
          best = i;
        }
      }
      _draft.insert(best + 1, p);
    });
  }

  LatLng _moved(LatLng from, Offset delta) {
    final cam = _map.camera;
    final sp = cam.latLngToScreenPoint(from);
    return cam.pointToLatLng(math.Point(sp.x + delta.dx, sp.y + delta.dy));
  }

  Marker _handle(int i) {
    return Marker(
      key: ValueKey('h$i'),
      point: _draft[i],
      width: 48,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _pushHistory(),
        onPanUpdate: (d) => setState(() => _draft[i] = _moved(_draft[i], d.delta)),
        onLongPress: () {
          if (_draft.length <= 3) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(tr(context, 'Kailangan ng kahit 3 sulok.', 'At least 3 corners are needed.'))));
            return;
          }
          _pushHistory();
          setState(() => _draft.removeAt(i));
        },
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.leaf, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poly = _editing ? _draft : widget.farm.polygon;
    final h = _editing ? widget.height + 60 : widget.height;
    final area = polygonAreaHa(poly);
    final b = widget.boundary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: h,
        child: Stack(children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.farm.center,
              initialZoom: 17,
              minZoom: 12,
              maxZoom: 22,
              cameraConstraint: b == null
                  ? const CameraConstraint.unconstrained()
                  : CameraConstraint.containCenter(
                bounds: LatLngBounds(
                  LatLng(b.sw.latitude - 0.01, b.sw.longitude - 0.01),
                  LatLng(b.ne.latitude + 0.01, b.ne.longitude + 0.01),
                ),
              ),
              onTap: (_, p) {
                if (_editing) _addPoint(p);
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag |
                InteractiveFlag.pinchZoom |
                InteractiveFlag.doubleTapZoom |
                InteractiveFlag.scrollWheelZoom |
                InteractiveFlag.flingAnimation,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.agriculture',
                maxNativeZoom: 19,
                maxZoom: 22,
              ),
              if (b != null)
                PolygonLayer(polygons: [
                  // Padilimin ang labas ng Pagsanjan
                  Polygon(
                    points: const [LatLng(85, -180), LatLng(85, 180), LatLng(-85, 180), LatLng(-85, -180)],
                    holePointsList: b.rings,
                    color: Colors.black.withValues(alpha: 0.38),
                    borderStrokeWidth: 0,
                  ),
                  for (final r in b.rings)
                    Polygon(
                      points: r,
                      color: const Color(0xFF22C55E).withValues(alpha: 0.05),
                      borderColor: const Color(0xFF22C55E),
                      borderStrokeWidth: 3.5,
                    ),
                ]),
              // Outer Saved Land Boundary
              if (widget.outerLandBoundary.length >= 3)
                PolygonLayer(polygons: [
                  Polygon(
                    points: widget.outerLandBoundary,
                    color: const Color(0xFF0056B3).withValues(alpha: 0.15),
                    borderColor: const Color(0xFF0056B3),
                    borderStrokeWidth: 3.5,
                  ),
                ]),
              if (poly.length >= 3)
                PolygonLayer(polygons: [
                  Polygon(
                    points: poly,
                    color: _isOutsideOuterBoundary
                        ? Colors.red.withValues(alpha: 0.4)
                        : AppColors.leaf.withValues(alpha: _editing ? 0.34 : 0.28),
                    borderColor: _isOutsideOuterBoundary ? Colors.redAccent : Colors.white,
                    borderStrokeWidth: 3,
                  ),
                ])
              else if (poly.length == 2)
                PolylineLayer(polylines: [Polyline(points: poly, color: _isOutsideOuterBoundary ? Colors.red : Colors.white, strokeWidth: 3)]),
              if (_editing) MarkerLayer(markers: [for (var i = 0; i < _draft.length; i++) _handle(i)]),
            ],
          ),

          // Alamat
          Positioned(
            left: 10,
            top: 10,
            child: _editing
                ? _Banner(
              text: _isOutsideOuterBoundary
                  ? tr(context, '⚠️ LUMAGPAS SA BOUNDARY!', '⚠️ EXCEEDS LAND BOUNDARY!')
                  : _draft.isEmpty
                  ? tr(context, 'Iguhit ang Taniman', 'Draw Crop Area')
                  : tr(context, 'Hugis: ${area.toStringAsFixed(2)} ha', 'Shape: ${area.toStringAsFixed(2)} ha'),
              hint: _isOutsideOuterBoundary
                  ? tr(context, 'Ang iginuhit na taniman ay lumalagpas sa rehistradong boundary ng iyong lupa!',
                      'This crop boundary extends beyond your registered outer land boundary!')
                  : _draft.isEmpty
                  ? tr(context, 'Pindutin ang mapa sa loob ng iyong boundary para maglagay ng sulok ng iyong taniman.',
                      'Tap the map inside your outer boundary to place corners for your crop area.')
                  : tr(context, 'Pindutin ang mapa = dagdag sulok · Hilahin = ilipat · Pindutin nang matagal = alisin',
                      'Tap map = add corner · Drag = move · Long-press = remove'),
            )
                : _Legend(
              items: [
                if (widget.outerLandBoundary.length >= 3)
                  (tr(context, 'Rehistradong Lupa (Supabase)', 'Outer Land Boundary'), const Color(0xFF0056B3), false),
                (tr(context, 'Aking Taniman', 'My Crop Area'), AppColors.leaf, false),
              ],
            ),
          ),

          // Zoom at sentro
          Positioned(
            right: 10,
            top: 10,
            child: Column(children: [
              _MapBtn(icon: Icons.add_rounded, tooltip: 'Zoom in', onTap: () => _zoom(1)),
              const SizedBox(height: 6),
              _MapBtn(icon: Icons.remove_rounded, tooltip: 'Zoom out', onTap: () => _zoom(-1)),
              const SizedBox(height: 6),
              _MapBtn(icon: Icons.center_focus_strong_rounded, tooltip: tr(context, 'Ipakita ang bukid', 'Fit farm'), onTap: _fit),
              if (_canEdit && !_editing) ...[
                const SizedBox(height: 6),
                _MapBtn(icon: Icons.edit_rounded, tooltip: tr(context, 'I-edit ang hugis', 'Edit shape'), onTap: _startEdit, accent: true),
              ],
            ]),
          ),

          // Mga button sa edit mode
          if (_editing)
            Positioned(
              left: 10,
              right: 10,
              bottom: 22,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  IconButton(
                    tooltip: tr(context, 'Bawiin', 'Undo'),
                    onPressed: _history.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: tr(context, 'Linisin lahat ng puntos', 'Clear all points'),
                    onPressed: _draft.isEmpty
                        ? null
                        : () {
                            _pushHistory();
                            setState(() => _draft.clear());
                          },
                    icon: const Icon(Icons.clear_all_rounded),
                  ),
                  if (widget.onReset != null)
                    IconButton(
                      tooltip: tr(context, 'Ibalik sa dati', 'Reset to default'),
                      onPressed: () {
                        widget.onReset!();
                        setState(() => _editing = false);
                        widget.onClose?.call();
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                    ),
                  const Spacer(),
                  TextButton(onPressed: _cancel, child: Text(tr(context, 'Kanselahin', 'Cancel'))),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: (_draft.length >= 3 && !_isOutsideOuterBoundary) ? _save : null,
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF236B43)),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(tr(context, 'I-save', 'Save')),
                  ),
                ]),
              ),
            ),

          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white70,
              child: const Text('Imagery © Esri, Maxar, Earthstar Geographics', style: TextStyle(fontSize: 9.5)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool accent;
  const _MapBtn({required this.icon, required this.tooltip, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent ? AppColors.leaf : Colors.white.withValues(alpha: 0.94),
        elevation: 2,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 38, height: 38, child: Icon(icon, size: 21, color: accent ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final String hint;
  const _Banner({required this.text, required this.hint});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.leaf)),
          const SizedBox(height: 2),
          Text(hint, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, height: 1.25)),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<(String, Color, bool)> items;
  const _Legend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        for (final i in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: i.$2,
                  shape: i.$3 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: i.$3 ? null : BorderRadius.circular(3),
                  border: Border.all(color: AppColors.leaf, width: 1.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(i.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ]),
          ),
      ]),
    );
  }
}
