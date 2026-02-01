import 'dart:convert';
import '../models/car_setup.dart';
import 'database.dart';

class SetupRepository {
  Future<void> insert(CarSetup setup) async {
    final db = await AppDatabase.instance();

    await db.insert('setups', {
      'id': setup.id,
      'car_id': setup.carId,
      'track_id': setup.trackId,
      'name': setup.name,
      'created_at': setup.createdAt.millisecondsSinceEpoch,
      'parameters': jsonEncode(setup.parameters),
    });
  }

  Future<List<CarSetup>> listByCarAndTrack(
    String carId,
    String trackId,
  ) async {
    final db = await AppDatabase.instance();

    final rows = await db.query(
      'setups',
      where: 'car_id = ? AND track_id = ?',
      whereArgs: [carId, trackId],
      orderBy: 'created_at DESC',
    );

    return rows.map((r) {
      return CarSetup(
        id: r['id'] as String,
        carId: r['car_id'] as String,
        trackId: r['track_id'] as String,
        name: r['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          r['created_at'] as int,
        ),
        parameters: jsonDecode(r['parameters'] as String),
      );
    }).toList();
  }
}
