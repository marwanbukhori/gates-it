import 'pet.dart';

abstract interface class PetRepository {
  Future<List<Pet>> fetchAll();
}
