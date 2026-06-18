import 'package:flutter/material.dart';
import 'router.dart';

class JustOcrApp extends StatelessWidget {
  const JustOcrApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Notice we changed MaterialApp to MaterialApp.router
    return MaterialApp.router(
      title: 'justOCR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Plug in our GoRouter configuration
      routerConfig: appRouter,
    );
  }
}