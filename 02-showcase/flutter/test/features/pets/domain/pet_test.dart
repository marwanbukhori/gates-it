import 'package:flutter_test/flutter_test.dart';
import 'package:pet_adoption/features/pets/domain/cat.dart';
import 'package:pet_adoption/features/pets/domain/dog.dart';

void main() {
  group('Dog', () {
    test('exposes species and defaults isTrained to false', () {
      const dog = Dog(id: 'a', name: 'Rex', age: 2, breed: 'Labrador');
      expect(dog.species, 'Dog');
      expect(dog.isTrained, isFalse);
      expect(dog.isAdopted, isFalse);
    });

    test('copyWith updates isAdopted without touching other fields', () {
      const dog = Dog(id: 'a', name: 'Rex', age: 2, breed: 'Labrador', isTrained: true);
      final adopted = dog.copyWith(isAdopted: true);
      expect(adopted.isAdopted, isTrue);
      expect(adopted.isTrained, isTrue);
      expect(adopted.name, 'Rex');
      expect(identical(dog, adopted), isFalse);
    });

    test('equality is driven by id + isAdopted', () {
      const a = Dog(id: 'a', name: 'Rex', age: 2, breed: 'Labrador');
      const b = Dog(id: 'a', name: 'Rex', age: 2, breed: 'Labrador');
      expect(a, equals(b));
      expect(a, isNot(equals(a.copyWith(isAdopted: true))));
    });
  });

  group('Cat', () {
    test('exposes species and defaults isIndoor to true', () {
      const cat = Cat(id: 'a', name: 'Whiskers', age: 4, breed: 'Persian');
      expect(cat.species, 'Cat');
      expect(cat.isIndoor, isTrue);
    });

    test('copyWith preserves species-specific fields', () {
      const cat = Cat(id: 'a', name: 'Whiskers', age: 4, breed: 'Persian', isIndoor: false);
      final adopted = cat.copyWith(isAdopted: true);
      expect(adopted.isAdopted, isTrue);
      expect(adopted.isIndoor, isFalse);
    });
  });
}
