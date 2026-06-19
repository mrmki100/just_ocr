import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Strictly using 'package:' imports prevents the Dart split-brain type mismatch!
import 'package:just_ocr/features/l10n/app_localizations.dart';
import 'package:just_ocr/features/l10n/app_language.dart'; 
import 'package:just_ocr/data/database/isar_service.dart';
import 'package:just_ocr/features/auth/presentation/login_screen.dart';
import 'package:just_ocr/features/dashboard/presentation/main_dashboard.dart';
import 'package:just_ocr/features/language/presentation/language_selection_screen.dart';
import 'package:just_ocr/services/file_import_service_impl.dart';
import 'package:just_ocr/services/ocr_service_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.initialize();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
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
        fontFamily: 'Vazirmatn', 
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
      
      // 2. This maps the button click to the actual Login Screen!
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}