import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database/isar_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/main_dashboard.dart';
import 'features/reader/book_notifier.dart';
import 'features/language/presentation/language_selection_screen.dart';
import 'l10n/app_language.dart';
import 'l10n/app_localizations.dart';
import 'services/file_import_service_impl.dart';
import 'services/ocr_service_impl.dart';
import 'services/auth/auth_service_impl.dart';

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
        ocrServiceProvider.overrideWith((ref) => OcrServiceImpl(prefs)),
      ],
      child: const MyApp(), 
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(appLanguageProvider);
    
    return MaterialApp(
      title: 'justOCR',
      debugShowCheckedModeBanner: false,
      
      // Localization setup
      locale: appLanguage.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa'),
        Locale('nl'),
        Locale('ar'),
        Locale('en'),
      ],
      
      // RTL support
      builder: (context, child) {
        return Directionality(
          textDirection: appLanguage.textDirection,
          child: child!,
        );
      },
      
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        // Accessibility improvements
        fontFamily: 'Vazirmatn', // Consider adding a Persian font
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, height: 1.6),
          bodyMedium: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
      highContrastTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.highContrastLight(
          primary: Colors.black,
          secondary: Colors.black87,
          surface: Colors.white,
        ),
      ),
      home: const LanguageSelectionScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}