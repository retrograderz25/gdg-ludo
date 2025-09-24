import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_ludo/core/providers/supabase_provider.dart';

import '../../../core/models/player.dart';

abstract class LobbyRepository {
  Future<String> createRoom(String hostNickname);
  Future<String> joinRoom({required String roomCode, required String nickname});
  Stream<List<Player>> getPlayersStream(String roomId);
}

// Provider lấy thông tin chi tiết của phòng theo thời gian thực
final roomStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, roomId) {
      final client = ref.watch(supabaseClientProvider);
      return client
          .from('rooms')
          .stream(primaryKey: ['id'])
          .eq('id', roomId)
          .limit(1)
          .map(
            (list) => list.isNotEmpty ? list.first : <String, dynamic>{},
          ); // Trả về phòng đầu tiên hoặc map rỗng
    });
