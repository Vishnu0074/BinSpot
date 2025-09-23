import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../models/bin_point.dart';
import '../providers/auth_provider.dart';
import '../providers/bin_provider.dart';
import 'add_bin_screen.dart';

class HomeMapScreen extends StatefulWidget {
  static const routeName = '/home';
  @override
  _HomeMapScreenState createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(13.0827, 80.2707); // default (Chennai) adjust for dev
  bool _loadingLocation = false;
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      if (pos != null) {
        setState(() {
          _center = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_center, 15);
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('BinSpot'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () async {
              final pos = await _determinePosition();
              if (pos != null) {
                _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get location')));
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
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _center,
          zoom: 13.0,
          onLongPress: _onMapLongPress,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.binspot',
          ),
          MarkerLayer(
            markers: bins.map((b) {
              return Marker(
                width: 80,
                height: 80,
                point: LatLng(b.lat, b.lng),
                builder: (ctx) => GestureDetector(
                  onTap: () {
                    _showBinBottomSheet(context, b);
                  },
                  child: Column(
                    children: [
                      Icon(Icons.delete, size: 28, color: Colors.greenAccent),
                      Container(
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(b.type, style: TextStyle(fontSize: 10)),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // add bin at current center location
          final center = _mapController.center;
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddBinScreen(initialLatLng: center)));
        },
        label: Text('Add Bin'),
        icon: Icon(Icons.add_location_alt),
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bin — ${b.type}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Added by: ${b.addedBy}'),
              SizedBox(height: 8),
              Text('Upvotes: ${b.upvotes}'),
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
                    onPressed: () {
                      // open in maps or do routing — for now move camera
                      _mapController.move(LatLng(b.lat, b.lng), 17);
                      Navigator.of(ctx).pop();
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
