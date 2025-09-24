import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/providers/supabase_provider.dart';

// Lắng nghe bảng game_state của phòng hiện tại
final gameStateStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, roomId) {
      final client = ref.watch(supabaseClientProvider);
      return client
          .from('game_state')
          .stream(primaryKey: ['room_id'])
          .eq('room_id', roomId)
          .map((list) => list.isNotEmpty ? list.first : {});
    });

// Lắng nghe tất cả quân cờ trong phòng hiện tại
final piecesStreamProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, roomId) {
      final client = ref.watch(supabaseClientProvider);
      // Chúng ta cần join với bảng players để lấy nickname
      return client
          .from('room_pieces')
          .stream(primaryKey: ['id'])
          .eq('player.room_id', roomId) // Lọc theo room_id của người chơi
          .map((list) => list);
    });

// Provider để lưu danh sách ID của các quân cờ có thể di chuyển
final validMovesProvider = StateProvider<List<String>>((ref) => []);
