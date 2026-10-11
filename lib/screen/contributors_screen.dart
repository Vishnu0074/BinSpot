import 'package:flutter/material.dart';

import '../services/api_client.dart';

class ContributorsScreen extends StatefulWidget {
  const ContributorsScreen({super.key});

  @override
  State<ContributorsScreen> createState() => _ContributorsScreenState();
}

class _ContributorsScreenState extends State<ContributorsScreen> {
  late Future<List<dynamic>> _contributors;

  @override
  void initState() {
    super.initState();
    _contributors = _load();
  }

  Future<List<dynamic>> _load() async {
    final result = await ApiClient.instance.get('/contributors/top/', authenticated: false);
    return (result['results'] as List<dynamic>? ?? []);
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF205C3B);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F1),
      appBar: AppBar(title: const Text('Community champions')),
      body: FutureBuilder<List<dynamic>>(
        future: _contributors,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load the leaderboard. ${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Be the first to plant a seed for a cleaner community.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(22)),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.forest_rounded, size: 36, color: Color(0xFFD8E9B5)),
                  SizedBox(height: 10),
                  Text('Small actions. Greener places.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Celebrating the people who help everyone find a bin.', style: TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 18),
              ...items.map((item) {
                final rank = item['rank'] as int? ?? 0;
                final count = item['bins_count'] as int? ?? 0;
                final title = item['title']?.toString() ?? 'Seed Planter';
                final name = item['display_name']?.toString() ?? 'Community member';
                final medal = rank == 1 ? '🌳' : rank == 2 ? '🌿' : rank == 3 ? '🍃' : '🌱';
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE4EFE6),
                      child: Text(medal, style: const TextStyle(fontSize: 21)),
                    ),
                    title: Text('$rank. $name', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(title),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: forest)),
                      const Text('bins', style: TextStyle(fontSize: 11)),
                    ]),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
