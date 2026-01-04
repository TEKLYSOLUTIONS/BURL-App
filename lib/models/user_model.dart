class Player {
  final String id;
  final String name;
  final String avatarUrl;
  final String role; // e.g., "Batsman", "Bowler", "All-rounder"
  final String age;
  final String battingStyle; // e.g., "Right-hand bat"
  final String bowlingStyle; // e.g., "Right-arm fast"

  const Player({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
    required this.age,
    required this.battingStyle,
    this.bowlingStyle = '',
  });

  // Mock Data
  static const List<Player> mockPlayers = [
    Player(
      id: '1',
      name: 'Arjun Sharma',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      role: 'Batsman',
      age: '14',
      battingStyle: 'Right-hand bat',
    ),
    Player(
      id: '2',
      name: 'Rohan Verma',
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
      role: 'All-rounder',
      age: '15',
      battingStyle: 'Left-hand bat',
      bowlingStyle: 'Left-arm orthodox',
    ),
  ];
}
