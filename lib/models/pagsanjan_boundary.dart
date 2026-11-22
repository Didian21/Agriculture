import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

/// Hangganan ng Pagsanjan (mula sa GeoJSON).
class PagsanjanBoundary {
  final List<List<LatLng>> rings;
  final LatLng sw, ne;
  const PagsanjanBoundary(this.rings, this.sw, this.ne);

  static PagsanjanBoundary? _cached;

  static Future<PagsanjanBoundary?> load() async {
    if (_cached != null) return _cached;
    try {
      final raw = await rootBundle.loadString('assets/MAP/Boundary_Pagsanjan.geojson');
      final data = json.decode(raw) as Map<String, dynamic>;
      final rings = <List<LatLng>>[];

      if (data['features'] != null) {
        for (final feature in data['features']) {
          final geometry = feature['geometry'];
          if (geometry != null) {
            final type = geometry['type'];
            final coordinates = geometry['coordinates'];

            if (type == 'Polygon') {
              for (final ring in coordinates) {
                final points = <LatLng>[];
                for (final coord in ring) {
                  points.add(LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()));
                }
                if (points.length >= 3) rings.add(points);
              }
            } else if (type == 'MultiPolygon') {
              for (final polygonCoords in coordinates) {
                for (final ring in polygonCoords) {
                  final points = <LatLng>[];
                  for (final coord in ring) {
                    points.add(LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()));
                  }
                  if (points.length >= 3) rings.add(points);
                }
              }
            }
          }
        }
      }

      if (rings.isEmpty) return null;

      var minLa = 90.0, maxLa = -90.0, minLo = 180.0, maxLo = -180.0;
      for (final r in rings) {
        for (final p in r) {
          if (p.latitude < minLa) minLa = p.latitude;
          if (p.latitude > maxLa) maxLa = p.latitude;
          if (p.longitude < minLo) minLo = p.longitude;
          if (p.longitude > maxLo) maxLo = p.longitude;
        }
      }
      _cached = PagsanjanBoundary(rings, LatLng(minLa, minLo), LatLng(maxLa, maxLo));
      return _cached;
    } catch (_) {
      return null;
    }
  }
}
