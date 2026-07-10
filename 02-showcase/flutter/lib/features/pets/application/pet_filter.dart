enum PetFilter {
  all('All'),
  dogs('Dogs'),
  cats('Cats');

  final String label;
  const PetFilter(this.label);
}
