import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/player.dart';
import 'lobby_repository.dart';

class SupabaseLobbyRepository implements LobbyRepository {
  final SupabaseClient _client;

  SupabaseLobbyRepository(this._client);

  @override
  Future<String> createRoom(String hostNickname) async {
    try {
      // Gọi một Edge Function để xử lý logic tạo phòng một cách an toàn
      final data = await _client.rpc(
        'create_room',
        params: {'nickname': hostNickname},
      );
      // Function sẽ trả về room_id
      return data as String;
    } catch (e) {
      // Xử lý lỗi (ví dụ: log, rethrow)
      throw Exception('Failed to create room: $e');
    }
  }

  @override
  Future<String> joinRoom({
    required String roomCode,
    required String nickname,
  }) async {
    try {
      final data = await _client.rpc(
        'join_room',
        params: {'p_room_code': roomCode, 'nickname': nickname},
      );
      // Function sẽ trả về room_id
      return data as String;
    } on PostgrestException catch (e) {
      // Bắt lỗi cụ thể từ Supabase (ví dụ: phòng không tồn tại, phòng đầy)
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to join room: $e');
    }
  }

  @override
  Stream<List<Player>> getPlayersStream(String roomId) {
    // Lắng nghe thay đổi trên bảng 'players' theo thời gian thực
    return _client
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((listOfMaps) {
          // Chuyển đổi dữ liệu JSON thành danh sách đối tượng Player
          return listOfMaps
              .map((playerMap) => Player.fromJson(playerMap))
              .toList();
        });
  }
}
