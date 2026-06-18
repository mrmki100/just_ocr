import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database/isar_service.dart';

// Adjust these import paths if your folder structure is slightly different
import 'features/dashboard/presentation/library_screen.dart'; 
import 'features/reader/book_notifier.dart';
import 'services/file_import_service_impl.dart';
import 'services/ocr_service_impl.dart';

void main() async {
  // 1. Enforce binding initialization before async native channels run
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Boot up the local Isar Database engine
  await IsarService.initialize();

  // 3. Initialize SharedPreferences for reading position persistence
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // 4. Overriding the abstract stubs injects concrete instances 
      // globally across the Riverpod graph without tight coupling.
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        fileImportServiceProvider.overrideWith((ref) => FileImportServiceImpl()),
        ocrServiceProvider.overrideWith((ref) => OcrServiceImpl()),
      ],
      child: const MyApp(), 
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'justOCR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const LibraryScreen(), 
    );
  }
}