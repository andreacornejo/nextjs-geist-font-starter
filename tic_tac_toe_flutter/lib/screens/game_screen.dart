import 'package:flutter/material.dart';
import 'dart:math';

class GameScreen extends StatefulWidget {
  final bool isSinglePlayer;

  const GameScreen({super.key, required this.isSinglePlayer});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  bool gameEnded = false;
  String winner = '';
  int round = 1;
  int playerXScore = 0;
  int playerOScore = 0;
  int draws = 0;
  bool isAITurn = false;

  late AnimationController _boardAnimationController;
  late AnimationController _cellAnimationController;
  late Animation<double> _boardAnimation;
  late Animation<double> _cellAnimation;

  @override
  void initState() {
    super.initState();
    _boardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cellAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _boardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _boardAnimationController,
      curve: Curves.elasticOut,
    ));

    _cellAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cellAnimationController,
      curve: Curves.bounceOut,
    ));

    _boardAnimationController.forward();
  }

  @override
  void dispose() {
    _boardAnimationController.dispose();
    _cellAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.isSinglePlayer ? 'Jugar Solo' : 'Jugar con Compañero',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Score and round info
                _buildScoreBoard(),
                const SizedBox(height: 20),
                
                // Current player indicator
                if (!gameEnded && !isAITurn) _buildCurrentPlayerIndicator(),
                if (isAITurn) _buildAIThinkingIndicator(),
                const SizedBox(height: 20),
                
                // Game board
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _boardAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _boardAnimation.value,
                          child: _buildGameBoard(),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Ronda $round de 3',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreItem('Jugador X', playerXScore, Colors.blue),
              _buildScoreItem('Empates', draws, Colors.grey),
              _buildScoreItem(
                widget.isSinglePlayer ? 'IA (O)' : 'Jugador O',
                playerOScore,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPlayerIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: currentPlayer == 'X' ? Colors.blue : Colors.red,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        'Turno del Jugador $currentPlayer',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAIThinkingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'IA pensando...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _makeMove(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: board[index].isEmpty ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: board[index].isEmpty ? Colors.grey[300]! : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    board[index],
                    key: ValueKey(board[index]),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: board[index] == 'X' ? Colors.blue : Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    if (round > 3) {
      return _buildFinalButtons();
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _resetCurrentGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Reiniciar Ronda'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Volver al Inicio'),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalButtons() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Column(
            children: [
              const Text(
                '¡Juego Terminado!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _getFinalWinner(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _resetGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Jugar de Nuevo'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Volver al Inicio'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _makeMove(int index) {
    if (board[index].isNotEmpty || gameEnded || isAITurn) return;

    setState(() {
      board[index] = currentPlayer;
    });

    _cellAnimationController.forward().then((_) {
      _cellAnimationController.reset();
    });

    if (_checkWinner()) {
      _handleGameEnd();
    } else if (_isBoardFull()) {
      _handleDraw();
    } else {
      _switchPlayer();
      if (widget.isSinglePlayer && currentPlayer == 'O') {
        _makeAIMove();
      }
    }
  }

  void _makeAIMove() {
    setState(() {
      isAITurn = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      int move = _getAIMove();
      setState(() {
        board[move] = 'O';
        isAITurn = false;
      });

      if (_checkWinner()) {
        _handleGameEnd();
      } else if (_isBoardFull()) {
        _handleDraw();
      } else {
        _switchPlayer();
      }
    });
  }

  int _getAIMove() {
    // Try to win
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'O';
        if (_checkWinner()) {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }

    // Try to block player
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        board[i] = 'X';
        if (_checkWinner()) {
          board[i] = '';
          return i;
        }
        board[i] = '';
      }
    }

    // Take center if available
    if (board[4].isEmpty) return 4;

    // Take corners
    List<int> corners = [0, 2, 6, 8];
    corners.shuffle();
    for (int corner in corners) {
      if (board[corner].isEmpty) return corner;
    }

    // Take any available spot
    List<int> available = [];
    for (int i = 0; i < 9; i++) {
      if (board[i].isEmpty) available.add(i);
    }
    return available[Random().nextInt(available.length)];
  }

  bool _checkWinner() {
    List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (List<int> pattern in winPatterns) {
      if (board[pattern[0]].isNotEmpty &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[1]] == board[pattern[2]]) {
        winner = board[pattern[0]];
        return true;
      }
    }
    return false;
  }

  bool _isBoardFull() {
    return !board.contains('');
  }

  void _switchPlayer() {
    setState(() {
      currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
    });
  }

  void _handleGameEnd() {
    setState(() {
      gameEnded = true;
      if (winner == 'X') {
        playerXScore++;
      } else {
        playerOScore++;
      }
    });

    _showRoundResult();
  }

  void _handleDraw() {
    setState(() {
      gameEnded = true;
      draws++;
    });

    _showRoundResult();
  }

  void _showRoundResult() {
    String message;
    if (winner.isNotEmpty) {
      if (widget.isSinglePlayer) {
        message = winner == 'X' ? '¡Ganaste!' : '¡La IA ganó!';
      } else {
        message = '¡Jugador $winner ganó!';
      }
    } else {
      message = '¡Empate!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          content: Text('Ronda $round completada'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (round < 3) {
                  _nextRound();
                } else {
                  setState(() {
                    round++;
                  });
                }
              },
              child: Text(round < 3 ? 'Siguiente Ronda' : 'Ver Resultados'),
            ),
          ],
        );
      },
    );
  }

  void _nextRound() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      gameEnded = false;
      winner = '';
      round++;
      isAITurn = false;
    });
  }

  void _resetCurrentGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      gameEnded = false;
      winner = '';
      isAITurn = false;
    });
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      gameEnded = false;
      winner = '';
      round = 1;
      playerXScore = 0;
      playerOScore = 0;
      draws = 0;
      isAITurn = false;
    });
  }

  String _getFinalWinner() {
    if (playerXScore > playerOScore) {
      return widget.isSinglePlayer ? '¡Ganaste el torneo!' : '¡Jugador X ganó el torneo!';
    } else if (playerOScore > playerXScore) {
      return widget.isSinglePlayer ? '¡La IA ganó el torneo!' : '¡Jugador O ganó el torneo!';
    } else {
      return '¡El torneo terminó en empate!';
    }
  }
}
