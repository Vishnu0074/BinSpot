import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/bin_provider.dart';
import 'home_map.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Finding your place in the community…';
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    while (!auth.initialized && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    try {
      setState(() => _status = 'Checking location permission…');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever && mounted) {
        setState(() => _status = 'Enable location permission in Settings for nearby bins.');
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (enabled) {
          setState(() => _status = 'Loading bins near you…');
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 12),
            ),
          );
          if (!mounted) return;
          context.read<BinProvider>().updateCurrentLocation(
            LatLng(position.latitude, position.longitude),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Location unavailable — you can still explore.');
    }

    if (!mounted) return;
    await context.read<BinProvider>().refresh();
    if (!mounted) return;
    setState(() => _finished = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => context.read<AuthProvider>().isAuthenticated
            ? HomeMapScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF205C3B);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(30)),
                child: const Icon(Icons.eco_rounded, size: 58, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('BinSpot', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: forest)),
              const SizedBox(height: 8),
              const Text('Find it. Share it. Keep it clean.', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF52685A))),
              const SizedBox(height: 28),
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: forest)),
              const SizedBox(height: 14),
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF52685A))),
              if (_finished) const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
