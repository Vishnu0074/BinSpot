import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/bin_point.dart';
import '../services/api_client.dart';
import '../utils/location_utils.dart';

class BinProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;
  List<BinPoint> _bins = [];
  List<BinPoint> _allBins = [];
  LatLng? _currentLocation;
  String? _lastError;
  Timer? _refreshTimer;
  bool _loading = false;
  static const double _searchRadiusMeters = 5000;

  List<BinPoint> get bins => List.unmodifiable(_bins);
  List<BinPoint> get allBins => List.unmodifiable(_allBins);
  String? get lastError => _lastError;
  bool get loading => _loading;

  BinProvider() {
    refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final response = await _api.get('/bins/');
      final list = response['results'] ?? response['data'] ?? [];
      if (list is List) {
        _allBins = list.whereType<Map>()
            .map((item) => BinPoint.fromMap(Map<String, dynamic>.from(item))).toList();
      }
      _lastError = null;
      _filterBinsByLocation();
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void updateCurrentLocation(LatLng location) {
    _currentLocation = location;
    _filterBinsByLocation();
    notifyListeners();
  }

  void _filterBinsByLocation() {
    if (_currentLocation == null) {
      _bins = List.of(_allBins);
      return;
    }
    final nearby = _allBins.where((bin) => LocationUtils.isWithinRadius(
      _currentLocation!, LatLng(bin.lat, bin.lng), _searchRadiusMeters,
    )).toList();
    _bins = nearby.isNotEmpty ? nearby : List.of(_allBins);
  }

  Future<void> addBin({required double lat, required double lng,
      required String addedBy, String type = 'bio'}) async {
    await _api.post('/bins/', body: {
      'latitude': lat,
      'longitude': lng,
      'description': type,
      'type': type,
    });
    await refresh();
  }

  Future<void> upvote(String id) async {
    await _api.post('/bins/$id/upvote/');
    await refresh();
  }

  Future<void> deleteBin(String id) async {
    await _api.delete('/bins/$id/');
    await refresh();
  }

  List<BinPoint> getNearbyBinsSorted() {
    if (_currentLocation == null) return List.of(_allBins);
    final sorted = List<BinPoint>.of(_allBins);
    sorted.sort((a, b) => LocationUtils.calculateDistance(
      _currentLocation!, LatLng(a.lat, a.lng),
    ).compareTo(LocationUtils.calculateDistance(
      _currentLocation!, LatLng(b.lat, b.lng),
    )));
    return sorted.where((bin) => LocationUtils.calculateDistance(
      _currentLocation!, LatLng(bin.lat, bin.lng),
    ) <= 10000).toList();
  }

  double? getDistanceToBin(BinPoint bin) => _currentLocation == null
      ? null
      : LocationUtils.calculateDistance(_currentLocation!, LatLng(bin.lat, bin.lng));
}
