import 'package:flutter/material.dart';

import 'models/cat.dart';
import 'models/dog.dart';
import 'models/pet.dart';
import 'repositories/pet_repository.dart';
import 'widgets/pet_tile.dart';

void main() => runApp(const PetAdoptionApp());

class PetAdoptionApp extends StatelessWidget {
  const PetAdoptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Adoption',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const PetListScreen(),
    );
  }
}

enum PetFilter { all, dog, cat }

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  final PetRepository _repository = PetRepository();
  late final List<Pet> _pets = _repository.getAll();
  PetFilter _filter = PetFilter.all;

  List<Pet> get _visiblePets {
    return switch (_filter) {
      PetFilter.all => _pets,
      PetFilter.dog => _pets.whereType<Dog>().toList(),
      PetFilter.cat => _pets.whereType<Cat>().toList(),
    };
  }

  void _adopt(Pet pet) {
    setState(() => pet.adopt());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${pet.name} has been adopted!')));
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePets;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoptable Pets'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SegmentedButton<PetFilter>(
              segments: const [
                ButtonSegment(value: PetFilter.all, label: Text('All')),
                ButtonSegment(value: PetFilter.dog, label: Text('Dogs')),
                ButtonSegment(value: PetFilter.cat, label: Text('Cats')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('No pets to show.'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final pet = visible[index];
                      return PetTile(pet: pet, onAdopt: () => _adopt(pet));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
