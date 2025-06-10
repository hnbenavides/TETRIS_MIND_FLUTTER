import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});

  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  static const int rows = 28;
  static const int columns = 16;

  List<List<Color?>> board = List.generate(
    rows,
    (_) => List.generate(columns, (_) => null),
  );

  Timer? gameTimer;
  int currentRow = 0;
  int currentCol = columns ~/ 2;
  Color currentBlockColor = Colors.blue;

  // Definición de formas (orientación fija)
  final List<List<List<int>>> shapes = [
    // T
    [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, 2]
    ],
    // L
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [2, 1]
    ],
    // J (L invertida)
    [
      [0, 1],
      [1, 1],
      [2, 1],
      [2, 0]
    ],
    // I
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0]
    ],
    // O (cuadrado)
    [
      [0, 0],
      [0, 1],
      [1, 0],
      [1, 1]
    ],
    // S
    [
      [0, 1],
      [0, 2],
      [1, 0],
      [1, 1]
    ],
    // Z
    [
      [0, 0],
      [0, 1],
      [1, 1],
      [1, 2]
    ],
    // L invertida (J invertida)
    [
      [0, 0],
      [0, 1],
      [1, 1],
      [2, 1]
    ],
    // S invertida
    [
      [0, 0],
      [0, 1],
      [1, 1],
      [1, 2]
    ],
    // Z invertida
    [
      [0, 1],
      [0, 2],
      [1, 0],
      [1, 1]
    ],
  ];

  List<List<int>> currentShape = [];
  List<List<int>> nextShape = [];
  Color nextBlockColor = Colors.blue;

  // Nueva variable para animar filas que se destruyen
  Set<int> rowsToClear = {};

  @override
  void initState() {
    super.initState();
    prepareNextPiece();
    spawnNewBlock();
    startGame();
  }

  void prepareNextPiece() {
    final rand = Random();
    int shapeIndex = rand.nextInt(shapes.length);
    List<List<int>> baseShape = shapes[shapeIndex];
    int rotations = rand.nextInt(4);
    List<List<int>> rotatedShape = baseShape;
    for (int i = 0; i < rotations; i++) {
      int maxRow = rotatedShape.map((cell) => cell[0]).reduce(max);
      rotatedShape =
          rotatedShape.map((cell) => [cell[1], maxRow - cell[0]]).toList();
      int minCol = rotatedShape.map((cell) => cell[1]).reduce(min);
      int minRow = rotatedShape.map((cell) => cell[0]).reduce(min);
      rotatedShape = rotatedShape
          .map((cell) => [cell[0] - minRow, cell[1] - minCol])
          .toList();
    }
    nextShape = rotatedShape;
    nextBlockColor = Colors.primaries[rand.nextInt(Colors.primaries.length)];
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        moveBlockDown();
      });
    });
  }

  bool canMove(int dRow, int dCol) {
    for (var cell in currentShape) {
      int newRow = currentRow + cell[0] + dRow;
      int newCol = currentCol + cell[1] + dCol;
      if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= columns) {
        return false;
      }
      if (board[newRow][newCol] != null) return false;
    }
    return true;
  }

  void moveBlockDown() {
    if (canMove(1, 0)) {
      currentRow++;
    } else {
      // Fijar la pieza en el tablero
      for (var cell in currentShape) {
        int r = currentRow + cell[0];
        int c = currentCol + cell[1];
        if (r >= 0 && r < rows && c >= 0 && c < columns) {
          board[r][c] = currentBlockColor;
        }
      }
      detectRowsToClearWithDelay();
    }
  }

  void detectRowsToClearWithDelay() {
    Set<int> fullRows = {};
    for (int row = 0; row < rows; row++) {
      if (board[row].every((cell) => cell != null)) {
        fullRows.add(row);
      }
    }
    if (fullRows.isNotEmpty) {
      setState(() {
        rowsToClear = fullRows;
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        clearFullRows();
        Future.delayed(const Duration(milliseconds: 350), () {
          spawnNewBlock();
        });
      });
    } else {
      // Espera antes de sacar la siguiente pieza
      Future.delayed(const Duration(milliseconds: 350), () {
        spawnNewBlock();
      });
    }
  }

  void clearFullRows() {
    setState(() {
      for (int row in rowsToClear.toList()..sort()) {
        board.removeAt(row);
        board.insert(0, List<Color?>.filled(columns, null));
      }
      rowsToClear.clear();
    });
  }

  void moveBlockLeft() {
    if (canMove(0, -1)) {
      setState(() {
        currentCol--;
      });
    }
  }

  void moveBlockRight() {
    if (canMove(0, 1)) {
      setState(() {
        currentCol++;
      });
    }
  }

  // Rota la pieza actual 90° a la derecha (sentido horario)
  void rotateCurrentShape() {
    // Encuentra el tamaño de la matriz de la pieza (máximo de filas y columnas)
    int maxRow = currentShape.map((cell) => cell[0]).reduce(max);
    int maxCol = currentShape.map((cell) => cell[1]).reduce(max);

    // Rota cada celda: (row, col) -> (col, maxRow - row)
    List<List<int>> rotated =
        currentShape.map((cell) => [cell[1], maxRow - cell[0]]).toList();

    // Ajusta la pieza para que no salga del tablero
    int minCol = rotated.map((cell) => cell[1]).reduce(min);
    int minRow = rotated.map((cell) => cell[0]).reduce(min);
    rotated =
        rotated.map((cell) => [cell[0] - minRow, cell[1] - minCol]).toList();

    // Verifica si la rotación es válida
    bool canRotate = rotated.every((cell) {
      int newRow = currentRow + cell[0];
      int newCol = currentCol + cell[1];
      return newRow >= 0 &&
          newRow < rows &&
          newCol >= 0 &&
          newCol < columns &&
          (board[newRow][newCol] == null);
    });

    if (canRotate) {
      setState(() {
        currentShape = rotated;
      });
    }
  }

  void spawnNewBlock() {
    // Usa la pieza preparada como la actual y prepara la siguiente
    currentShape = nextShape;
    currentBlockColor = nextBlockColor;
    // Centrar la pieza horizontalmente
    int maxCol = currentShape.map((cell) => cell[1]).reduce(max);
    currentRow = 0;
    currentCol = (columns ~/ 2) - (maxCol ~/ 2);
    prepareNextPiece();
    // Si la nueva pieza colisiona al aparecer, termina el juego
    if (!canMove(0, 0)) {
      gameTimer?.cancel();
      showGameOverDialog();
    }
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('You lost!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      board = List.generate(
        rows,
        (_) => List.generate(columns, (_) => null),
      );
      startGame();
    });
  }

  void dropBlockToBottom() {
    while (canMove(1, 0)) {
      currentRow++;
    }
    setState(() {
      moveBlockDown(); // Esto fija la pieza y genera la siguiente
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetris'),
      ),
      body: Column(
        children: [
          // Miniatura de la próxima pieza
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CustomPaint(
                        painter: _MiniPiecePainter(nextShape, nextBlockColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: AspectRatio(
                aspectRatio: columns / rows,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(149, 168, 35, 235)),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color.fromARGB(30, 213, 32, 245),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                    ),
                    itemCount: rows * columns,
                    itemBuilder: (context, index) {
                      int row = index ~/ columns;
                      int col = index % columns;
                      bool isCurrentBlock = currentShape.any((cell) =>
                          row == currentRow + cell[0] &&
                          col == currentCol + cell[1]);
                      bool isClearing = rowsToClear.contains(row);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isClearing
                              ? Colors.white
                              : isCurrentBlock
                                  ? currentBlockColor
                                  : board[row][col] ??
                                      const Color.fromARGB(94, 224, 224, 224),
                          border: Border.all(
                            color: const Color.fromARGB(63, 89, 70, 70),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Botones para mover izquierda/derecha/rotar/abajo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: moveBlockLeft,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(204, 191, 33, 243)),
                  child: const Icon(Icons.arrow_left),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: rotateCurrentShape,
                  child: const Icon(Icons.rotate_right),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: moveBlockRight,
                  child: const Icon(Icons.arrow_right),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: dropBlockToBottom,
                  child: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            height: MediaQuery.of(context).size.height * 0.08,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border:
                    Border.all(color: const Color.fromARGB(215, 178, 6, 226)),
                color: const Color.fromARGB(196, 201, 7, 255)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
}

class _MiniPiecePainter extends CustomPainter {
  final List<List<int>> shape;
  final Color color;

  _MiniPiecePainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    double blockSize = min(size.width, size.height) / 4;
    Paint paint = Paint()..color = color;

    for (var cell in shape) {
      canvas.drawRect(
        Rect.fromLTWH(
            cell[1] * blockSize, cell[0] * blockSize, blockSize, blockSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
