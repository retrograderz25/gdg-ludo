import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/game_provider.dart';
import '../utils/board_mapper.dart';

// Provider để lấy thông tin của người chơi hiện tại (chỉ một lần)
final myPlayerInfoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, roomId) {
      final client = ref.watch(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      return client
          .from('players')
          .select('color')
          .eq('user_id', userId)
          .eq('room_id', roomId)
          .single()
          .then((data) => data);
    });

class GameScreen extends ConsumerWidget {
  final String roomId;
  const GameScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateStreamProvider(roomId));
    final pieces = ref.watch(piecesStreamProvider(roomId));
    final myPlayerInfo = ref.watch(myPlayerInfoProvider(roomId));
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final validMoves = ref.watch(validMovesProvider);

    // Xử lý logic di chuyển quân cờ
    void handleMovePiece(String pieceId) async {
      try {
        await ref
            .read(supabaseClientProvider)
            .rpc(
              'move_piece',
              params: {'p_piece_id': pieceId},
            );
        ref.read(validMovesProvider.notifier).state = [];
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ván Cờ Bắt Đầu!'),
      ),
      body: gameState.when(
        data: (state) {
          if (state.isEmpty) {
            return const Center(child: Text('Đang chờ trạng thái game...'));
          }
          final currentTurnPlayerId = state['current_turn_player_id'];
          final isMyTurn = currentTurnPlayerId == myUserId;
          final diceRoll = state['last_dice_roll'];

          return Column(
            children: [
              // ---- KHU VỰC THÔNG TIN ----
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      isMyTurn ? 'ĐẾN LƯỢT BẠN!' : 'Đang chờ đối thủ...',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    if (diceRoll != null)
                      Text(
                        'Xúc xắc vừa tung: $diceRoll',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                  ],
                ),
              ),

              // ---- NÚT TUNG XÚC XẮC ----
              if (isMyTurn && diceRoll == null) // Chỉ hiện nút khi chưa tung
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final result = await ref
                            .read(supabaseClientProvider)
                            .rpc(
                              'roll_dice',
                              params: {'p_room_id': roomId},
                            );
                        // Cập nhật StateProvider với danh sách các quân cờ có thể đi
                        final moves = (result['valid_moves'] as List)
                            .map((e) => e.toString())
                            .toList();
                        ref.read(validMovesProvider.notifier).state = moves;
                      } catch (e) {
                        /* ... xử lý lỗi ... */
                      }
                    },
                    child: const Text('Tung Xúc Xắc'),
                  ),
                ),

              const Divider(height: 30),

              // ---- HIỂN THỊ QUÂN CỜ CÓ THỂ TƯƠNG TÁC ----
              // ---- THAY THẾ LISTVIEW BẰNG BÀN CỜ VISUAL ----
              Expanded(
                child: pieces.when(
                  data: (pieceList) {
                    return myPlayerInfo.when(
                      // Chỉ khi có thông tin màu của người chơi thì mới vẽ bàn cờ
                      data: (playerInfo) {
                        if (playerInfo == null) {
                          return const Center(
                            child: Text("Không tìm thấy thông tin người chơi."),
                          );
                        }
                        final myColor = playerInfo['color'];

                        // Map để theo dõi index của các quân cờ trong chuồng của mỗi màu
                        final homeIndices = <String, int>{};

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final boardSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            final mapper = BoardMapper(
                              boardSize: boardSize,
                              myColor: myColor,
                            );

                            return Stack(
                              children: [
                                // 1. Vẽ nền bàn cờ
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/board.png',
                                  ), // <-- Thay thế bằng ảnh bàn cờ của bạn
                                ),

                                // 2. Vẽ các quân cờ
                                ...pieceList.map((piece) {
                                  final pieceId = piece['id'].toString();
                                  final pieceColor = piece['color'].toString();
                                  final position = piece['position'] as int;
                                  final isMyPiece =
                                      piece['player_id'] == myUserId;
                                  final canMove = validMoves.contains(pieceId);

                                  int homeIndex = 0;
                                  if (position == 0) {
                                    homeIndex = homeIndices[pieceColor] ?? 0;
                                    homeIndices[pieceColor] = homeIndex + 1;
                                  }

                                  final offset = mapper.getOffsetForPiece(
                                    pieceColor: pieceColor,
                                    logicalPosition: position,
                                    homeIndex: homeIndex,
                                  );

                                  // Giảm kích thước quân cờ một chút
                                  final pieceSize = mapper.cellSize * 0.8;

                                  return AnimatedPositioned(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    left:
                                        offset.dx -
                                        (pieceSize / 2) +
                                        (mapper.cellSize / 2),
                                    top:
                                        offset.dy -
                                        (pieceSize / 2) +
                                        (mapper.cellSize / 2),
                                    width: pieceSize,
                                    height: pieceSize,
                                    child: GestureDetector(
                                      onTap: isMyPiece && canMove
                                          ? () => handleMovePiece(pieceId)
                                          : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black54,
                                            width: 1.5,
                                          ),
                                          boxShadow: canMove
                                              ? [
                                                  const BoxShadow(
                                                    color: Colors.white,
                                                    blurRadius: 8,
                                                    spreadRadius: 4,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: _getColorFromString(
                                            pieceColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(
                        child: Text("Lỗi lấy thông tin người chơi: $e"),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Lỗi tải quân cờ: $e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Lỗi tải game: $e')),
      ),
    );
  }

  // Hàm trợ giúp để chuyển string màu thành đối tượng Color
  Color _getColorFromString(String colorString) {
    switch (colorString) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
