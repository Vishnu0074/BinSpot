
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/bin_provider.dart';

class AddBinScreen extends StatefulWidget {
  final LatLng initialLatLng;
  AddBinScreen({required this.initialLatLng});

  @override
  _AddBinScreenState createState() => _AddBinScreenState();
}

class _AddBinScreenState extends State<AddBinScreen> {
  String _type = 'bio';
  bool _submitting = false;

  void _submit() async {
    setState(() { _submitting = true; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final binProv = Provider.of<BinProvider>(context, listen: false);
    try {
      await binProv.addBin(
        lat: widget.initialLatLng.latitude,
        lng: widget.initialLatLng.longitude,
        addedBy: auth.uid,
        type: _type,
      );
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bin added!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Bin'),
      ),
      body: Container(
        color: Color(0xFFF5F5DC), // Light cream background
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
            Text(
              'Location: ${widget.initialLatLng.latitude.toStringAsFixed(6)}, ${widget.initialLatLng.longitude.toStringAsFixed(6)}',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              items: [
                DropdownMenuItem(value: 'bio', child: Text('Bio')),
                DropdownMenuItem(value: 'plastic', child: Text('Plastic')),
                DropdownMenuItem(value: 'both', child: Text('Both (Bio + Plastic)')),
              ],
              onChanged: (v) { setState(() { _type = v ?? 'bio'; }); },
              decoration: InputDecoration(
                labelText: 'Bin Type',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting ? CircularProgressIndicator() : Text('Add Bin'),
            )
            ],
          ),
        ),
      ),
    );
  }
}
