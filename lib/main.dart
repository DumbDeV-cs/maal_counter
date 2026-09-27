import 'package:flutter/material.dart';

void main() {
  runApp(const MarriageCounterApp());
}

class MarriageCounterApp extends StatelessWidget {
  const MarriageCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marriage Taas Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameSetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final TextEditingController _playerController = TextEditingController();
  final List<String> _players = [];

  void _addPlayer() {
    if (_playerController.text.trim().isNotEmpty && _players.length < 5) {
      setState(() {
        _players.add(_playerController.text.trim());
        _playerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marriage Game Setup'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Players (2 to 5 players):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerController,
                    decoration: const InputDecoration(
                      labelText: 'Player Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _players.length < 5 ? _addPlayer : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(_players[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _players.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _players.length >= 2
                  ? () {
                      // TODO: Navigate to Tiplu & Maal calculation screen
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Game', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}