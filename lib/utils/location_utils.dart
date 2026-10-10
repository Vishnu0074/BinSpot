import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationUtils {
  static const double _earthRadiusMeters = 6371000;

  static double calculateDistance(LatLng from, LatLng to) {
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);
    final deltaLat = _degreesToRadians(to.latitude - from.latitude);
    final deltaLon = _degreesToRadians(to.longitude - from.longitude);
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    final clamped = a.clamp(0.0, 1.0);
    return _earthRadiusMeters *
        2 *
        math.atan2(math.sqrt(clamped), math.sqrt(1 - clamped));
  }

  static bool isWithinRadius(LatLng center, LatLng point, double radiusMeters) {
    return calculateDistance(center, point) <= radiusMeters;
  }

  static Future<void> openMapsNavigation(LatLng destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open a maps application.');
    }
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}