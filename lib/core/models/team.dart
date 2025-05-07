import 'player.dart';

enum TeamFormat {
  twoVsTwo,    // 2x2
  threeVsThree, // 3x3
  fourVsFour,  // 4x4
  sixVsSix,    // 6x6
}

class Team {
  final String id;
  final String name;
  final TeamFormat format;
  final List<Player> players;
  final Player? setter; // Levantador específico para o time (opcional)

  Team({
    required this.id,
    required this.name,
    required this.format,
    required this.players,
    this.setter,
  }) {
    // Validação do número de jogadores baseado no formato
    final expectedPlayers = _getExpectedPlayersCount(format);
    if (players.length != expectedPlayers) {
      throw ArgumentError(
        'Número inválido de jogadores para o formato $format. '
        'Esperado: $expectedPlayers, Recebido: ${players.length}',
      );
    }

    // Validação do levantador
    if (setter != null && !setter!.isSetter) {
      throw ArgumentError('O jogador designado como levantador deve ter a flag isSetter como true');
    }
  }

  // Método para obter o número esperado de jogadores baseado no formato
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

  // Método para criar uma cópia do time com campos modificados
  Team copyWith({
    String? id,
    String? name,
    TeamFormat? format,
    List<Player>? players,
    Player? setter,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      players: players ?? this.players,
      setter: setter ?? this.setter,
    );
  }

  // Método para converter o time em um Map (útil para persistência)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format.toString(),
      'players': players.map((player) => player.toMap()).toList(),
      'setter': setter?.toMap(),
    };
  }

  // Método para criar um time a partir de um Map
  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      format: TeamFormat.values.firstWhere(
        (e) => e.toString() == map['format'],
      ),
      players: (map['players'] as List)
          .map((playerMap) => Player.fromMap(playerMap as Map<String, dynamic>))
          .toList(),
      setter: map['setter'] != null
          ? Player.fromMap(map['setter'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() => 'Team(id: $id, name: $name, format: $format, players: $players, setter: $setter)';
} 