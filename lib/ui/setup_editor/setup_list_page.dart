import 'package:flutter/material.dart';
import '../../core/models/car_setup.dart';
import '../../core/storage/setup_repository.dart';

class SetupListPage extends StatefulWidget {
  const SetupListPage({
    super.key,
    required this.carId,
    required this.trackId,
  });

  final String carId;
  final String trackId;

  @override
  State<SetupListPage> createState() => _SetupListPageState();
}

class _SetupListPageState extends State<SetupListPage> {
  final _repo = SetupRepository();
  late Future<List<CarSetup>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.listByCarAndTrack(widget.carId, widget.trackId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _repo.listByCarAndTrack(widget.carId, widget.trackId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setups')),
      body: FutureBuilder<List<CarSetup>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final setups = snapshot.data!;
          if (setups.isEmpty) {
            return const Center(child: Text('No setups yet'));
          }

          return ListView.separated(
            itemCount: setups.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = setups[i];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(
                  'Created: ${s.createdAt.toLocal()}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SetupDetailPage(setup: s),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _repo.insert(
            CarSetup(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              carId: widget.carId,
              trackId: widget.trackId,
              name: 'Mock setup ${DateTime.now().second}',
              createdAt: DateTime.now(),
              parameters: {'aero': 5, 'rideHeight': 60},
            ),
          );
          await _reload();
        },
        tooltip: 'Add mock setup',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SetupDetailPage extends StatelessWidget {
  final CarSetup setup;

  const SetupDetailPage({super.key, required this.setup});

  @override
  Widget build(BuildContext context) {
    // ...your detail page UI...
    return Scaffold(
      appBar: AppBar(title: Text(setup.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Setup details here'),
      ),
    );
  }
}
