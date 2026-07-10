import 'package:flutter_test/flutter_test.dart';
import 'package:pet_adoption/models/cat.dart';
import 'package:pet_adoption/models/dog.dart';
import 'package:pet_adoption/repositories/pet_repository.dart';

void main() {
  group('PetRepository', () {
    final pets = PetRepository().getAll();

    test('returns 4 pets from the sample dataset', () {
      expect(pets.length, 4);
    });

    test('mixes Dog and Cat instances', () {
      expect(pets.whereType<Dog>().length, 2);
      expect(pets.whereType<Cat>().length, 2);
    });

    test('Dogs default isTrained to false unless specified', () {
      final rex = pets.whereType<Dog>().firstWhere((d) => d.name == 'Rex');
      final buddy = pets.whereType<Dog>().firstWhere((d) => d.name == 'Buddy');
      expect(rex.isTrained, isTrue);
      expect(buddy.isTrained, isFalse);
    });

    test('Cats default isIndoor to true unless specified', () {
      final mittens = pets.whereType<Cat>().firstWhere((c) => c.name == 'Mittens');
      final whiskers = pets.whereType<Cat>().firstWhere((c) => c.name == 'Whiskers');
      expect(mittens.isIndoor, isFalse);
      expect(whiskers.isIndoor, isTrue);
    });

    test('all pets start as not adopted', () {
      expect(pets.every((p) => !p.isAdopted), isTrue);
    });

    test('adopt() marks a pet as adopted', () {
      final buddy = pets.whereType<Dog>().firstWhere((d) => d.name == 'Buddy');
      buddy.adopt();
      expect(buddy.isAdopted, isTrue);
    });
  });
}
