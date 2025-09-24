import 'dart:math';
import 'package:flutter/material.dart';

// Một lớp trợ giúp đơn giản để lưu tọa độ grid (x, y)
class GridPoint {
  final int x;
  final int y;
  const GridPoint(this.x, this.y);
}

class BoardMapper {
  final Size boardSize;
  final String
  myColor; // Màu của người chơi đang xem ('red', 'blue', 'yellow', 'green')

  late final double cellSize;
  late final GridPoint gridCenter;

  // Các bản đồ này lưu tọa độ (dưới dạng GridPoint) cho mỗi vị trí logic
  // trong một bàn cờ "chuẩn" (Màu Đỏ ở dưới)
  static final Map<int, GridPoint> _pathCoordinates = {};
  static final Map<String, List<GridPoint>> _homeAreaCoordinates = {};
  static final Map<String, List<GridPoint>> _homeRunCoordinates = {};

  BoardMapper({required this.boardSize, required this.myColor}) {
    // Bàn cờ được chia thành lưới 15x15
    cellSize = boardSize.width / 15.0;
    gridCenter = const GridPoint(7, 7);
    _initializeCoordinates();
  }

  /// Hàm chính để lấy tọa độ pixel (Offset) cho một quân cờ
  /// - [pieceColor]: Màu của chính quân cờ đó
  /// - [logicalPosition]: Vị trí logic (0 cho chuồng, 1-52 cho vòng ngoài, >100 cho về đích)
  /// - [homeIndex]: Thứ tự của quân cờ khi ở trong chuồng (0, 1, 2, 3) để xếp cho đẹp
  Offset getOffsetForPiece({
    required String pieceColor,
    required int logicalPosition,
    int homeIndex = 0,
  }) {
    GridPoint canonicalPoint;

    if (logicalPosition == 0) {
      // Trong chuồng
      canonicalPoint = _homeAreaCoordinates[pieceColor]![homeIndex];
    } else if (logicalPosition > 100) {
      // Đang về đích
      int homeRunIndex = logicalPosition % 100 - 1;
      canonicalPoint = _homeRunCoordinates[pieceColor]![homeRunIndex];
    } else {
      // Trên đường đi
      canonicalPoint = _pathCoordinates[logicalPosition]!;
    }

    // Xoay tọa độ chuẩn dựa trên góc nhìn của người chơi (`myColor`)
    final rotatedPoint = _rotatePoint(canonicalPoint);

    // Chuyển tọa độ grid đã xoay thành tọa độ pixel trên màn hình
    return Offset(rotatedPoint.x * cellSize, rotatedPoint.y * cellSize);
  }

  // Xoay một điểm quanh tâm của bàn cờ
  GridPoint _rotatePoint(GridPoint point) {
    int angle = 0;
    switch (myColor) {
      case 'red':
        angle = 0;
        break; // Không xoay
      case 'blue':
        angle = 270;
        break; // Xoay ngược 90 độ
      case 'yellow':
        angle = 180;
        break; // Xoay 180 độ
      case 'green':
        angle = 90;
        break; // Xoay 90 độ
    }

    if (angle == 0) return point;

    // Tọa độ tương đối so với tâm
    int dx = point.x - gridCenter.x;
    int dy = point.y - gridCenter.y;

    // Ma trận xoay
    double rad = angle * (pi / 180.0);
    int newDx = (dx * cos(rad) - dy * sin(rad)).round();
    int newDy = (dx * sin(rad) + dy * cos(rad)).round();

    return GridPoint(gridCenter.x + newDx, gridCenter.y + newDy);
  }

  // --- PHẦN KHỞI TẠO BẢN ĐỒ TỌA ĐỘ ---
  // Chỉ chạy một lần để tính toán và lưu trữ vị trí của tất cả các ô
  static void _initializeCoordinates() {
    if (_pathCoordinates.isNotEmpty) return; // Chỉ khởi tạo một lần

    // 1. Tọa độ các ô trong chuồng (Home Areas)
    _homeAreaCoordinates['red'] = [
      const GridPoint(2, 10),
      const GridPoint(3, 10),
      const GridPoint(2, 11),
      const GridPoint(3, 11),
    ];
    _homeAreaCoordinates['blue'] = [
      const GridPoint(10, 2),
      const GridPoint(11, 2),
      const GridPoint(10, 3),
      const GridPoint(11, 3),
    ];
    _homeAreaCoordinates['yellow'] = [
      const GridPoint(2, 2),
      const GridPoint(3, 2),
      const GridPoint(2, 3),
      const GridPoint(3, 3),
    ];
    _homeAreaCoordinates['green'] = [
      const GridPoint(10, 10),
      const GridPoint(11, 10),
      const GridPoint(10, 11),
      const GridPoint(11, 11),
    ];

    // 2. Tọa độ đường về đích (Home Runs)
    _homeRunCoordinates['red'] = [
      for (int i = 1; i < 7; i++) GridPoint(7, 14 - i),
    ];
    _homeRunCoordinates['blue'] = [
      for (int i = 1; i < 7; i++) GridPoint(14 - i, 7),
    ];
    _homeRunCoordinates['yellow'] = [
      for (int i = 1; i < 7; i++) GridPoint(7, i),
    ];
    _homeRunCoordinates['green'] = [
      for (int i = 1; i < 7; i++) GridPoint(i, 7),
    ];

    // 3. Tọa độ đường đi chính (52 ô)
    // Đoạn đường của MÀU ĐỎ (dưới)
    _pathCoordinates[1] = const GridPoint(6, 13); // Ô xuất phát
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[2 + i] = GridPoint(6, 12 - i);
    }
    for (int i = 0; i < 2; i++) {
      _pathCoordinates[7 + i] = GridPoint(5 - i, 8);
    }
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[9 + i] = GridPoint(4, 7 - i);
    }
    _pathCoordinates[14] = const GridPoint(5, 2);

    // Đoạn đường của MÀU XANH (phải)
    _pathCoordinates[15] = const GridPoint(2, 6);
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[16 + i] = GridPoint(2 + i, 6);
    }
    _pathCoordinates[21] = const GridPoint(6, 5);
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[22 + i] = GridPoint(8, 5 - i);
    }
    _pathCoordinates[27] = const GridPoint(8, 0);

    // Đoạn đường của MÀU VÀNG (trên)
    _pathCoordinates[28] = const GridPoint(8, 2);
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[29 + i] = GridPoint(8, 2 + i);
    }
    _pathCoordinates[34] = const GridPoint(9, 6);
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[35 + i] = GridPoint(10 + i, 6);
    }
    _pathCoordinates[40] = const GridPoint(12, 5);

    // Đoạn đường của MÀU XANH LÁ (trái)
    _pathCoordinates[41] = const GridPoint(12, 8);
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[42 + i] = GridPoint(12 - i, 8);
    }
    _pathCoordinates[47] = const GridPoint(8, 9);
    for (int i = 0; i < 5; i++) {
      _pathCoordinates[48 + i] = GridPoint(6, 10 + i);
    }
    _pathCoordinates[53] = const GridPoint(6, 12);
  }
}
