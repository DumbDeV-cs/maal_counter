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

// 1. Game Setup Screen
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TipluSelectionScreen(players: _players),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Next: Select Tiplu', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Tiplu Selection Screen
class TipluSelectionScreen extends StatefulWidget {
  final List<String> players;
  const TipluSelectionScreen({super.key, required this.players});

  @override
  State<TipluSelectionScreen> createState() => _TipluSelectionScreenState();
}

class _TipluSelectionScreenState extends State<TipluSelectionScreen> {
  String selectedSuit = 'Spades ♠';
  String selectedRank = 'Jack';

  final List<String> suits = ['Spades ♠', 'Hearts ♥', 'Diamonds ♦', 'Clubs ♣'];
  final List<String> ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Tiplu Card'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose the Cut-Joker (Tiplu) for this round:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Suit:', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              value: selectedSuit,
              isExpanded: true,
              items: suits.map((suit) {
                return DropdownMenuItem(value: suit, child: Text(suit));
              }).toList(),
              onChanged: (val) => setState(() => selectedSuit = val!),
            ),
            const SizedBox(height: 20),
            const Text('Rank:', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              value: selectedRank,
              isExpanded: true,
              items: ranks.map((rank) {
                return DropdownMenuItem(value: rank, child: Text(rank));
              }).toList(),
              onChanged: (val) => setState(() => selectedRank = val!),
            ),
            const Spacer(),
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Selected Tiplu: $selectedRank of $selectedSuit',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaalInputScreen(
                      players: widget.players,
                      tiplu: '$selectedRank of $selectedSuit',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Enter Maal Points', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Maal Input Screen
class MaalInputScreen extends StatefulWidget {
  final List<String> players;
  final String tiplu;

  const MaalInputScreen({super.key, required this.players, required this.tiplu});

  @override
  State<MaalInputScreen> createState() => _MaalInputScreenState();
}

class _MaalInputScreenState extends State<MaalInputScreen> {
  final Map<String, int> _playerPoints = {};

  @override
  void initState() {
    super.initState();
    for (var player in widget.players) {
      _playerPoints[player] = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Count Maal Points'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Tiplu: ${widget.tiplu}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            const Text(
              'Adjust points for each player:',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.players.length,
                itemBuilder: (context, index) {
                  String player = widget.players[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            player,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    if ((_playerPoints[player] ?? 0) > 0) {
                                      _playerPoints[player] = (_playerPoints[player] ?? 0) - 1;
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${_playerPoints[player]} pts',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    _playerPoints[player] = (_playerPoints[player] ?? 0) + 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
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
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScoreSummaryScreen(
                      playerPoints: _playerPoints,
                      tiplu: widget.tiplu,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.assessment),
              label: const Text('Calculate Settlement', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. Score Summary Screen
class ScoreSummaryScreen extends StatelessWidget {
  final Map<String, int> playerPoints;
  final String tiplu;

  const ScoreSummaryScreen({super.key, required this.playerPoints, required this.tiplu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settlement Scorecard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tiplu: $tiplu',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Final Maal Breakdown:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: playerPoints.entries.map((entry) {
                  return Card(
                    child: ListTile(
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        '${entry.value} Points',
                        style: const TextStyle(fontSize: 16, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Start New Round', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}