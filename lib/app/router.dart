import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/library_screen.dart';

// This is the main router for the entire app.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LibraryScreen(),
    ),
    // We will add the /reader and /settings routes here later
  ],
);