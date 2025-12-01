import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'dart:math' as math;

class RubikScene extends StatefulWidget {
  const RubikScene({Key? key}) : super(key: key);

  @override
  State<RubikScene> createState() => _RubikSceneState();
}

class _RubikSceneState extends State<RubikScene> with TickerProviderStateMixin {
  late Scene _scene;
  late List<List<List<Object>>> _cubes = [];
  bool _isRotating = false;

  AnimationController? _rotationController;
  Animation<double>? _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCubesArray();
  }

  void _initializeCubesArray() {
    _cubes = List.generate(
      3,
      (x) => List.generate(
        3,
        (y) => List.generate(3, (z) => Object(name: 'temp')),
      ),
    );
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;

    for (int x = 0; x < 3; x++) {
      for (int y = 0; y < 3; y++) {
        for (int z = 0; z < 3; z++) {
          final mesh = Mesh(
            vertices: _createCubeVertices(),
            texcoords: _createCubeTexcoords(),
            indices: _createCubeIndices(), // Đã sửa hàm này
            colors: _createCubeColors(x, y, z),
          );

          final obj = Object(
            name: 'cube_${x}_${y}_$z',
            mesh: mesh,
            position: Vector3((x - 1) * 2.2, (y - 1) * 2.2, (z - 1) * 2.2),
            scale: Vector3(0.95, 0.95, 0.95),
          );

          scene.world.add(obj);
          _cubes[x][y][z] = obj;
        }
      }
    }

    scene.camera.position.setValues(10, 10, 15);
    scene.camera.target.setValues(0, 0, 0);
  }

  List<Vector3> _createCubeVertices() {
    return [
      Vector3(-1, -1, 1),
      Vector3(1, -1, 1),
      Vector3(1, 1, 1),
      Vector3(-1, 1, 1),
      Vector3(-1, -1, -1),
      Vector3(-1, 1, -1),
      Vector3(1, 1, -1),
      Vector3(1, -1, -1),
      Vector3(-1, 1, -1),
      Vector3(-1, 1, 1),
      Vector3(1, 1, 1),
      Vector3(1, 1, -1),
      Vector3(-1, -1, -1),
      Vector3(1, -1, -1),
      Vector3(1, -1, 1),
      Vector3(-1, -1, 1),
      Vector3(1, -1, -1),
      Vector3(1, 1, -1),
      Vector3(1, 1, 1),
      Vector3(1, -1, 1),
      Vector3(-1, -1, -1),
      Vector3(-1, -1, 1),
      Vector3(-1, 1, 1),
      Vector3(-1, 1, -1),
    ];
  }

  List<Offset> _createCubeTexcoords() {
    return List.generate(24, (i) => const Offset(0, 0));
  }

  // --- [SỬA LỖI 1] Trả về List<Polygon> thay vì List<int> ---
  List<Polygon> _createCubeIndices() {
    List<Polygon> indices = [];
    for (int i = 0; i < 6; i++) {
      int offset = i * 4;
      indices.add(Polygon(offset, offset + 1, offset + 2));
      indices.add(Polygon(offset, offset + 2, offset + 3));
    }
    return indices;
  }

  List<Color> _createCubeColors(int x, int y, int z) {
    List<Color> colors = [];
    for (int i = 0; i < 4; i++)
      colors.add(z == 2 ? Colors.white : Colors.grey[900]!);
    for (int i = 0; i < 4; i++)
      colors.add(z == 0 ? Colors.yellow : Colors.grey[900]!);
    for (int i = 0; i < 4; i++)
      colors.add(y == 2 ? Colors.red : Colors.grey[900]!);
    for (int i = 0; i < 4; i++)
      colors.add(y == 0 ? Colors.orange : Colors.grey[900]!);
    for (int i = 0; i < 4; i++)
      colors.add(x == 2 ? Colors.blue : Colors.grey[900]!);
    for (int i = 0; i < 4; i++)
      colors.add(x == 0 ? Colors.green : Colors.grey[900]!);
    return colors;
  }

  void _rotateFace({
    required List<Object> Function() getCubes,
    required Vector3 axis,
    required bool clockwise,
    required Function swapPositions,
  }) {
    setState(() => _isRotating = true);

    final cubes = getCubes();
    final angle = clockwise ? -math.pi / 2 : math.pi / 2;

    final initialPositions = cubes
        .map((c) => Vector3.copy(c.position))
        .toList();

    // --- [SỬA LỖI 2] Bỏ .eulerAngles, dùng trực tiếp c.rotation ---
    final initialRotations = cubes
        .map((c) => Vector3.copy(c.rotation))
        .toList();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController!, curve: Curves.easeInOut),
    );

    _rotationController!.addListener(() {
      final progress = animation.value;
      final currentAngle = angle * progress;

      for (int i = 0; i < cubes.length; i++) {
        final cube = cubes[i];
        final initialPos = initialPositions[i];

        final rotatedPos = _rotatePointAroundAxis(
          initialPos,
          axis,
          currentAngle,
        );
        cube.position.setFrom(rotatedPos);

        final rotationEuler = Vector3.copy(initialRotations[i]);
        if (axis.x != 0) rotationEuler.x += currentAngle * 180 / math.pi;
        if (axis.y != 0) rotationEuler.y += currentAngle * 180 / math.pi;
        if (axis.z != 0) rotationEuler.z += currentAngle * 180 / math.pi;

        // --- [SỬA LỖI 3] Thay setEuler bằng setValues ---
        cube.rotation.setValues(
          rotationEuler.x,
          rotationEuler.y,
          rotationEuler.z,
        );

        cube.updateTransform();
      }

      setState(() {});
    });

    _rotationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        swapPositions();
        setState(() => _isRotating = false);
        _rotationController?.dispose();
      }
    });

    _rotationController!.forward();
  }

  // --- Logic xoay các mặt giữ nguyên ---
  void _rotateFront(bool clockwise) {
    if (_isRotating) return;
    _rotateFace(
      getCubes: () {
        List<Object> cubes = [];
        for (int x = 0; x < 3; x++) {
          for (int y = 0; y < 3; y++) {
            cubes.add(_cubes[x][y][2]);
          }
        }
        return cubes;
      },
      axis: Vector3(0, 0, 1),
      clockwise: clockwise,
      swapPositions: () {
        if (clockwise) {
          var temp = _cubes[0][0][2];
          _cubes[0][0][2] = _cubes[0][2][2];
          _cubes[0][2][2] = _cubes[2][2][2];
          _cubes[2][2][2] = _cubes[2][0][2];
          _cubes[2][0][2] = temp;
          temp = _cubes[1][0][2];
          _cubes[1][0][2] = _cubes[0][1][2];
          _cubes[0][1][2] = _cubes[1][2][2];
          _cubes[1][2][2] = _cubes[2][1][2];
          _cubes[2][1][2] = temp;
        } else {
          var temp = _cubes[0][0][2];
          _cubes[0][0][2] = _cubes[2][0][2];
          _cubes[2][0][2] = _cubes[2][2][2];
          _cubes[2][2][2] = _cubes[0][2][2];
          _cubes[0][2][2] = temp;
          temp = _cubes[1][0][2];
          _cubes[1][0][2] = _cubes[2][1][2];
          _cubes[2][1][2] = _cubes[1][2][2];
          _cubes[1][2][2] = _cubes[0][1][2];
          _cubes[0][1][2] = temp;
        }
      },
    );
  }

  void _rotateBack(bool clockwise) {
    if (_isRotating) return;
    _rotateFace(
      getCubes: () {
        List<Object> cubes = [];
        for (int x = 0; x < 3; x++) {
          for (int y = 0; y < 3; y++) {
            cubes.add(_cubes[x][y][0]);
          }
        }
        return cubes;
      },
      axis: Vector3(0, 0, 1),
      clockwise: !clockwise,
      swapPositions: () {
        if (clockwise) {
          var temp = _cubes[0][0][0];
          _cubes[0][0][0] = _cubes[2][0][0];
          _cubes[2][0][0] = _cubes[2][2][0];
          _cubes[2][2][0] = _cubes[0][2][0];
          _cubes[0][2][0] = temp;
          temp = _cubes[1][0][0];
          _cubes[1][0][0] = _cubes[2][1][0];
          _cubes[2][1][0] = _cubes[1][2][0];
          _cubes[1][2][0] = _cubes[0][1][0];
          _cubes[0][1][0] = temp;
        } else {
          var temp = _cubes[0][0][0];
          _cubes[0][0][0] = _cubes[0][2][0];
          _cubes[0][2][0] = _cubes[2][2][0];
          _cubes[2][2][0] = _cubes[2][0][0];
          _cubes[2][0][0] = temp;
          temp = _cubes[1][0][0];
          _cubes[1][0][0] = _cubes[0][1][0];
          _cubes[0][1][0] = _cubes[1][2][0];
          _cubes[1][2][0] = _cubes[2][1][0];
          _cubes[2][1][0] = temp;
        }
      },
    );
  }

  void _rotateLeft(bool clockwise) {
    if (_isRotating) return;
    _rotateFace(
      getCubes: () {
        List<Object> cubes = [];
        for (int y = 0; y < 3; y++) {
          for (int z = 0; z < 3; z++) {
            cubes.add(_cubes[0][y][z]);
          }
        }
        return cubes;
      },
      axis: Vector3(1, 0, 0),
      clockwise: !clockwise,
      swapPositions: () {
        if (clockwise) {
          var temp = _cubes[0][0][0];
          _cubes[0][0][0] = _cubes[0][0][2];
          _cubes[0][0][2] = _cubes[0][2][2];
          _cubes[0][2][2] = _cubes[0][2][0];
          _cubes[0][2][0] = temp;
          temp = _cubes[0][1][0];
          _cubes[0][1][0] = _cubes[0][0][1];
          _cubes[0][0][1] = _cubes[0][1][2];
          _cubes[0][1][2] = _cubes[0][2][1];
          _cubes[0][2][1] = temp;
        } else {
          var temp = _cubes[0][0][0];
          _cubes[0][0][0] = _cubes[0][2][0];
          _cubes[0][2][0] = _cubes[0][2][2];
          _cubes[0][2][2] = _cubes[0][0][2];
          _cubes[0][0][2] = temp;
          temp = _cubes[0][1][0];
          _cubes[0][1][0] = _cubes[0][2][1];
          _cubes[0][2][1] = _cubes[0][1][2];
          _cubes[0][1][2] = _cubes[0][0][1];
          _cubes[0][0][1] = temp;
        }
      },
    );
  }

  void _rotateRight(bool clockwise) {
    if (_isRotating) return;
    _rotateFace(
      getCubes: () {
        List<Object> cubes = [];
        for (int y = 0; y < 3; y++) {
          for (int z = 0; z < 3; z++) {
            cubes.add(_cubes[2][y][z]);
          }
        }
        return cubes;
      },
      axis: Vector3(1, 0, 0),
      clockwise: clockwise,
      swapPositions: () {
        if (clockwise) {
          var temp = _cubes[2][0][0];
          _cubes[2][0][0] = _cubes[2][2][0];
          _cubes[2][2][0] = _cubes[2][2][2];
          _cubes[2][2][2] = _cubes[2][0][2];
          _cubes[2][0][2] = temp;
          temp = _cubes[2][1][0];
          _cubes[2][1][0] = _cubes[2][2][1];
          _cubes[2][2][1] = _cubes[2][1][2];
          _cubes[2][1][2] = _cubes[2][0][1];
          _cubes[2][0][1] = temp;
        } else {
          var temp = _cubes[2][0][0];
          _cubes[2][0][0] = _cubes[2][0][2];
          _cubes[2][0][2] = _cubes[2][2][2];
          _cubes[2][2][2] = _cubes[2][2][0];
          _cubes[2][2][0] = temp;
          temp = _cubes[2][1][0];
          _cubes[2][1][0] = _cubes[2][0][1];
          _cubes[2][0][1] = _cubes[2][1][2];
          _cubes[2][1][2] = _cubes[2][2][1];
          _cubes[2][2][1] = temp;
        }
      },
    );
  }

  void _rotateTop(bool clockwise) {
    if (_isRotating) return;
    _rotateFace(
      getCubes: () {
        List<Object> cubes = [];
        for (int x = 0; x < 3; x++) {
          for (int z = 0; z < 3; z++) {
            cubes.add(_cubes[x][2][z]);
          }
        }
        return cubes;
      },
      axis: Vector3(0, 1, 0),
      clockwise: clockwise,
      swapPositions: () {
        if (clockwise) {
          var temp = _cubes[0][2][0];
          _cubes[0][2][0] = _cubes[0][2][2];
          _cubes[0][2][2] = _cubes[2][2][2];
          _cubes[2][2][2] = _cubes[2][2][0];
          _cubes[2][2][0] = temp;
          temp = _cubes[1][2][0];
          _cubes[1][2][0] = _cubes[0][2][1];
          _cubes[0][2][1] = _cubes[1][2][2];
          _cubes[1][2][2] = _cubes[2][2][1];
          _cubes[2][2][1] = temp;
        } else {
          var temp = _cubes[0][2][0];
          _cubes[0][2][0] = _cubes[2][2][0];
          _cubes[2][2][0] = _cubes[2][2][2];
          _cubes[2][2][2] = _cubes[0][2][2];
          _cubes[0][2][2] = temp;
          temp = _cubes[1][2][0];
          _cubes[1][2][0] = _cubes[2][2][1];
          _cubes[2][2][1] = _cubes[1][2][2];
          _cubes[1][2][2] = _cubes[0][2][1];
          _cubes[0][2][1] = temp;
        }
      },
    );
  }

  void _rotateBottom(bool clockwise) {
    if (_isRotating) return;
    _rotateFace(
      getCubes: () {
        List<Object> cubes = [];
        for (int x = 0; x < 3; x++) {
          for (int z = 0; z < 3; z++) {
            cubes.add(_cubes[x][0][z]);
          }
        }
        return cubes;
      },
      axis: Vector3(0, 1, 0),
      clockwise: !clockwise,
      swapPositions: () {
        if (clockwise) {
          var temp = _cubes[0][0][0];
          _cubes[0][0][0] = _cubes[2][0][0];
          _cubes[2][0][0] = _cubes[2][0][2];
          _cubes[2][0][2] = _cubes[0][0][2];
          _cubes[0][0][2] = temp;
          temp = _cubes[1][0][0];
          _cubes[1][0][0] = _cubes[2][0][1];
          _cubes[2][0][1] = _cubes[1][0][2];
          _cubes[1][0][2] = _cubes[0][0][1];
          _cubes[0][0][1] = temp;
        } else {
          var temp = _cubes[0][0][0];
          _cubes[0][0][0] = _cubes[0][0][2];
          _cubes[0][0][2] = _cubes[2][0][2];
          _cubes[2][0][2] = _cubes[2][0][0];
          _cubes[2][0][0] = temp;
          temp = _cubes[1][0][0];
          _cubes[1][0][0] = _cubes[0][0][1];
          _cubes[0][0][1] = _cubes[1][0][2];
          _cubes[1][0][2] = _cubes[2][0][1];
          _cubes[2][0][1] = temp;
        }
      },
    );
  }

  Vector3 _rotatePointAroundAxis(Vector3 point, Vector3 axis, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    final x = point.x, y = point.y, z = point.z;

    if (axis.x != 0) {
      return Vector3(x, cos * y - sin * z, sin * y + cos * z);
    } else if (axis.y != 0) {
      return Vector3(cos * x + sin * z, y, -sin * x + cos * z);
    } else {
      return Vector3(cos * x - sin * y, sin * x + cos * y, z);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: const Text('Rubik 3D Cube'),
        backgroundColor: Colors.deepPurple[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Cube(onSceneCreated: _onSceneCreated, interactive: true),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '🎮 Điều khiển đơn giản',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSimpleButton(
                        'Trước ↻',
                        Colors.white,
                        () => _rotateFront(true),
                      ),
                      _buildSimpleButton(
                        'Trước ↺',
                        Colors.white70,
                        () => _rotateFront(false),
                      ),
                      _buildSimpleButton(
                        'Sau ↻',
                        Colors.yellow,
                        () => _rotateBack(true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSimpleButton(
                        'Trái ↻',
                        Colors.green,
                        () => _rotateLeft(true),
                      ),
                      _buildSimpleButton(
                        'Phải ↻',
                        Colors.blue,
                        () => _rotateRight(true),
                      ),
                      _buildSimpleButton(
                        'Trên ↻',
                        Colors.red,
                        () => _rotateTop(true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isRotating ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _rotationController?.dispose();
    super.dispose();
  }
}
