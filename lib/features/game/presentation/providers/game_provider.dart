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

// Lắng nghe tất cả quân cờ trong phòng hiện tại từ VIEW 'room_pieces'
final piecesStreamProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, roomId) {
      final client = ref.watch(supabaseClientProvider);

      // Thay vì stream từ 'pieces' và cố gắng join,
      // chúng ta stream từ VIEW 'room_pieces' đã được join sẵn.
      return client
          .from('room_pieces') // <-- THAY ĐỔI QUAN TRỌNG
          .stream(primaryKey: ['id']) // 'id' là khóa chính của quân cờ
          .eq(
            'room_id',
            roomId,
          ) // <-- Bây giờ có thể lọc trực tiếp trên cột room_id
          .map((list) => list);
    });

// Provider để lưu danh sách ID của các quân cờ có thể di chuyển
final validMovesProvider = StateProvider<List<String>>((ref) => []);
