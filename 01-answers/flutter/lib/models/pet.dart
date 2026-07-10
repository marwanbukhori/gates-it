abstract class Pet {
  final String name;
  final int age;
  final String breed;
  bool isAdopted;

  Pet({
    required this.name,
    required this.age,
    required this.breed,
    this.isAdopted = false,
  });

  String get type;

  void adopt() {
    isAdopted = true;
  }
}
