import 'package:flutter/material.dart';
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
        appBar: AppBar(
          title: const Text('Birdle'),
        ),
        body: const GamePage(),
      ),
    );
  }
}

class Tile extends StatelessWidget {
  const Tile(this.letter, this.hitType, {super.key});

  final String letter;
  final HitType hitType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: switch (hitType) {
          HitType.hit => Colors.green,
          HitType.partial => Colors.yellow,
          HitType.miss => Colors.grey,
          _ => Colors.white,
        },
      ),
      child: Text(
        letter.toUpperCase(),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  void submitGuess(String guess) {
    if (guess.length != 5) return;

    if (!_game.isLegalGuess(guess)) {
      print("Palavra inválida");
      return;
    }

    setState(() {
      _game.guess(guess);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // GRID
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var guess in _game.guesses)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var letter in guess)
                        Tile(letter.char, letter.type),
                    ],
                  ),
              ],
            ),
          ),

          // INPUT
          GuessInput(
            onSubmitGuess: submitGuess,
          ),
        ],
      ),
    );
  }
}

class GuessInput extends StatefulWidget {
  const GuessInput({super.key, required this.onSubmitGuess});

  final void Function(String) onSubmitGuess;

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _onSubmit() {
    widget.onSubmitGuess(_controller.text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLength: 5,
              autofocus: true,
              decoration: const InputDecoration(
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              onSubmitted: (_) => _onSubmit(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_circle_up),
          onPressed: _onSubmit,
        ),
      ],
    );
  }
}