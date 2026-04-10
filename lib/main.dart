import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Birdle')),
        body: const GamePage(),
      ),
    );
  }
}

class FlipTile extends StatefulWidget {
  const FlipTile({
    super.key,
    required this.letter,
    required this.hitType,
    required this.animate,
    required this.delay,
  });

  final String letter;
  final HitType hitType;
  final bool animate;
  final int delay;

  @override
  State<FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<FlipTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _showFront = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween(begin: 0.0, end: pi).animate(_controller)
      ..addListener(() {
        if (_animation.value > pi / 2 && _showFront) {
          setState(() {
            _showFront = false;
          });
        }
      });

    if (widget.animate) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        _controller.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant FlipTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animate && !_controller.isAnimating) {
      _showFront = true;
      _controller.reset();

      Future.delayed(Duration(milliseconds: widget.delay), () {
        _controller.forward();
      });
    }
  }

  Color getColor() {
    switch (widget.hitType) {
      case HitType.hit:
        return Colors.green;
      case HitType.partial:
        return Colors.yellow;
      case HitType.miss:
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        final angle = _animation.value;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(angle),
          child: Container(
            margin: const EdgeInsets.all(2),
            height: 55,
            width: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: _showFront ? Colors.white : getColor(),
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(angle > pi / 2 ? pi : 0),
              child: Text(
                widget.letter.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Game _game = Game();

  String currentGuess = '';
  final FocusNode _focusNode = FocusNode();

  Map<String, HitType> keyboardState = {};
  int lastAnimatedRow = -1;

  void addLetter(String letter) {
    if (_game.didWin || _game.didLose) return;
    if (currentGuess.length >= 5) return;

    setState(() {
      currentGuess += letter;
    });
  }

  void removeLetter() {
    if (currentGuess.isEmpty) return;

    setState(() {
      currentGuess =
          currentGuess.substring(0, currentGuess.length - 1);
    });
  }

  void submitGuess() {
    if (_game.didWin || _game.didLose) return;

    if (currentGuess.length != 5) return;

    if (!_game.isLegalGuess(currentGuess)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palavra inválida')),
      );
      return;
    }

    final result = _game.guess(currentGuess);

    for (var letter in result) {
      final current = keyboardState[letter.char];

      if (current == HitType.hit) continue;

      if (letter.type == HitType.hit ||
          (letter.type == HitType.partial && current != HitType.hit)) {
        keyboardState[letter.char] = letter.type;
      } else if (current == null) {
        keyboardState[letter.char] = letter.type;
      }
    }

    setState(() {
      lastAnimatedRow = _game.activeIndex - 1;
      currentGuess = '';
    });

    if (_game.didWin) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('🎉 Você ganhou!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetGame();
                },
                child: const Text('Reiniciar'),
              )
            ],
          ),
        );
      });
    } else if (_game.didLose) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('😢 Você perdeu!'),
            content: Text('Palavra: ${_game.hiddenWord}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  resetGame();
                },
                child: const Text('Reiniciar'),
              )
            ],
          ),
        );
      });
    }
  }

  void resetGame() {
    setState(() {
      _game.resetGame();
      currentGuess = '';
      keyboardState.clear();
      lastAnimatedRow = -1;
    });
  }

  Widget buildGrid() {
    final activeIndex = _game.activeIndex;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _game.guesses.length; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int j = 0; j < 5; j++)
                Builder(
                  builder: (_) {
                    if (i < activeIndex) {
                      final letter = _game.guesses[i][j];
                      return FlipTile(
                        letter: letter.char,
                        hitType: letter.type,
                        animate: i == lastAnimatedRow,
                        delay: j * 300,
                      );
                    }

                    if (i == activeIndex) {
                      final char =
                          j < currentGuess.length ? currentGuess[j] : '';
                      return FlipTile(
                        letter: char,
                        hitType: HitType.none,
                        animate: false,
                        delay: 0,
                      );
                    }

                    return const FlipTile(
                      letter: '',
                      hitType: HitType.none,
                      animate: false,
                      delay: 0,
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  Widget buildKeyboard() {
    List<List<String>> rows = [
      ['q','w','e','r','t','y','u','i','o','p'],
      ['a','s','d','f','g','h','j','k','l'],
      ['z','x','c','v','b','n','m'],
    ];

    return Column(
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((letter) {
            final type = keyboardState[letter];

            Color color;
            switch (type) {
              case HitType.hit:
                color = Colors.green;
                break;
              case HitType.partial:
                color = Colors.yellow;
                break;
              case HitType.miss:
                color = Colors.grey;
                break;
              default:
                color = Colors.white;
            }

            return Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(letter.toUpperCase()),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  void handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter) {
      submitGuess();
    } else if (key == LogicalKeyboardKey.backspace) {
      removeLetter();
    } else {
      final label = key.keyLabel.toLowerCase();
      if (RegExp(r'^[a-z]$').hasMatch(label)) {
        addLetter(label);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: handleKey,
      child: Column(
        children: [
          Expanded(child: buildGrid()),
          buildKeyboard(),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: resetGame,
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}