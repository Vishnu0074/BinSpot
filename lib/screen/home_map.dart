import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../models/bin_point.dart';
import '../providers/auth_provider.dart';
import '../providers/bin_provider.dart';
import '../utils/location_utils.dart';
import 'add_bin_screen.dart';

class HomeMapScreen extends StatefulWidget {
  static const routeName = '/home';
  @override
  _HomeMapScreenState createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(13.0827, 80.2707); // default (Chennai) adjust for dev
  LatLng? _currentLocation;
  bool _loadingLocation = false;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationTimer;
  double _currentHeading = 0.0;
  double _mapRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _initializeLocation() async {
    final pos = await _determinePosition();
    if (pos != null) {
      final location = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = location;
        _currentLocation = location;
      });
      _mapController.move(_center, 15);
      
      // Update bin provider with current location
      if (mounted) {
        Provider.of<BinProvider>(context, listen: false)
            .updateCurrentLocation(location);
      }
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1, // Update only if moved at least 1 meter
          ),
        );
        
        final newLocation = LatLng(position.latitude, position.longitude);
        final heading = position.heading.isNaN ? 0.0 : (position.heading);
        
        // Only update if location actually changed significantly
        if (_currentLocation == null || 
            LocationUtils.calculateDistance(_currentLocation!, newLocation) > 5) {
          setState(() {
            _currentLocation = newLocation;
            _currentHeading = heading;
          });
          
          // Update bin provider with new location
          if (mounted) {
            Provider.of<BinProvider>(context, listen: false)
                .updateCurrentLocation(newLocation);
          }
        } else if (heading != _currentHeading) {
          setState(() {
            _currentHeading = heading;
          });
        }
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  Future<Position?> _determinePosition() async {
    setState(() { _loadingLocation = true; });
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() { _loadingLocation = false; });
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() { _loadingLocation = false; });
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() { _loadingLocation = false; });
        return null;
      }
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() { _loadingLocation = false; });
    return pos;
  }

  void _onMapLongPress(TapPosition tap, LatLng latlng) {
    // open add bin screen prefilled with latlng
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddBinScreen(initialLatLng: latlng)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bins = Provider.of<BinProvider>(context).bins;
    final binProvider = Provider.of<BinProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('BinSpot'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 16);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Location not available')),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              onLongPress: _onMapLongPress,
              onMapEvent: (MapEvent mapEvent) {
                if (mapEvent is MapEventRotateEnd || mapEvent is MapEventMove) {
                  setState(() {
                    _mapRotation = _mapController.camera.rotation;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.binspot',
              ),
              MarkerLayer(
                markers: [
                  // Current location marker - simple blue dot
                  if (_currentLocation != null)
                    Marker(
                      width: 20,
                      height: 20,
                      point: _currentLocation!,
                      alignment: Alignment.center,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  // Bin markers
                  ...bins.map((b) {
                  return Marker(
                    width: 40,
                    height: 50,
                    point: LatLng(b.lat, b.lng),
                    alignment: Alignment.bottomCenter,
                    rotate: false, // Prevent rotation with map
                      child: GestureDetector(
                        onTap: () {
                          _showBinBottomSheet(context, b);
                        },
                        child: Transform.translate(
                          offset: Offset(0, -5), // Fine-tune anchor point
                          child: Icon(
                            Icons.location_pin,
                            size: 40,
                            color: _getBinColor(b.type),
                          ),
                        ),
                    ),
                  );
                }).toList(),
                ],
              )
            ],
          ),
          // Compass widget
          Positioned(
            top: 16,
            right: 16,
            child: _buildCompass(),
          ),
          // Bottom sheet handle
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(binProvider),
          ),
        ],
      ),
      // Removed floating action button
    );
  }

  Color _getBinColor(String binType) {
    switch (binType.toLowerCase()) {
      case 'bio':
        return Colors.green;
      case 'plastic':
        return Colors.blue;
      case 'both':
        return Colors.purple;
      default:
        return Colors.green; // Default to bio/green
    }
  }

  IconData _getBinIcon(String binType) {
    switch (binType.toLowerCase()) {
      case 'bio':
        return Icons.delete;
      case 'plastic':
        return Icons.recycling;
      case 'both':
        return Icons.delete_forever;
      default:
        return Icons.delete;
    }
  }

  Widget _buildCompass() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: _currentHeading * (pi / 180),
        child: Icon(
          Icons.navigation,
          color: Colors.red,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BinProvider binProvider) {
    final nearbyBins = binProvider.getNearbyBinsSorted();
    
    return GestureDetector(
      onTap: () {
        _showNearbyBinsBottomSheet(binProvider, nearbyBins);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '${nearbyBins.length} nearby bins',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_up, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNearbyBinsBottomSheet(BinProvider binProvider, List<BinPoint> nearbyBins) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Nearby Bins',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${nearbyBins.length} found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // List of bins
              Expanded(
                child: nearbyBins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No nearby bins found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try expanding your search area',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: nearbyBins.length,
                        itemBuilder: (context, index) {
                          final bin = nearbyBins[index];
                          final distance = binProvider.getDistanceToBin(bin);
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _getBinColor(bin.type).withValues(alpha: 0.2),
                                child: Icon(
                                  _getBinIcon(bin.type),
                                  color: _getBinColor(bin.type),
                                ),
                              ),
                              title: Text(
                                bin.type.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text('Added by: ${bin.addedBy}'),
                                  SizedBox(height: 2),
                                  Text('Upvotes: ${bin.upvotes}'),
                                  if (distance != null) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      'Distance: ${distance < 1000 ? 
                                          '${distance.round()}m' : 
                                          '${(distance / 1000).toStringAsFixed(1)}km'}',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.thumb_up_outlined, color: Colors.green),
                                    onPressed: () {
                                      binProvider.upvote(bin.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Bin upvoted!')),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.directions, color: Colors.blue),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      try {
                                        await LocationUtils.openMapsNavigation(LatLng(bin.lat, bin.lng));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Could not open maps: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  // Show delete button only if current user added the bin
                                  if (bin.addedBy == Provider.of<AuthProvider>(context, listen: false).uid)
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        _showDeleteConfirmation(context, bin, binProvider);
                                      },
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _mapController.move(LatLng(bin.lat, bin.lng), 16);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, BinPoint bin, BinProvider binProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Bin'),
          content: Text('Are you sure you want to delete this ${bin.type} bin? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close bottom sheet
                try {
                  await binProvider.deleteBin(bin.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bin deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting bin: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showBinBottomSheet(BuildContext ctx, BinPoint b) {
    final binProv = Provider.of<BinProvider>(ctx, listen: false);
    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 220,
          decoration: BoxDecoration(
            color: Color(0xFFF5F5DC), // Light cream background
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bin — ${b.type}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 8),
              Text('Added by: ${b.addedBy}', style: TextStyle(color: Colors.black)),
              SizedBox(height: 8),
              Text('Upvotes: ${b.upvotes}', style: TextStyle(color: Colors.black)),
              Spacer(),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      binProv.upvote(b.id);
                      Navigator.of(ctx).pop();
                    },
                    icon: Icon(Icons.thumb_up),
                    label: Text('Verify / Upvote'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      try {
                        await LocationUtils.openMapsNavigation(LatLng(b.lat, b.lng));
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Could not open maps: $e')),
                        );
                      }
                    },
                    icon: Icon(Icons.directions),
                    label: Text('Navigate'),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}