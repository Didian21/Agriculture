import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../providers/farm_input_provider.dart';
import '../../../services/farm_weather_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/weather_icon.dart';

/// Mapa ng sariling bukid + panahon sa mismong lokasyon (tap sa mapa para ilipat ang pin).
class FarmMapCard extends StatefulWidget {
  final FarmInputProvider input;
  const FarmMapCard({super.key, required this.input});

  @override
  State<FarmMapCard> createState() => _FarmMapCardState();
}

class _FarmMapCardState extends State<FarmMapCard> {
  final _map = MapController();
  final _service = FarmWeatherService();
  FarmWeather? _w;
  bool _loading = true;
  bool _failed = false;
  double? _loadedLat, _loadedLon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FarmMapCard old) {
    super.didUpdateWidget(old);
    if (_loadedLat != widget.input.lat || _loadedLon != widget.input.lon) {
      _map.move(LatLng(widget.input.lat, widget.input.lon), _map.camera.zoom);
      _load();
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lat = widget.input.lat, lon = widget.input.lon;
    _loadedLat = lat;
    _loadedLon = lon;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final w = await _service.fetch(lat, lon);
      if (!mounted || _loadedLat != lat || _loadedLon != lon) return;
      setState(() {
        _w = w;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final point = LatLng(widget.input.lat, widget.input.lon);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 230,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                      ),
                      onTap: (_, p) => widget.input.setLocation(
                        double.parse(p.latitude.toStringAsFixed(5)),
                        double.parse(p.longitude.toStringAsFixed(5)),
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wency',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: point,
                          width: 48,
                          height: 54,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on_rounded, size: 48, color: AppColors.down),
                        ),
                      ]),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: Colors.white70,
                      child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(child: Text(t.dssMapHint, style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.input.lat.toStringAsFixed(4)}, ${widget.input.lon.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.input.resetLocation,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(t.dssResetLocation),
            ),
          ),
          const Divider(height: 18),
          Text(t.dssWeatherHere, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.ink)),
          const SizedBox(height: 8),
          _weatherBody(t),
        ],
      ),
    );
  }

  Widget _weatherBody(AppLocalizations t) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
    }
    final w = _w;
    if (_failed || w == null) {
      return Row(
        children: [
          Expanded(child: Text(t.dssWeatherFailed, style: const TextStyle(color: AppColors.muted))),
          TextButton(onPressed: _load, child: Text(t.tryAgain)),
        ],
      );
    }
    final glyph = glyphFor(w.code, isDay: w.isDay);
    return Row(
      children: [
        WeatherIcon(glyph: glyph, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${w.tempC.round()}°C',
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.ink)),
              Text(t.glyphLabel(glyph), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 2,
                children: [
                  _fact(Icons.thermostat_rounded, '${t.dssFeelsLike} ${w.feelsC.round()}°'),
                  _fact(Icons.water_drop_outlined, '${w.humidity}%'),
                  _fact(Icons.air_rounded, '${w.windKmh.round()} km/h'),
                  _fact(Icons.umbrella_outlined, '${w.rainNext24h.toStringAsFixed(1)} mm / 24h'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fact(IconData i, String s) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, size: 15, color: AppColors.leaf),
      const SizedBox(width: 3),
      Text(s, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
    ],
  );
}