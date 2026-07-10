import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_adoption/app/theme/app_theme.dart';
import 'package:pet_adoption/features/pets/application/pet_providers.dart';
import 'package:pet_adoption/features/pets/data/in_memory_pet_repository.dart';
import 'package:pet_adoption/features/pets/presentation/pet_list_screen.dart';

Widget _harness() {
  return ProviderScope(
    overrides: [
      petRepositoryProvider.overrideWithValue(
        const InMemoryPetRepository(simulatedLatency: Duration.zero),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const PetListScreen(),
    ),
  );
}

Future<void> _mountWideCanvas(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_harness());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the header and all four pets after loading',
      (tester) async {
    await _mountWideCanvas(tester);

    expect(find.text('Find a friend'), findsOneWidget);
    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Mittens'), findsOneWidget);
    expect(find.text('Whiskers'), findsOneWidget);
  });

  testWidgets('filter chips narrow the list to a single species',
      (tester) async {
    await _mountWideCanvas(tester);

    await tester.tap(find.text('Dogs'));
    await tester.pumpAndSettle();

    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Buddy'), findsOneWidget);
    expect(find.text('Mittens'), findsNothing);
    expect(find.text('Whiskers'), findsNothing);
  });

  testWidgets('tapping Adopt me swaps the button for the adopted pill',
      (tester) async {
    await _mountWideCanvas(tester);

    final adoptButtons = find.text('Adopt me');
    expect(adoptButtons, findsWidgets);

    await tester.tap(adoptButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Adopted — going home'), findsOneWidget);
  });
}
