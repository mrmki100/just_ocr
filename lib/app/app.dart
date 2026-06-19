import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import '../providers/theme_provider.dart';
import '../features/l10n/app_localizations.dart';
import '../features/language/presentation/language_selection_screen.dart';

class JustOcrApp extends ConsumerWidget {
  const JustOcrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final currentLanguage = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'justOCR',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: appRouter,
      
      // --- Localization Configuration ---
      locale: currentLanguage.locale,
      supportedLocales: const [
        Locale('fa'), // Persian
        Locale('en'), // English
        Locale('ar'), // Arabic
        Locale('nl'), // Dutch
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}