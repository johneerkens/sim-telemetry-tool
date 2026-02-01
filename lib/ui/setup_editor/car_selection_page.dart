import 'package:flutter/material.dart';
import '../../core/models/mock_data.dart';

class CarSelectionPage extends StatelessWidget {
  const CarSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Car')),
      body: ListView.separated(
        itemCount: mockCars.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final carModel = mockCars[i];
          final car = Car(
            name: carModel.name,
            // Add other fields as necessary to map from CarModel to Car
          );
          return ListTile(
            title: Text(car.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackSelectionPage(car: car),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TrackSelectionPage extends StatelessWidget {
  final Car car;
  const TrackSelectionPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Track for ${car.name}')),
      body: Center(child: Text('Track selection goes here')),
    );
  }
}

class Car {
  final String name;
  // Add other fields as necessary

  Car({required this.name});
}
