import 'package:hive/hive.dart';
import 'player.dart';

part 'team.g.dart';

@HiveType(typeId: 2)
class Team {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final TeamFormat format;
  
  @HiveField(3)
  final List<Player> players;
  
  @HiveField(4)
  final Player? setter; // Levantador específico para o time (opcional)

  @HiveField(5)
  final int victories;

  factory Team.empty() {
    return Team(
      id: '',
      name: '',
      format: TeamFormat.twoVsTwo,
      players: [],
      victories: 0
    );
  }

  Team({
    required this.id,
    required this.name,
    required this.format,
    required this.players,
    required this.victories,
    this.setter,
  }) {
    if (setter != null) {
      if (!setter!.isSetter) {
        throw ArgumentError('O jogador designado como levantador deve ter a flag isSetter como true');
      }
    }
  }

  int _getExpectedPlayersCount(TeamFormat format) {
    switch (format) {
      case TeamFormat.twoVsTwo:
        return 2;
      case TeamFormat.threeVsThree:
        return 3;
      case TeamFormat.fourVsFour:
        return 4;
      case TeamFormat.sixVsSix:
        return 6;
    }
  }

  Team copyWith({
    String? id,
    String? name,
    TeamFormat? format,
    List<Player>? players,
    Player? setter,
    int? victories,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      players: players ?? this.players,
      setter: setter ?? this.setter,
      victories: victories ?? this.victories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format.toString(),
      'players': players.map((p) => p.toMap()).toList(),
      'setter': setter?.toMap(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      format: TeamFormat.values.firstWhere(
        (e) => e.toString() == map['format'],
      ),
      players: (map['players'] as List)
          .map((p) => Player.fromMap(p as Map<String, dynamic>))
          .toList(),
      setter: map['setter'] != null
          ? Player.fromMap(map['setter'] as Map<String, dynamic>)
          : null,
      victories: map['victories'] as int
    );
  }

  @override
  String toString() => 'Team(id: $id, name: $name, format: $format, players: $players, setter: $setter, victories: $victories)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 1)
enum TeamFormat {
  @HiveField(0)
  twoVsTwo,    // 2x2
  @HiveField(1)
  threeVsThree, // 3x3
  @HiveField(2)
  fourVsFour,  // 4x4
  @HiveField(3)
  sixVsSix,    // 6x6
} 