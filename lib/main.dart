// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_screen.dart'
    hide authStateStreamProvider;
import 'features/game/presentation/screens/game_screen.dart';
import 'features/lobby/presentation/screens/home_screen.dart';
import 'features/lobby/presentation/screens/lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mgovyobwxallxveuzytl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3Z5b2J3eGFsbHh2ZXV6eXRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2NDQzODMsImV4cCI6MjA3NDIyMDM4M30.G_DGDH5k6VNVkpLfh4s1UdL6E63DyqdRkUyqlx2aIBY',
  );

  // Xóa logic đăng nhập ẩn danh ở đây

  runApp(const ProviderScope(child: MyApp()));
}

// Chuyển GoRouter ra ngoài để có thể truy cập ref
final _routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateStreamProvider);
  final authStream = ref.watch(authStateStreamProvider.future);

  return GoRouter(
    // Lắng nghe thay đổi để tự động refresh router
    refreshListenable: GoRouterRefreshStream(authStream.asStream()),
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.value?.session?.user != null;
      final isLoggingIn = state.matchedLocation == '/auth';

      // Nếu chưa đăng nhập và không ở trang auth -> chuyển đến trang auth
      if (!isLoggedIn && !isLoggingIn) {
        return '/auth';
      }

      // Nếu đã đăng nhập và đang ở trang auth -> chuyển đến trang chủ
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null; // Không cần chuyển hướng
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/lobby/:room_id',
        builder: (context, state) {
          final roomId = state.pathParameters['room_id']!;
          return LobbyScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/game/:room_id',
        builder: (context, state) {
          final roomId = state.pathParameters['room_id']!;
          return GameScreen(roomId: roomId);
        },
      ),
    ],
  );
});

// Helper class cho GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'Cờ Cá Ngựa Multiplayer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
