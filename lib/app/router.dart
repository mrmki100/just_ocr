import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/main_dashboard.dart';

// This is the main router for the entire app.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainDashboard(),
    ),
    // We will add the /reader and /settings routes here later
  ],
);