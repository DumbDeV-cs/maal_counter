import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MarriageCounterApp());
}

// Avatar Model
class AvatarData {
  final IconData icon;
  final Color color;
  final String name;

  const AvatarData({required this.icon, required this.color, required this.name});
}

const List<AvatarData> availableAvatars = [
  AvatarData(icon: Icons.style, color: Color(0xFFEC4899), name: 'Cards'),
  AvatarData(icon: Icons.casino, color: Color(0xFF3B82F6), name: 'Dice'),
  AvatarData(icon: Icons.emoji_events, color: Color(0xFFF59E0B), name: 'Trophy'),
  AvatarData(icon: Icons.face, color: Color(0xFF10B981), name: 'King'),
  AvatarData(icon: Icons.local_fire_department, color: Color(0xFFEF4444), name: 'Fire'),
  AvatarData(icon: Icons.auto_awesome, color: Color(0xFF06B6D4), name: 'Star'),
  AvatarData(icon: Icons.psychology, color: Color(0xFF8B5CF6), name: 'Brain'),
  AvatarData(icon: Icons.sports_esports, color: Color(0xFF6366F1), name: 'Gamer'),
];

// Player Model
class Player {
  final String name;
  final int avatarIndex;
  final PlayerMaal maal;
  int cumulativeScore;

  Player({required this.name, required this.avatarIndex, this.cumulativeScore = 0}) 
      : maal = PlayerMaal();

  void resetRound() {
    maal.hasMarriage = false;
    maal.hasTunnel = false;
    maal.hasTiplu = false;
    maal.hasAlte = false;
    maal.hasJhal = false;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'avatarIndex': avatarIndex,
    'cumulativeScore': cumulativeScore,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      avatarIndex: json['avatarIndex'],
      cumulativeScore: json['cumulativeScore'],
    );
  }
}

// Model for Player Maal Options
class PlayerMaal {
  bool hasMarriage = false; // 10 pts
  bool hasTunnel = false;   // 5 pts
  bool hasTiplu = false;    // 3 pts
  bool hasAlte = false;     // 3 pts
  bool hasJhal = false;     // 3 pts

  int get totalPoints => 
    (hasMarriage ? 10 : 0) + 
    (hasTunnel ? 5 : 0) + 
    (hasTiplu ? 3 : 0) + 
    (hasAlte ? 3 : 0) + 
    (hasJhal ? 3 : 0);
}

// Centralized Game Session Controller with SharedPreferences Storage
class GameSession {
  final List<Player> players;
  final List<Map<String, int>> roundHistory = [];

  GameSession({required this.players});

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('saved_players', jsonEncode(players.map((p) => p.toJson()).toList()));
    prefs.setString('saved_history', jsonEncode(roundHistory));
  }

  static Future<GameSession?> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final playersStr = prefs.getString('saved_players');
    final historyStr = prefs.getString('saved_history');

    if (playersStr != null) {
      List decodedPlayers = jsonDecode(playersStr);
      List<Player> players = decodedPlayers.map((item) => Player.fromJson(item)).toList();
      
      GameSession session = GameSession(players: players);

      if (historyStr != null) {
        List decodedHistory = jsonDecode(historyStr);
        for (var h in decodedHistory) {
          session.roundHistory.add(Map<String, int>.from(h));
        }
      }
      return session;
    }
    return null;
  }

  Future<void> recordRound(Map<String, int> roundPoints) async {
    roundHistory.add(roundPoints);
    for (var player in players) {
      player.cumulativeScore += roundPoints[player.name] ?? 0;
    }
    await saveToStorage();
  }

  Future<bool> undoLastRound() async {
    if (roundHistory.isNotEmpty) {
      final lastRound = roundHistory.removeLast();
      for (var player in players) {
        player.cumulativeScore -= lastRound[player.name] ?? 0;
      }
      await saveToStorage();
      return true;
    }
    return false;
  }

  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('saved_players');
    prefs.remove('saved_history');
  }
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
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF10B981),
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

// Gradient Background Wrapper
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
            Color(0xFF0F172A),
            Color(0xFF2E1065),
            Color(0xFF4C1D95),
          ],
        ),
      ),
      child: Stack(
        children: [
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
  final List<Player> _players = [];
  int _selectedAvatarIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() async {
    GameSession? existingSession = await GameSession.loadFromStorage();
    if (existingSession != null && existingSession.players.isNotEmpty && mounted) {
      // Prompt user or automatically resume
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TipluSelectionScreen(gameSession: existingSession),
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _addPlayer() {
    if (_playerController.text.trim().isNotEmpty && _players.length < 5) {
      setState(() {
        _players.add(
          Player(
            name: _playerController.text.trim().toUpperCase(),
            avatarIndex: _selectedAvatarIndex,
          ),
        );
        _playerController.clear();
        _selectedAvatarIndex = (_selectedAvatarIndex + 1) % availableAvatars.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    final activeAvatar = availableAvatars[_selectedAvatarIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('MARRIAGE TABLE')),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Profile Icon:',
                style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableAvatars.length,
                  itemBuilder: (context, index) {
                    final avatar = availableAvatars[index];
                    final isSelected = index == _selectedAvatarIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: avatar.color,
                          radius: isSelected ? 24 : 20,
                          child: Icon(avatar.icon, color: Colors.white, size: isSelected ? 24 : 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _playerController,
                maxLength: 12,
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter player name...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: activeAvatar.color,
                      child: Icon(activeAvatar.icon, color: Colors.white, size: 20),
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF34D399), size: 30),
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
              Expanded(
                child: _players.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 64, color: Colors.white24),
                            SizedBox(height: 10),
                            Text(
                              'No players added yet\nPick an icon & tap + to add',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          final player = _players[index];
                          final avatar = availableAvatars[player.avatarIndex];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: avatar.color,
                                  child: Icon(avatar.icon, color: Colors.white, size: 22),
                                ),
                                title: Text(
                                  player.name,
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
                onPressed: _players.length >= 2
                    ? () async {
                        final gameSession = GameSession(players: _players);
                        await gameSession.saveToStorage();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim1, anim2) => TipluSelectionScreen(gameSession: gameSession),
                            transitionsBuilder: (context, anim1, anim2, child) {
                              return FadeTransition(opacity: anim1, child: child);
                            },
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
  final GameSession gameSession;
  const TipluSelectionScreen({super.key, required this.gameSession});

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
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
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
                  for (var p in widget.gameSession.players) {
                    p.resetRound();
                  }
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, anim1, anim2) => MaalInputScreen(
                        gameSession: widget.gameSession,
                        tiplu: '$selectedRank of $selectedSuit',
                      ),
                      transitionsBuilder: (context, anim1, anim2, child) {
                        return FadeTransition(opacity: anim1, child: child);
                      },
                    ),
                  );
                },
                child: const Text('CHOOSE MAAL OPTIONS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
  final GameSession gameSession;
  final String tiplu;

  const MaalInputScreen({super.key, required this.gameSession, required this.tiplu});

  @override
  State<MaalInputScreen> createState() => _MaalInputScreenState();
}

class _MaalInputScreenState extends State<MaalInputScreen> {
  @override
  Widget build(BuildContext context) {
    final players = widget.gameSession.players;

    return Scaffold(
      appBar: AppBar(title: const Text('CHOOSE PLAYER MAAL')),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select what each player holds:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final avatar = availableAvatars[player.avatarIndex];
                    final maal = player.maal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ExpansionTile(
                          collapsedIconColor: const Color(0xFFC4B5FD),
                          iconColor: const Color(0xFF34D399),
                          leading: CircleAvatar(
                            backgroundColor: avatar.color,
                            child: Icon(avatar.icon, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34D399).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
                            ),
                            child: Text(
                              '${maal.totalPoints} pts',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  _buildChoiceChip('Marriage (10pts)', maal.hasMarriage, (val) {
                                    setState(() => maal.hasMarriage = val);
                                  }),
                                  _buildChoiceChip('Tunnel/3-Pattia (5pts)', maal.hasTunnel, (val) {
                                    setState(() => maal.hasTunnel = val);
                                  }),
                                  _buildChoiceChip('Tiplu (3pts)', maal.hasTiplu, (val) {
                                    setState(() => maal.hasTiplu = val);
                                  }),
                                  _buildChoiceChip('Alte (3pts)', maal.hasAlte, (val) {
                                    setState(() => maal.hasAlte = val);
                                  }),
                                  _buildChoiceChip('Jhal (3pts)', maal.hasJhal, (val) {
                                    setState(() => maal.hasJhal = val);
                                  }),
                                ],
                              ),
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
                onPressed: () async {
                  Map<String, int> roundPoints = {};
                  for (var p in players) {
                    roundPoints[p.name] = p.maal.totalPoints;
                  }
                  await widget.gameSession.recordRound(roundPoints);

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, anim1, anim2) => ScoreSummaryScreen(
                          gameSession: widget.gameSession,
                          tiplu: widget.tiplu,
                        ),
                        transitionsBuilder: (context, anim1, anim2, child) {
                          return FadeTransition(opacity: anim1, child: child);
                        },
                      ),
                    );
                  }
                },
                child: const Text('VIEW SUMMARY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, ValueChanged<bool> onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF8B5CF6),
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.08),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFFC4B5FD) : Colors.white.withOpacity(0.15),
        ),
      ),
    );
  }
}

// 4. Score Summary Screen with Celebration, Undo, & History Table
class ScoreSummaryScreen extends StatefulWidget {
  final GameSession gameSession;
  final String tiplu;

  const ScoreSummaryScreen({super.key, required this.gameSession, required this.tiplu});

  @override
  State<ScoreSummaryScreen> createState() => _ScoreSummaryScreenState();
}

class _ScoreSummaryScreenState extends State<ScoreSummaryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<Player> _getSortedPlayers() {
    List<Player> list = List.from(widget.gameSession.players);
    list.sort((a, b) => b.cumulativeScore.compareTo(a.cumulativeScore));
    return list;
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final players = widget.gameSession.players;
        final history = widget.gameSession.roundHistory;

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Round History Matrix', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: history.isEmpty
              ? const Text('No rounds played yet.', style: TextStyle(color: Colors.white70))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, roundIndex) {
                      final roundData = history[roundIndex];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Round ${roundIndex + 1}',
                              style: const TextStyle(color: Color(0xFFC4B5FD), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 12,
                              children: players.map((p) {
                                int pts = roundData[p.name] ?? 0;
                                return Text(
                                  '${p.name}: +$pts',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF8B5CF6))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = _getSortedPlayers();
    final leader = sortedPlayers.first;
    final leaderAvatar = availableAvatars[leader.avatarIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('STANDINGS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFFC4B5FD)),
            tooltip: 'View Round History',
            onPressed: _showHistoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.orangeAccent),
            tooltip: 'Undo Last Round',
            onPressed: () async {
              bool success = await widget.gameSession.undoLastRound();
              if (success && mounted) {
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No rounds to undo!')),
                );
              }
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: VictoryConfettiPainter(_confettiController.value),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: leaderAvatar.color,
                              child: Icon(leaderAvatar.icon, color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            leader.name,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text('ROUND LEADER', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            '${leader.cumulativeScore} Total Points',
                            style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text('CUMULATIVE LEADERBOARD', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedPlayers.length,
                      itemBuilder: (context, index) {
                        final player = sortedPlayers[index];
                        final avatar = availableAvatars[player.avatarIndex];
                        final isLeader = index == 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isLeader ? 0.1 : 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isLeader ? Colors.amber.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: avatar.color,
                                child: Icon(avatar.icon, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                player.name,
                                style: TextStyle(
                                  color: isLeader ? Colors.amberAccent : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              trailing: Text(
                                '${player.cumulativeScore} pts',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isLeader ? Colors.amberAccent : const Color(0xFF34D399),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, anim1, anim2) => TipluSelectionScreen(gameSession: widget.gameSession),
                                transitionsBuilder: (context, anim1, anim2, child) {
                                  return FadeTransition(opacity: anim1, child: child);
                                },
                              ),
                            );
                          },
                          child: const Text('NEXT ROUND', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            await widget.gameSession.clearStorage();
                            if (context.mounted) {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            }
                          },
                          child: const Text('NEW GAME', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Particle/Confetti Burst Celebration Effect
class VictoryConfettiPainter extends CustomPainter {
  final double progress;
  VictoryConfettiPainter(this.progress);

  final List<_Particle> particles = List.generate(35, (index) {
    final random = math.Random(index);
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble() * 0.4 + 0.1,
      color: [Colors.amber, Colors.pinkAccent, Colors.cyanAccent, Colors.greenAccent, Colors.purpleAccent][random.nextInt(5)],
      size: random.nextDouble() * 6 + 4,
      speedX: (random.nextDouble() - 0.5) * 1.5,
      speedY: random.nextDouble() * -1.2 - 0.5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity((1.0 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final currentX = (particle.x * size.width + particle.speedX * progress * 150) % size.width;
      final currentY = particle.y * size.height + particle.speedY * progress * 250 + (progress * progress * 100);

      canvas.drawCircle(Offset(currentX, currentY), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VictoryConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _Particle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double speedX;
  final double speedY;

  _Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedX,
    required this.speedY,
  });
}