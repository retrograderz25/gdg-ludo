class Room {
  final String id;
  final String roomCode;
  final String hostId;

  Room({required this.id, required this.roomCode, required this.hostId});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      roomCode: json['room_code'],
      hostId: json['host_id'],
    );
  }
}
