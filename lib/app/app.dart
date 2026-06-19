import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../providers/theme_provider.dart';

class JustOcrApp extends ConsumerWidget {
  const JustOcrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    // Notice we changed MaterialApp to MaterialApp.router
    return MaterialApp.router(
      title: 'justOCR',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      // Plug in our GoRouter configuration
      routerConfig: appRouter,
    );
  }
}