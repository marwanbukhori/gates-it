import 'package:flutter/material.dart';

import '../features/pets/presentation/pet_list_screen.dart';
import 'theme/app_theme.dart';

class PetAdoptionApp extends StatelessWidget {
  const PetAdoptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home for Every Paw',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const PetListScreen(),
    );
  }
}
