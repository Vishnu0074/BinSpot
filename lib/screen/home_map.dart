import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/bin_point.dart';
import '../providers/auth_provider.dart';
import '../providers/bin_provider.dart';
import '../utils/location_utils.dart';
import 'add_bin_screen.dart';
import 'contributors_screen.dart';
import 'login_screen.dart';

class HomeMapScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  static const _forest = Color(0xFF205C3B);
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(9.2648, 76.7758);
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  bool _mapReady = false;
  double _mapZoom = 14;

  @override
  void initState() {
    super.initState();
    final savedLocation = context.read<BinProvider>().currentLocation;
    if (savedLocation != null) {
      _currentLocation = savedLocation;
      _center = savedLocation;
    }
    _watchLocation();
  }

  void _watchLocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 25,
      ),
    ).listen((position) {
      if (!mounted) return;
      final next = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = next;
        if (!_mapReady) _center = next;
      });
      context.read<BinProvider>().updateCurrentLocation(next);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Color _binColor(BinPoint bin) {
    if (bin.isRestricted) return const Color(0xFF858C87);
    switch (bin.type) {
      case 'plastic':
        return const Color(0xFF367DB5);
      case 'both':
        return const Color(0xFF8A62A8);
      default:
        return _forest;
    }
  }

  IconData _binIcon(BinPoint bin) {
    if (bin.isRestricted) return Icons.lock_rounded;
    switch (bin.type) {
      case 'plastic':
        return Icons.recycling_rounded;
      case 'both':
        return Icons.delete_sweep_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  String _accessLabel(BinPoint bin) {
    switch (bin.accessLevel) {
      case 'limited': return 'Limited entry';
      case 'private': return 'Private access';
      default: return 'Public';
    }
  }

  void _toggleMore() async {
    final provider = context.read<BinProvider>();
    await provider.toggleExpandedNearby();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(provider.showingMore
          ? 'Showing up to 100 bins within 5 km'
          : 'Showing the 20 closest bins'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _addBin() async {
    final point = _mapReady ? _mapController.camera.center : (_currentLocation ?? _center);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddBinScreen(initialLatLng: point)),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BinProvider>();
    final bins = provider.bins;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F1),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onMapReady: () => _mapReady = true,
              onPositionChanged: (camera, hasGesture) {
                if (_mapZoom != camera.zoom) {
                  setState(() => _mapZoom = camera.zoom);
                }
              },
              onLongPress: (_, _) => _toggleMore(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.binspot.app',
              ),
              CircleLayer(circles: [
                if (_currentLocation != null)
                  CircleMarker(
                    point: _currentLocation!,
                    radius: 24,
                    useRadiusInMeter: false,
                    color: _forest.withValues(alpha: 0.12),
                    borderColor: _forest.withValues(alpha: 0.35),
                    borderStrokeWidth: 1,
                  ),
              ]),
              MarkerLayer(markers: [
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D8CDE),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                    ),
                  ),
                ...bins.map((bin) {
                  // Keep the marker's tip anchored to the exact coordinate.
                  // Shrink markers as the map zooms out to reduce overlap and
                  // avoid making nearby pins look like they are in the wrong place.
                  final markerSize = (_mapZoom * 2.4).clamp(20.0, 40.0);
                  return Marker(
                    point: LatLng(bin.lat, bin.lng),
                    width: markerSize,
                    height: markerSize + 4,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showBinDetails(bin),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Icon(
                          Icons.location_pin,
                          size: markerSize,
                          color: _binColor(bin),
                        ),
                      ),
                    ),
                  );
                }),
              ]),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 5))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: _forest, borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 11),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BinSpot', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1D3828))),
                          Text('Cleaner places, together', style: TextStyle(fontSize: 11, color: Color(0xFF68786D))),
                        ],
                      )),
                      IconButton(
                        tooltip: 'Top contributors',
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContributorsScreen())),
                        icon: const Icon(Icons.emoji_events_outlined, color: _forest),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFF68786D)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.near_me_rounded, color: _forest, size: 17),
                        const SizedBox(width: 6),
                        Text(provider.showingMore ? 'Nearby area · up to 100 bins' : 'Nearby · 20 closest bins',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(children: [
                      _MapAction(icon: Icons.my_location_rounded, label: 'My location', onTap: () {
                        final location = _currentLocation;
                        if (location != null) _mapController.move(location, 16);
                      }),
                      const SizedBox(height: 10),
                      _MapAction(
                        icon: provider.showingMore ? Icons.filter_alt_off_rounded : Icons.explore_rounded,
                        label: provider.showingMore ? 'Show 20' : 'Explore more',
                        onTap: _toggleMore,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _buildNearbyCard(provider),
                ],
              ),
            ),
          ),
          if (provider.loading)
            const Positioned(top: 150, right: 18, child: SizedBox(
              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: _forest),
            )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBin,
        backgroundColor: _forest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add a bin', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildNearbyCard(BinProvider provider) {
    final nearby = provider.getNearbyBinsSorted();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showNearbyList(provider),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD6DDD7), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.radar_rounded, color: _forest, size: 25),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bins around you', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF20382A))),
                Text(provider.lastError != null ? 'Could not refresh bins' : '${nearby.length} shown · within 5 km',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF68786D))),
              ])),
              const Icon(Icons.keyboard_arrow_up_rounded, color: _forest, size: 27),
            ]),
            if (nearby.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearby.take(5).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final bin = nearby[index];
                    return ActionChip(
                      avatar: Icon(_binIcon(bin), color: _binColor(bin), size: 17),
                      label: Text('${_accessLabel(bin)} · ${_distanceLabel(provider.getDistanceToBin(bin))}'),
                      onPressed: () => _showBinDetails(bin),
                      backgroundColor: const Color(0xFFF5F7F1),
                      side: BorderSide.none,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 7),
            const Text('Tap to browse · Press and hold the map to reveal more nearby bins',
                style: TextStyle(fontSize: 11, color: Color(0xFF77847B))),
          ]),
        ),
      ),
    );
  }

  String _distanceLabel(double? meters) {
    if (meters == null) return 'distance unknown';
    return meters < 1000 ? '${meters.round()} m' : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _showNearbyList(BinProvider provider) {
    final bins = provider.getNearbyBinsSorted();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Color(0xFFF5F7F1), borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(children: [
                const Expanded(child: Text('Nearby bins', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800))),
                Text('${bins.length} found', style: const TextStyle(color: Color(0xFF68786D))),
              ]),
            ),
            Expanded(child: bins.isEmpty
                ? const Center(child: Text('No bins found in this area yet. Be the first to add one!'))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: bins.length,
                    itemBuilder: (context, index) {
                      final bin = bins[index];
                      final color = _binColor(bin);
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color.withValues(alpha: .13), child: Icon(_binIcon(bin), color: color)),
                          title: Text(bin.description.isEmpty ? '${bin.type.toUpperCase()} bin' : bin.description,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${_accessLabel(bin)} · ${_distanceLabel(provider.getDistanceToBin(bin))}\n${bin.upvotes} community confirmations',
                              style: TextStyle(color: bin.isRestricted ? const Color(0xFF777F79) : const Color(0xFF68786D))),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(context);
                            _mapController.move(LatLng(bin.lat, bin.lng), 17);
                          },
                        ),
                      );
                    },
                  )),
          ]),
        ),
      ),
    );
  }

  void _showBinDetails(BinPoint bin) {
    final color = _binColor(bin);
    final provider = context.read<BinProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 18),
          Row(children: [
            CircleAvatar(radius: 25, backgroundColor: color.withValues(alpha: .14), child: Icon(_binIcon(bin), color: color, size: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bin.description.isEmpty ? '${bin.type.toUpperCase()} bin' : bin.description, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(_accessLabel(bin), style: TextStyle(color: bin.isRestricted ? const Color(0xFF777F79) : _forest, fontWeight: FontWeight.w600)),
            ])),
          ]),
          const SizedBox(height: 12),
          Text('Added by ${bin.addedBy} · ${_distanceLabel(provider.getDistanceToBin(bin))}', style: const TextStyle(color: Color(0xFF68786D))),
          const SizedBox(height: 6),
          Text('${bin.upvotes} community confirmations', style: const TextStyle(color: Color(0xFF68786D))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(sheetContext);
                try {
                  await LocationUtils.openMapsNavigation(LatLng(bin.lat, bin.lng));
                } catch (_) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open your maps app.')));
                }
              },
              icon: const Icon(Icons.directions_rounded), label: const Text('Directions'),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _forest, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(sheetContext);
                try {
                  await provider.upvote(bin.id);
                } catch (error) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not confirm bin: $error')));
                }
              },
              icon: const Icon(Icons.verified_outlined), label: const Text('Confirm bin'),
            )),
          ]),
        ])),
      ),
    );
  }
}

class _MapAction extends StatelessWidget {
  const _MapAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    elevation: 4,
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFF205C3B), size: 23),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}
