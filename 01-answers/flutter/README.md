# Flutter — Pet Adoption Assessment

Answers to the Flutter portion of the GATES Full Stack Developer Assessment. A pet adoption screen showcasing OOP inheritance, a repository layer, and Material 3 UI with filtering and stateful "adopt" actions.

## Rubric mapping

| # | Requirement | Marks | Where |
|---|-------------|:-----:|-------|
| 1a | Abstract `Pet` class with `name`, `age`, `breed`, `isAdopted` | 1 | [`lib/models/pet.dart`](lib/models/pet.dart) |
| 1b | `Dog` (`isTrained` default false) and `Cat` (`isIndoor` default true) subclasses | 2 | [`lib/models/dog.dart`](lib/models/dog.dart), [`lib/models/cat.dart`](lib/models/cat.dart) |
| 2a | `PetRepository` returning mixed sample list | 2 | [`lib/repositories/pet_repository.dart`](lib/repositories/pet_repository.dart) |

Plus, per the assignment brief ("display a list… allow filtering by pet type… mark pets as adopted"):

- List of adoptable pets — [`lib/main.dart`](lib/main.dart) `PetListScreen`
- Filter by pet type (All / Dogs / Cats) — segmented button, `PetFilter` enum
- Mark as adopted — `Pet.adopt()`; UI updates via `setState`

## Design notes

- Abstract `Pet` — enforces the common contract; concrete subclasses add type-specific fields.
- `type` getter — overridden in each subclass; used by the UI for filtering and label rendering. Prevents leaking `instanceof`-style checks into presentation code.
- `PetRepository` — sits between UI and data. Currently hard-coded, but swappable to an HTTP or database source with no UI changes.
- `PetTile` widget — presentation-only, receives a `Pet` and an `onAdopt` callback. Uses Dart 3 pattern matching (`switch (pet)`) to render subclass-specific traits without downcasts scattered across the UI.

## Run

```bash
flutter pub get
flutter run           # pick a device: iOS Simulator / Android emulator / Chrome / macOS
flutter test          # unit tests
flutter analyze       # lints
```

## Project layout

```
lib/
  main.dart                     — MaterialApp + PetListScreen (filter + adopt)
  models/
    pet.dart                    — abstract Pet
    dog.dart                    — Dog extends Pet (isTrained)
    cat.dart                    — Cat extends Pet (isIndoor)
  repositories/
    pet_repository.dart         — sample data
  widgets/
    pet_tile.dart               — list item
test/
  pet_repository_test.dart      — covers models + repository
pubspec.yaml
analysis_options.yaml
```

> `flutter create .` was not run in this folder — only the assessment-specific Dart code and `pubspec.yaml` are here. To generate the platform folders (`ios/`, `android/`, `web/`, `macos/`, etc.), run `flutter create .` inside this directory; existing files will be preserved.
