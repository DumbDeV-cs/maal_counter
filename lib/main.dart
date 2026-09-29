import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MarriageCounterApp());
}

// ---------------------------------------------------------------------------
// Avatar Model
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// House Rules (all point values are editable from the setup screen)
// ---------------------------------------------------------------------------
class HouseRules {
  int marriageHigh; // Marriage option 1 (default 15)
  int marriageLow; // Marriage option 2 (default 10)
  List<int> maalPoints; // index = number of maal (0, 1, 2)
  int tipluPerCard; // points per tiplu
  List<int> alterPoints; // index = number of alter (0..3)
  List<int> jokerPoints; // index = number of joker (0..3)
  int winnerFullPoints; // winner gets this from a player who has NOT shown sequences
  int winnerReducedPoints; // winner gets this from a player who HAS shown sequences

  HouseRules({
    this.marriageHigh = 15,
    this.marriageLow = 10,
    List<int>? maalPoints,
    this.tipluPerCard = 2,
    List<int>? alterPoints,
    List<int>? jokerPoints,
    this.winnerFullPoints = 10,
    this.winnerReducedPoints = 3,
  })  : maalPoints = maalPoints ?? [0, 3, 8],
        alterPoints = alterPoints ?? [0, 5, 15, 20],
        jokerPoints = jokerPoints ?? [0, 5, 15, 20];

  int get maxMaal => maalPoints.length - 1;
  int get maxAlter => alterPoints.length - 1;
  int get maxJoker => jokerPoints.length - 1;

  Map<String, dynamic> toJson() => {
        'marriageHigh': marriageHigh,
        'marriageLow': marriageLow,
        'maal': maalPoints,
        'tipluPerCard': tipluPerCard,
        'alter': alterPoints,
        'joker': jokerPoints,
        'winnerFull': winnerFullPoints,
        'winnerReduced': winnerReducedPoints,
      };

  factory HouseRules.fromJson(Map<String, dynamic> json) {
    return HouseRules(
      marriageHigh: json['marriageHigh'] ?? 15,
      marriageLow: json['marriageLow'] ?? 10,
      maalPoints: json['maal'] != null ? List<int>.from(json['maal']) : null,
      tipluPerCard: json['tipluPerCard'] ?? 2,
      alterPoints: json['alter'] != null ? List<int>.from(json['alter']) : null,
      jokerPoints: json['joker'] != null ? List<int>.from(json['joker']) : null,
      winnerFullPoints: json['winnerFull'] ?? 10,
      winnerReducedPoints: json['winnerReduced'] ?? 3,
    );
  }
}

// ---------------------------------------------------------------------------
// Player Model
// ---------------------------------------------------------------------------
class Player {
  final String name;
  final int avatarIndex;
  final PlayerMaal maal;
  int cumulativeScore;

  Player({required this.name, required this.avatarIndex, this.cumulativeScore = 0})
      : maal = PlayerMaal();

  void resetRound() => maal.reset();

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarIndex': avatarIndex,
        'cumulativeScore': cumulativeScore,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      avatarIndex: json['avatarIndex'],
      cumulativeScore: json['cumulativeScore'] ?? 0,
    );
  }
}

// What a player holds in one round
class PlayerMaal {
  bool hasMarriageHigh = false; // e.g. 15 pts
  bool hasMarriageLow = false; // e.g. 10 pts
  int maalCount = 0;
  int tipluCount = 0;
  int alterCount = 0;
  int jokerCount = 0;
  bool hasShownSequence = false;

  void reset() {
    hasMarriageHigh = false;
    hasMarriageLow = false;
    maalCount = 0;
    tipluCount = 0;
    alterCount = 0;
    jokerCount = 0;
    hasShownSequence = false;
  }

  int getTotalPoints(HouseRules rules) {
    int total = 0;
    if (hasMarriageHigh) total += rules.marriageHigh;
    if (hasMarriageLow) total += rules.marriageLow;
    total += rules.maalPoints[maalCount.clamp(0, rules.maxMaal)];
    total += tipluCount * rules.tipluPerCard;
    total += rules.alterPoints[alterCount.clamp(0, rules.maxAlter)];
    total += rules.jokerPoints[jokerCount.clamp(0, rules.maxJoker)];
    return total;
  }
}

// ---------------------------------------------------------------------------
// Game Session Controller with SharedPreferences Storage
// ---------------------------------------------------------------------------
class GameSession {
  final List<Player> players;
  final HouseRules houseRules;
  final List<Map<String, int>> roundHistory = [];

  GameSession({required this.players, HouseRules? houseRules})
      : houseRules = houseRules ?? HouseRules();

  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_players', jsonEncode(players.map((p) => p.toJson()).toList()));
    await prefs.setString('saved_history', jsonEncode(roundHistory));
    await prefs.setString('saved_rules', jsonEncode(houseRules.toJson()));
  }

  static Future<GameSession?> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playersStr = prefs.getString('saved_players');
      final historyStr = prefs.getString('saved_history');
      final rulesStr = prefs.getString('saved_rules');

      if (playersStr != null) {
        List decodedPlayers = jsonDecode(playersStr);
        List<Player> players = decodedPlayers.map((item) => Player.fromJson(item)).toList();

        HouseRules rules = rulesStr != null ? HouseRules.fromJson(jsonDecode(rulesStr)) : HouseRules();

        GameSession session = GameSession(players: players, houseRules: rules);

        if (historyStr != null) {
          List decodedHistory = jsonDecode(historyStr);
          for (var h in decodedHistory) {
            session.roundHistory.add(Map<String, int>.from(h));
          }
        }
        return session;
      }
    } catch (_) {
      // corrupted / old-format save: ignore and start fresh
    }
    return null;
  }

  /// Calculates this round's points for every player:
  ///  - each player's own maal/marriage/tiplu/alter/joker points
  ///  - winner (the one who showed) collects from every other player:
  ///      winnerFullPoints if that player has NOT shown sequences,
  ///      winnerReducedPoints if that player HAS shown sequences.
  ///    The amount is subtracted from the paying player.
  Map<String, int> calculateRound(String winnerName) {
    final Map<String, int> points = {};
    for (var p in players) {
      points[p.name] = p.maal.getTotalPoints(houseRules);
    }
    for (var p in players) {
      if (p.name == winnerName) continue;
      final pay = p.maal.hasShownSequence
          ? houseRules.winnerReducedPoints
          : houseRules.winnerFullPoints;
      points[p.name] = (points[p.name] ?? 0) - pay;
      points[winnerName] = (points[winnerName] ?? 0) + pay;
    }
    return points;
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

  static Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_players');
    await prefs.remove('saved_history');
    await prefs.remove('saved_rules');
  }
}

String _signed(int v) => v > 0 ? '+$v' : '$v';

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
          colors: [Color(0xFF0F172A), Color(0xFF2E1065), Color(0xFF4C1D95)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.pinkAccent.withOpacity(0.15)),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyanAccent.withOpacity(0.15)),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Game Setup Screen (always opens here; old game can be resumed or discarded)
// ---------------------------------------------------------------------------
class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _playerController = TextEditingController();
  final List<Player> _players = [];
  final HouseRules _houseRules = HouseRules();
  GameSession? _savedSession;
  int _selectedAvatarIndex = 0;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadSavedGame();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _playerController.dispose();
    super.dispose();
  }

  // Only LOAD the old game; never force the user into it.
  void _loadSavedGame() async {
    final existing = await GameSession.loadFromStorage();
    if (!mounted) return;
    setState(() {
      _savedSession = (existing != null && existing.players.isNotEmpty) ? existing : null;
      _isLoading = false;
    });
    _fadeController.forward();
  }

  void _addPlayer() {
    final name = _playerController.text.trim().toUpperCase();
    if (name.isEmpty || _players.length >= 5) return;
    if (_players.any((p) => p.name == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That name is already added. Use a different name.')),
      );
      return;
    }
    setState(() {
      _players.add(Player(name: name, avatarIndex: _selectedAvatarIndex));
      _playerController.clear();
      _selectedAvatarIndex = (_selectedAvatarIndex + 1) % availableAvatars.length;
    });
  }

  void _showHouseRulesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget row(String label, int value, ValueChanged<int> onChanged) {
              return _buildRuleRow(label, value, (val) {
                setDialogState(() => onChanged(val));
                setState(() {});
              });
            }

            Widget header(String text) => Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(text.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  ),
                );

            final r = _houseRules;
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1B4B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.rule, color: Color(0xFF34D399)),
                  SizedBox(width: 10),
                  Text('House Rules', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Customize point values for this match:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      header('Marriage'),
                      row('Marriage (option 1)', r.marriageHigh, (v) => r.marriageHigh = v),
                      row('Marriage (option 2)', r.marriageLow, (v) => r.marriageLow = v),
                      header('Maal'),
                      row('1 Maal', r.maalPoints[1], (v) => r.maalPoints[1] = v),
                      row('2 Maal', r.maalPoints[2], (v) => r.maalPoints[2] = v),
                      header('Tiplu'),
                      row('Per Tiplu', r.tipluPerCard, (v) => r.tipluPerCard = v),
                      header('Alter'),
                      row('1 Alter', r.alterPoints[1], (v) => r.alterPoints[1] = v),
                      row('2 Alter', r.alterPoints[2], (v) => r.alterPoints[2] = v),
                      row('3 Alter', r.alterPoints[3], (v) => r.alterPoints[3] = v),
                      header('Joker'),
                      row('1 Joker', r.jokerPoints[1], (v) => r.jokerPoints[1] = v),
                      row('2 Joker', r.jokerPoints[2], (v) => r.jokerPoints[2] = v),
                      row('3 Joker', r.jokerPoints[3], (v) => r.jokerPoints[3] = v),
                      header('Winner (showed cards)'),
                      row('From player w/o sequences', r.winnerFullPoints, (v) => r.winnerFullPoints = v),
                      row('From player with sequences', r.winnerReducedPoints, (v) => r.winnerReducedPoints = v),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRuleRow(String label, int currentVal, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
            onPressed: currentVal > 0 ? () => onChanged(currentVal - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text('$currentVal',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF34D399), size: 20),
            onPressed: () => onChanged(currentVal + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeCard() {
    final saved = _savedSession!;
    final names = saved.players.map((p) => p.name).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34D399).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UNFINISHED GAME FOUND',
              style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text('$names  •  ${saved.roundHistory.length} round(s)',
              style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34D399),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TipluSelectionScreen(gameSession: saved)),
                    );
                  },
                  child: const Text('RESUME', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await GameSession.clearStorage();
                    if (mounted) setState(() => _savedSession = null);
                  },
                  child: const Text('DISCARD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: const Text('MARRIAGE TABLE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rule, color: Color(0xFF34D399)),
            tooltip: 'Configure House Rules',
            onPressed: _showHouseRulesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.code, color: Color(0xFFC4B5FD)),
            tooltip: 'Developer Info',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1B4B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Row(
                    children: [
                      Icon(Icons.terminal, color: Color(0xFF8B5CF6)),
                      SizedBox(width: 10),
                      Text('Developer', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('App: Marriage Taas Counter', style: TextStyle(color: Colors.white70, fontSize: 15)),
                      SizedBox(height: 8),
                      Text('Developer: Prabesh Dhital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('GitHub: DumbDev-cs', style: TextStyle(color: Color(0xFF34D399), fontSize: 14)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF8B5CF6))),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_savedSession != null) _buildResumeCard(),
                // Developer Badge Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFF8B5CF6),
                        backgroundImage: AssetImage('assets/mascot.png'),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PRABESH DHITAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('GitHub: DumbDev-cs', style: TextStyle(color: Color(0xFF34D399), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'NEW GAME - Select Profile Icon:',
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
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2.5),
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
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + (index * 80)),
                              builder: (context, val, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - val)),
                                  child: Opacity(opacity: val, child: child),
                                );
                              },
                              child: Container(
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
                                      onPressed: () => setState(() => _players.removeAt(index)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _players.length >= 2
                        ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
                        : [],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _players.length >= 2
                        ? () async {
                            // Starting a fresh game overwrites any old saved game
                            final gameSession = GameSession(players: List.from(_players), houseRules: _houseRules);
                            await gameSession.saveToStorage();
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, anim1, anim2) => TipluSelectionScreen(gameSession: gameSession),
                                  transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
                                ),
                              );
                            }
                          }
                        : null,
                    child: const Text('START NEW GAME', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Tiplu Selection Screen
// ---------------------------------------------------------------------------
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
                tween: Tween<double>(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      const Text('TIPLU CARD', style: TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 12)),
                      const SizedBox(height: 10),
                      Text(selectedRank, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 5),
                      Text(selectedSuit, style: TextStyle(fontSize: 26, color: _getSuitColor(selectedSuit), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
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
                        transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
                      ),
                    );
                  },
                  child: const Text('CHOOSE MAAL OPTIONS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
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
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Maal Input Screen (Marriage / Maal / Tiplu / Alter / Joker + Winner)
// ---------------------------------------------------------------------------
class MaalInputScreen extends StatefulWidget {
  final GameSession gameSession;
  final String tiplu;

  const MaalInputScreen({super.key, required this.gameSession, required this.tiplu});

  @override
  State<MaalInputScreen> createState() => _MaalInputScreenState();
}

class _MaalInputScreenState extends State<MaalInputScreen> {
  String? _winnerName; // player who showed the cards

  @override
  Widget build(BuildContext context) {
    final players = widget.gameSession.players;
    final rules = widget.gameSession.houseRules;
    final preview = _winnerName != null ? widget.gameSession.calculateRound(_winnerName!) : null;

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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mark the winner (showed cards) and what each player holds. '
                  'Winner gets ${rules.winnerFullPoints} pts from players with no sequences, '
                  '${rules.winnerReducedPoints} pts from players who showed sequences.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final avatar = availableAvatars[player.avatarIndex];
                    final maal = player.maal;
                    final isWinner = _winnerName == player.name;
                    final net = preview != null ? (preview[player.name] ?? 0) : maal.getTotalPoints(rules);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWinner ? Colors.amber.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                          width: isWinner ? 1.5 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ExpansionTile(
                          initiallyExpanded: index == 0,
                          collapsedIconColor: const Color(0xFFC4B5FD),
                          iconColor: const Color(0xFF34D399),
                          leading: CircleAvatar(
                            backgroundColor: avatar.color,
                            child: Icon(avatar.icon, color: Colors.white, size: 20),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  player.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              if (isWinner) const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.emoji_events, color: Colors.amberAccent, size: 18),
                              ),
                            ],
                          ),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (net < 0 ? Colors.redAccent : const Color(0xFF34D399)).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: (net < 0 ? Colors.redAccent : const Color(0xFF34D399)).withOpacity(0.4)),
                            ),
                            child: Text(
                              '${_signed(net)} pts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: net < 0 ? Colors.redAccent : const Color(0xFF34D399),
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: [
                                      _buildChip('Winner (showed)', isWinner, (val) {
                                        setState(() => _winnerName = val ? player.name : null);
                                      }, selectedColor: Colors.amber.shade700),
                                      _buildChip('Showed sequences', maal.hasShownSequence, (val) {
                                        setState(() => maal.hasShownSequence = val);
                                      }),
                                      _buildChip('Marriage (${rules.marriageHigh})', maal.hasMarriageHigh, (val) {
                                        setState(() {
                                          maal.hasMarriageHigh = val;
                                          if (val) maal.hasMarriageLow = false;
                                        });
                                      }),
                                      _buildChip('Marriage (${rules.marriageLow})', maal.hasMarriageLow, (val) {
                                        setState(() {
                                          maal.hasMarriageLow = val;
                                          if (val) maal.hasMarriageHigh = false;
                                        });
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCounter('Maal', maal.maalCount, rules.maxMaal,
                                      '${rules.maalPoints[maal.maalCount]} pts',
                                      (v) => setState(() => maal.maalCount = v)),
                                  _buildCounter('Tiplu', maal.tipluCount, 3,
                                      '${maal.tipluCount * rules.tipluPerCard} pts',
                                      (v) => setState(() => maal.tipluCount = v)),
                                  _buildCounter('Alter', maal.alterCount, rules.maxAlter,
                                      '${rules.alterPoints[maal.alterCount]} pts',
                                      (v) => setState(() => maal.alterCount = v)),
                                  _buildCounter('Joker', maal.jokerCount, rules.maxJoker,
                                      '${rules.jokerPoints[maal.jokerCount]} pts',
                                      (v) => setState(() => maal.jokerCount = v)),
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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (_winnerName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select the winner (player who showed the cards) first.')),
                      );
                      return;
                    }
                    final roundPoints = widget.gameSession.calculateRound(_winnerName!);
                    await widget.gameSession.recordRound(roundPoints);

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, anim1, anim2) => ScoreSummaryScreen(
                            gameSession: widget.gameSession,
                            tiplu: widget.tiplu,
                          ),
                          transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
                        ),
                      );
                    }
                  },
                  child: const Text('VIEW SUMMARY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int count, int max, String pointsText, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            onPressed: count > 0 ? () => onChanged(count - 1) : null,
          ),
          SizedBox(
            width: 24,
            child: Text('$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF34D399)),
            onPressed: count < max ? () => onChanged(count + 1) : null,
          ),
          const Spacer(),
          Text(pointsText, style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, ValueChanged<bool> onSelected, {Color? selectedColor}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? const Color(0xFF8B5CF6),
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.08),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? const Color(0xFFC4B5FD) : Colors.white.withOpacity(0.15)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Score Summary Screen
// ---------------------------------------------------------------------------
class ScoreSummaryScreen extends StatefulWidget {
  final GameSession gameSession;
  final String tiplu;

  const ScoreSummaryScreen({super.key, required this.gameSession, required this.tiplu});

  @override
  State<ScoreSummaryScreen> createState() => _ScoreSummaryScreenState();
}

class _ScoreSummaryScreenState extends State<ScoreSummaryScreen> with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
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
                                  '${p.name}: ${_signed(pts)}',
                                  style: TextStyle(color: pts < 0 ? Colors.redAccent : Colors.white70, fontSize: 14),
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

  Future<void> _confirmNewGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End this game?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Current scores will be cleared and you can start a new game with new players.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Game', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GameSession.clearStorage();
      if (!mounted) return;
      // Remove every old screen and open a FRESH setup screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GameSetupScreen()),
        (route) => false,
      );
    }
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
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10))],
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
                          Text(leader.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text('LEADER', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
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
                        final lastRound = widget.gameSession.roundHistory.isNotEmpty
                            ? (widget.gameSession.roundHistory.last[player.name] ?? 0)
                            : 0;

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
                              subtitle: Text(
                                'This round: ${_signed(lastRound)}',
                                style: TextStyle(color: lastRound < 0 ? Colors.redAccent : Colors.white54, fontSize: 12),
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // Clear the old round screens so the stack doesn't keep growing
                              Navigator.pushAndRemoveUntil(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, anim1, anim2) => TipluSelectionScreen(gameSession: widget.gameSession),
                                  transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('NEXT ROUND', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          ),
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
                          onPressed: _confirmNewGame,
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

// ---------------------------------------------------------------------------
// Confetti painter
// ---------------------------------------------------------------------------
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