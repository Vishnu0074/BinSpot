import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/bin_provider.dart';

class AddBinScreen extends StatefulWidget {
  final LatLng initialLatLng;
  const AddBinScreen({super.key, required this.initialLatLng});

  @override
  State<AddBinScreen> createState() => _AddBinScreenState();
}

class _AddBinScreenState extends State<AddBinScreen> {
  String _type = 'bio';
  String _accessLevel = 'public';
  final _description = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    try {
      await context.read<BinProvider>().addBin(
        lat: widget.initialLatLng.latitude,
        lng: widget.initialLatLng.longitude,
        addedBy: auth.uid,
        type: _type,
        accessLevel: _accessLevel,
        description: _description.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bin added to the community map.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add bin: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF205C3B);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F1),
      appBar: AppBar(title: const Text('Add a community bin')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE4EFE6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: forest, size: 30),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pinned location', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('${widget.initialLatLng.latitude.toStringAsFixed(5)}, ${widget.initialLatLng.longitude.toStringAsFixed(5)}'),
                ])),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('What can go here?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Bin type',
                prefixIcon: Icon(Icons.recycling_rounded),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bio', child: Text('Organic / bio waste')),
                DropdownMenuItem(value: 'plastic', child: Text('Plastic recycling')),
                DropdownMenuItem(value: 'both', child: Text('Mixed / multiple waste types')),
              ],
              onChanged: _submitting ? null : (value) => setState(() => _type = value ?? 'bio'),
            ),
            const SizedBox(height: 22),
            const Text('Who can access this bin?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Choose the access level so people know whether they can enter the area.',
                style: TextStyle(color: Color(0xFF607064))),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _accessLevel,
              decoration: const InputDecoration(
                labelText: 'Access level',
                prefixIcon: Icon(Icons.lock_open_rounded),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public — open to everyone')),
                DropdownMenuItem(value: 'limited', child: Text('Limited entry — campus / office compound')),
                DropdownMenuItem(value: 'private', child: Text('Private — residents / authorised users')),
              ],
              onChanged: _submitting ? null : (value) => setState(() => _accessLevel = value ?? 'public'),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              maxLength: 240,
              decoration: const InputDecoration(
                labelText: 'Helpful note (optional)',
                hintText: 'e.g. Beside the main gate, open during office hours',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_location_alt_rounded),
                label: Text(_submitting ? 'Adding bin…' : 'Add to BinSpot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
