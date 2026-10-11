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
  bool _loading = false;
  bool _showMore = false;
  static const double searchRadiusKm = 5;
  static const int defaultLimit = 20;
  static const int expandedLimit = 100;

  List<BinPoint> get bins => List.unmodifiable(_bins);
  List<BinPoint> get allBins => List.unmodifiable(_allBins);
  String? get lastError => _lastError;
  bool get loading => _loading;
  bool get showingMore => _showMore;
  LatLng? get currentLocation => _currentLocation;

  Future<void> initialize() => refresh();

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final location = _currentLocation;
      final query = location == null
          ? ''
          : '?lat=${location.latitude}&lng=${location.longitude}'
              '&radius_km=$searchRadiusKm&limit=${_showMore ? expandedLimit : defaultLimit}';
      final response = await _api.get('/bins/$query', authenticated: false);
      final list = response['results'] ?? response['data'] ?? [];
      if (list is List) {
        _allBins = list.whereType<Map>()
            .map((item) => BinPoint.fromMap(Map<String, dynamic>.from(item))).toList();
      }
      _bins = List.of(_allBins);
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void updateCurrentLocation(LatLng location) {
    if (_currentLocation != null &&
        LocationUtils.calculateDistance(_currentLocation!, location) < 25) return;
    _currentLocation = location;
    refresh();
  }

  Future<void> toggleExpandedNearby() async {
    _showMore = !_showMore;
    await refresh();
  }

  Future<void> addBin({
    required double lat,
    required double lng,
    required String addedBy,
    String type = 'bio',
    String accessLevel = 'public',
    String description = '',
  }) async {
    await _api.post('/bins/', body: {
      'latitude': lat,
      'longitude': lng,
      'description': description,
      'type': type,
      'access_level': accessLevel,
    });
    await refresh();
  }

  Future<void> upvote(String id) async {
    await _api.post('/bins/$id/upvote/', authenticated: false);
    await refresh();
  }

  Future<void> deleteBin(String id) async {
    await _api.delete('/bins/$id/');
    await refresh();
  }

  List<BinPoint> getNearbyBinsSorted() {
    if (_currentLocation == null) return List.of(_bins);
    final sorted = List<BinPoint>.of(_bins);
    sorted.sort((a, b) => (getDistanceToBin(a) ?? double.infinity)
        .compareTo(getDistanceToBin(b) ?? double.infinity));
    return sorted;
  }

  double? getDistanceToBin(BinPoint bin) => _currentLocation == null
      ? null
      : LocationUtils.calculateDistance(_currentLocation!, LatLng(bin.lat, bin.lng));
}
