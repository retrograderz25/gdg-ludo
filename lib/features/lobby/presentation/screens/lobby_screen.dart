import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gdg_ludo/features/lobby/data/lobby_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/lobby_provider.dart';

class LobbyScreen extends ConsumerWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersStream = ref.watch(playersInRoomProvider(roomId));
    final roomStream = ref.watch(roomStreamProvider(roomId));
    final currentUserId = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.id;

    // TODO: Lắng nghe trạng thái phòng để chuyển màn hình
    ref.listen(roomStreamProvider(roomId), (previous, next) {
      final status = next.value?['status'];
      // Khi status trong DB đổi thành 'in_progress', chuyển màn hình
      if (status == 'in_progress') {
        // Chuyển sang màn hình chơi game
        // Dùng `go` để thay thế màn hình hiện tại, người dùng không thể back lại lobby
        context.go('/game/$roomId');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: roomStream.when(
          data: (roomData) {
            final roomCode = roomData['room_code'] ?? '...';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Phòng: $roomCode'),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã phòng!')),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Text('Đang tải...'),
          error: (e, s) => const Text('Lỗi'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: playersStream.when(
              data: (players) {
                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return ListTile(
                      leading: Icon(
                        Icons.person,
                        color: Colors.primaries[player.color.index],
                      ),
                      title: Text(player.nickname),
                      subtitle: Text('ID: ${player.id.substring(0, 8)}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Lỗi: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            // Kết hợp cả 2 stream để quyết định trạng thái nút Bắt đầu
            child: playersStream.when(
              data: (players) => roomStream.when(
                data: (roomData) {
                  final hostUserIdFromRoom =
                      roomData['host_id']; // Đây là User ID của host
                  final currentUserId = ref
                      .watch(supabaseClientProvider)
                      .auth
                      .currentUser
                      ?.id;
                  final isHost = currentUserId == hostUserIdFromRoom;
                  final canStart = players.length >= 2;

                  String? hostPlayerId;
                  if (isHost) {
                    try {
                      // --- SỬA LỖI LOGIC TẠI ĐÂY ---
                      // Tìm người chơi (Player) có userId trùng với hostUserIdFromRoom,
                      // sau đó lấy ra Player ID của người đó.
                      hostPlayerId = players
                          .firstWhere((p) => p.userId == hostUserIdFromRoom)
                          .id;
                    } catch (e) {
                      hostPlayerId = null; // Không tìm thấy (trường hợp hiếm)
                    }
                  }

                  if (!isHost) {
                    return const Text('Chờ chủ phòng bắt đầu trận đấu...');
                  }

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: isHost && canStart && hostPlayerId != null
                        ? () async {
                            try {
                              await ref
                                  .read(supabaseClientProvider)
                                  .rpc(
                                    'start_game',
                                    params: {
                                      'p_room_id': roomId,
                                    },
                                  );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(
                                      'Lỗi khi bắt đầu trận: ${e.toString()}',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: Text(
                      canStart
                          ? 'Bắt đầu trận đấu'
                          : 'Cần ít nhất 2 người chơi',
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Lỗi: $e'),
            ),
          ),
        ],
      ),
    );
  }
}
