import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/models/player.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/lobby_repository.dart';
import '../../data/supabase_lobby_repository.dart';

// Provider cho Repository
final lobbyRepositoryProvider = Provider<LobbyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseLobbyRepository(client);
});

// Provider để lấy danh sách người chơi trong phòng (dạng Stream)
final playersInRoomProvider = StreamProvider.autoDispose
    .family<List<Player>, String>((ref, roomId) {
      final lobbyRepo = ref.watch(lobbyRepositoryProvider);
      return lobbyRepo.getPlayersStream(roomId);
    });

// State Notifier để xử lý các hành động tạo/tham gia phòng
final lobbyActionProvider =
    StateNotifierProvider<LobbyActionNotifier, AsyncValue<String?>>((ref) {
      return LobbyActionNotifier(ref.watch(lobbyRepositoryProvider));
    });

class LobbyActionNotifier extends StateNotifier<AsyncValue<String?>> {
  final LobbyRepository _repository;

  LobbyActionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createRoom(String nickname) async {
    state = const AsyncValue.loading();
    try {
      final roomId = await _repository.createRoom(nickname);
      state = AsyncValue.data(roomId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> joinRoom(String roomCode, String nickname) async {
    state = const AsyncValue.loading();
    try {
      final roomId = await _repository.joinRoom(
        roomCode: roomCode,
        nickname: nickname,
      );
      state = AsyncValue.data(roomId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
