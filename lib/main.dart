import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_ocr/features/l10n/app_localizations.dart';
import 'package:just_ocr/features/l10n/app_language.dart'; 
import 'package:just_ocr/data/database/isar_service.dart';
import 'package:just_ocr/features/auth/presentation/login_screen.dart';
import 'package:just_ocr/features/dashboard/presentation/main_dashboard.dart';
import 'package:just_ocr/features/language/presentation/language_selection_screen.dart';
import 'package:just_ocr/services/file_import_service_impl.dart';
import 'package:just_ocr/services/ocr_service_impl.dart';
import 'package:just_ocr/features/reader/book_notifier.dart';
import 'package:just_ocr/services/auth/auth_service_impl.dart';
import 'package:just_ocr/features/dashboard/presentation/settings_tab.dart'; // For selectedOcrModelProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.initialize();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final authService = AuthServiceImpl();
  await authService.initialize();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        fileImportServiceProvider.overrideWith((ref) => FileImportServiceImpl()),
        // OCR service will be created with the selected model dynamically
        ocrServiceProvider.overrideWith((ref) {
          final selectedModel = ref.watch(selectedOcrModelProvider);
          return OcrServiceImpl(prefs, modelName: selectedModel);
        }),
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
      localizationsDelegates: [
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

      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}