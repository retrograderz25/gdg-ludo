enum PlayerColor { red, blue, green, yellow } // Mở rộng thêm sau

class Player {
  final String id;
  final String? userId;
  final String roomId;
  final String nickname;
  final PlayerColor color;

  Player({
    required this.id,
    this.userId,
    required this.roomId,
    required this.nickname,
    required this.color,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      userId: json['user_id'],
      roomId: json['room_id'],
      nickname: json['nickname'],
      // Chuyển đổi string từ DB thành enum
      color: PlayerColor.values.byName(json['color']),
    );
  }
}
