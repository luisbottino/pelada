import 'team.dart';
import 'player.dart';
import 'waiting_queue.dart';

enum TeamSelectionMode {
  random,     // Seleção aleatória de times
  sequential, // Seleção por ordem de chegada
}

class Match {
  final String id;
  final String name;
  final TeamFormat format;
  final bool separateSetters;
  final TeamSelectionMode teamSelectionMode;
  final List<Player> registeredPlayers;
  final List<Team> teams;
  final WaitingQueue waitingQueue;
  final DateTime createdAt;

  Match({
    required this.id,
    required this.name,
    required this.format,
    required this.separateSetters,
    required this.teamSelectionMode,
    List<Player>? registeredPlayers,
    List<Team>? teams,
    WaitingQueue? waitingQueue,
    DateTime? createdAt,
  })  : registeredPlayers = registeredPlayers ?? [],
        teams = teams ?? [],
        waitingQueue = waitingQueue ?? WaitingQueue(),
        createdAt = createdAt ?? DateTime.now();

  // Adiciona um jogador à lista de jogadores registrados
  Match addPlayer(Player player) {
    if (registeredPlayers.any((p) => p.id == player.id)) {
      throw ArgumentError('Jogador já registrado nesta pelada');
    }
    return copyWith(
      registeredPlayers: [...registeredPlayers, player],
    );
  }

  // Remove um jogador da lista de jogadores registrados
  Match removePlayer(Player player) {
    return copyWith(
      registeredPlayers: registeredPlayers.where((p) => p.id != player.id).toList(),
    );
  }

  // Gera os times baseado no modo de seleção
  Match generateTeams() {
    if (registeredPlayers.isEmpty) {
      throw ArgumentError('Não há jogadores registrados para gerar times');
    }

    final playersPerTeam = _getExpectedPlayersCount(format);
    final totalTeams = (registeredPlayers.length / playersPerTeam).floor();
    
    if (totalTeams < 2) {
      throw ArgumentError('Número insuficiente de jogadores para formar times');
    }

    List<Player> availablePlayers = List.from(registeredPlayers);
    List<Team> newTeams = [];

    // Se houver separação de levantadores, garante que cada time tenha um
    if (separateSetters) {
      final setters = availablePlayers.where((p) => p.isSetter).toList();
      if (setters.length < totalTeams) {
        throw ArgumentError('Número insuficiente de levantadores para os times');
      }
    }

    for (int i = 0; i < totalTeams; i++) {
      List<Player> teamPlayers = [];
      
      // Seleciona jogadores baseado no modo de seleção
      if (teamSelectionMode == TeamSelectionMode.random) {
        availablePlayers.shuffle();
      }

      // Adiciona jogadores ao time
      for (int j = 0; j < playersPerTeam; j++) {
        if (availablePlayers.isEmpty) break;
        teamPlayers.add(availablePlayers.removeAt(0));
      }

      // Cria o time
      newTeams.add(Team(
        id: 'team_${i + 1}',
        name: 'Time ${i + 1}',
        format: format,
        players: teamPlayers,
        setter: separateSetters ? teamPlayers.firstWhere((p) => p.isSetter) : null,
      ));
    }

    // Adiciona jogadores restantes à fila de espera
    final newWaitingQueue = availablePlayers.fold<WaitingQueue>(
      waitingQueue,
      (queue, player) => queue.addPlayer(player),
    );

    return copyWith(
      teams: newTeams,
      waitingQueue: newWaitingQueue,
    );
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

  // Cria uma cópia da pelada com campos modificados
  Match copyWith({
    String? id,
    String? name,
    TeamFormat? format,
    bool? separateSetters,
    TeamSelectionMode? teamSelectionMode,
    List<Player>? registeredPlayers,
    List<Team>? teams,
    WaitingQueue? waitingQueue,
    DateTime? createdAt,
  }) {
    return Match(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      separateSetters: separateSetters ?? this.separateSetters,
      teamSelectionMode: teamSelectionMode ?? this.teamSelectionMode,
      registeredPlayers: registeredPlayers ?? this.registeredPlayers,
      teams: teams ?? this.teams,
      waitingQueue: waitingQueue ?? this.waitingQueue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Converte a pelada em um Map (útil para persistência)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'format': format.toString(),
      'separateSetters': separateSetters,
      'teamSelectionMode': teamSelectionMode.toString(),
      'registeredPlayers': registeredPlayers.map((p) => p.toMap()).toList(),
      'teams': teams.map((t) => t.toMap()).toList(),
      'waitingQueue': waitingQueue.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Cria uma pelada a partir de um Map
  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] as String,
      name: map['name'] as String,
      format: TeamFormat.values.firstWhere(
        (e) => e.toString() == map['format'],
      ),
      separateSetters: map['separateSetters'] as bool,
      teamSelectionMode: TeamSelectionMode.values.firstWhere(
        (e) => e.toString() == map['teamSelectionMode'],
      ),
      registeredPlayers: (map['registeredPlayers'] as List)
          .map((p) => Player.fromMap(p as Map<String, dynamic>))
          .toList(),
      teams: (map['teams'] as List)
          .map((t) => Team.fromMap(t as Map<String, dynamic>))
          .toList(),
      waitingQueue: WaitingQueue.fromMap(map['waitingQueue'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  String toString() => 'Match(id: $id, name: $name, format: $format, teams: $teams)';
} 