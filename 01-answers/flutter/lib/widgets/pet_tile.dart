import 'package:flutter/material.dart';

import '../models/cat.dart';
import '../models/dog.dart';
import '../models/pet.dart';

class PetTile extends StatelessWidget {
  final Pet pet;
  final VoidCallback onAdopt;

  const PetTile({super.key, required this.pet, required this.onAdopt});

  @override
  Widget build(BuildContext context) {
    final trait = switch (pet) {
      Dog(:final isTrained) => isTrained ? 'Trained' : 'Untrained',
      Cat(:final isIndoor) => isIndoor ? 'Indoor' : 'Outdoor',
      _ => '',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: pet is Dog ? Colors.brown[200] : Colors.pink[100],
          child: Text(pet.type[0], style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(
          pet.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: pet.isAdopted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('${pet.breed} · Age ${pet.age} · $trait'),
        trailing: pet.isAdopted
            ? const Chip(
                label: Text('Adopted'),
                backgroundColor: Color(0xFFE0F2E9),
                labelStyle: TextStyle(color: Color(0xFF1B5E20)),
              )
            : FilledButton.tonal(
                onPressed: onAdopt,
                child: const Text('Adopt'),
              ),
      ),
    );
  }
}
