import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gdg_ludo/features/auth/presentation/providers/auth_provider.dart';
import '../providers/lobby_provider.dart';
import '../widgets/join_room_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<String?>>(lobbyActionProvider, (previous, next) {
      next.when(
        data: (roomId) {
          if (roomId != null) {
            context.go('/lobby/$roomId');
          }
        },
        loading: () {},
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
        },
      );
    });

    final lobbyState = ref.watch(lobbyActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cờ Cá Ngựa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Gọi đúng provider đã được import
              ref.read(authActionProvider).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: lobbyState.isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                ref.read(lobbyActionProvider.notifier).createRoom('Host');
              },
              child: const Text('Tạo phòng'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => JoinRoomDialog(
                    onJoin: (roomCode) {
                      ref.read(lobbyActionProvider.notifier).joinRoom(roomCode, 'Player');
                    },
                  ),
                );
              },
              child: const Text('Tham gia phòng'),
            ),
          ],
        ),
      ),
    );
  }
}