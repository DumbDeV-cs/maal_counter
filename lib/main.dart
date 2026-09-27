import 'package:flutter/material.dart';
import 'dart:ui';

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

  Player({required this.name, required this.avatarIndex}) : maal = PlayerMaal();
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
        // Cycle to next avatar automatically for convenience
        _selectedAvatarIndex = (_selectedAvatarIndex + 1) % availableAvatars.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Avatar Selection Bar
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
                      child: Container(
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
                          radius: 22,
                          child: Icon(avatar.icon, color: Colors.white, size: 22),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Input Field
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
              // Players List
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
  final List<Player> players;
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
  final List<Player> players;
  final String tiplu;

  const MaalInputScreen({super.key, required this.players, required this.tiplu});

  @override
  State<MaalInputScreen> createState() => _MaalInputScreenState();
}

class _MaalInputScreenState extends State<MaalInputScreen> {
  @override
  Widget build(BuildContext context) {
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
                  itemCount: widget.players.length,
                  itemBuilder: (context, index) {
                    final player = widget.players[index];
                    final avatar = availableAvatars[player.avatarIndex];
                    final maal = player.maal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
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
                        trailing: Container(
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
                        players: widget.players,
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

// 4. Score Summary Screen
class ScoreSummaryScreen extends StatelessWidget {
  final List<Player> players;
  final String tiplu;

  const ScoreSummaryScreen({super.key, required this.players, required this.tiplu});

  List<Player> _getSortedPlayers() {
    List<Player> list = List.from(players);
    list.sort((a, b) => b.maal.totalPoints.compareTo(a.maal.totalPoints));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = _getSortedPlayers();
    final winner = sortedPlayers.first;
    final winnerAvatar = availableAvatars[winner.avatarIndex];

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
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: winnerAvatar.color,
                        child: Icon(winnerAvatar.icon, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      winner.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text('WINS THE ROUND!', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      '${winner.maal.totalPoints} Points',
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text('FINAL STANDINGS', style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = sortedPlayers[index];
                    final avatar = availableAvatars[player.avatarIndex];
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
                          backgroundColor: avatar.color,
                          child: Icon(avatar.icon, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          player.name,
                          style: TextStyle(
                            color: isWinner ? Colors.amberAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        trailing: Text(
                          '${player.maal.totalPoints} pts',
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
                  backgroundColor: const Color(0xFF10B981),
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