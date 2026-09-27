import 'package:flutter/material.dart';
import 'dart:ui';

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
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6), // Vibrant Violet
          secondary: Color(0xFF10B981), // Mint Green
          surface: Color(0xFF1E1B4B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const GameSetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Gorgeous Gradient Background Wrapper
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Deep Slate Blue
            Color(0xFF2E1065), // Rich Violet
            Color(0xFF4C1D95), // Deep Purple
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle glowing orb top-right
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent.withOpacity(0.15),
              ),
            ),
          ),
          // Subtle glowing orb bottom-left
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withOpacity(0.15),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
          SafeArea(child: child),
        ],
      ),
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
        _players.add(_playerController.text.trim().toUpperCase());
        _playerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MARRIAGE TABLE')),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Players (2 to 5):',
                style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              // Input Field
              TextField(
                controller: _playerController,
                maxLength: 12,
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter player name...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFC4B5FD)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF34D399), size: 28),
                    onPressed: _players.length < 5 ? _addPlayer : null,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                  ),
                ),
                onSubmitted: (_) => _addPlayer(),
              ),
              const SizedBox(height: 20),
              // Player List
              Expanded(
                child: _players.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 64, color: Colors.white24),
                            const SizedBox(height: 10),
                            const Text('No players added yet\nTap + to build the table', 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Color(0xFFC4B5FD), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                _players[index],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
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
              // Next Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
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
                child: const Text('SELECT TIPLU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
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

  Color _getSuitColor(String suit) {
    if (suit.contains('♥') || suit.contains('♦')) return Colors.redAccent;
    return Colors.amberAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHOOSE TIPLU')),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select the Cut-Joker card for this round:',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 25),
              _buildSelector('Suit', selectedSuit, suits, (val) => setState(() => selectedSuit = val!)),
              const SizedBox(height: 20),
              _buildSelector('Rank', selectedRank, ranks, (val) => setState(() => selectedRank = val!)),
              const Spacer(),
              // Gorgeous Preview Card
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.04)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('TIPLU CARD', style: TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 12)),
                    const SizedBox(height: 10),
                    Text(
                      selectedRank,
                      style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      selectedSuit,
                      style: TextStyle(fontSize: 26, color: _getSuitColor(selectedSuit), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
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
                child: const Text('ENTER MAAL POINTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelector(String title, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1B4B),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFC4B5FD)),
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
      appBar: AppBar(title: const Text('COUNT MAAL')),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Tiplu banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'TIPLU: ${widget.tiplu}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Adjust points for each player:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.players.length,
                  itemBuilder: (context, index) {
                    String player = widget.players[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: ListTile(
                        title: Text(
                          player,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                              onPressed: () {
                                setState(() {
                                  if ((_playerPoints[player] ?? 0) > 0) {
                                    _playerPoints[player] = (_playerPoints[player] ?? 0) - 1;
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                '${_playerPoints[player]}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF34D399)),
                              onPressed: () {
                                setState(() {
                                  _playerPoints[player] = (_playerPoints[player] ?? 0) + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
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
                child: const Text('VIEW SUMMARY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
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

  List<MapEntry<String, int>> _getSortedScores() {
    var entries = playerPoints.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final sortedScores = _getSortedScores();
    final winner = sortedScores.first;

    return Scaffold(
      appBar: AppBar(title: const Text('GAME OVER')),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Winner Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      winner.key,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text('WINS THE ROUND!', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      '${winner.value} Points',
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text('FINAL STANDINGS', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedScores.length,
                  itemBuilder: (context, index) {
                    final entry = sortedScores[index];
                    final isWinner = index == 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isWinner ? 0.1 : 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isWinner ? Colors.amber.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isWinner ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          child: Icon(
                            isWinner ? Icons.military_tech : Icons.person,
                            color: isWinner ? Colors.amberAccent : Colors.white7Div ?? Colors.white70,
                          ),
                        ),
                        title: Text(
                          entry.key,
                          style: TextStyle(
                            color: isWinner ? Colors.amberAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        trailing: Text(
                          '${entry.value} pts',
                          style: TextStyle(
                            fontSize: 20,
                            color: isWinner ? Colors.amberAccent : const Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Vibrant Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('START NEW ROUND', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}