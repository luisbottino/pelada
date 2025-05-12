import 'package:hive/hive.dart';
import 'team.dart';
import 'player.dart';
import 'waiting_queue.dart';

part 'match.g.dart';

@HiveType(typeId: 4)
enum TeamSelectionMode {
  @HiveField(0)
  random,     // Seleção aleatória de times
  @HiveField(1)
  sequential, // Seleção por ordem de chegada
}

@HiveType(typeId: 5)
class Match {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final TeamFormat format;
  
  @HiveField(3)
  final bool separateSetters;
  
  @HiveField(4)
  final TeamSelectionMode teamSelectionMode;
  
  @HiveField(5)
  final List<Player> registeredPlayers;

  @HiveField(6)
  final Team teamInCourtA;
  @HiveField(7)
  final Team teamInCourtB;
  @HiveField(8)
  final Team nextTeam;
  
  @HiveField(9)
  final WaitingQueue waitingQueue;
  
  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime? updatedAt;

  Match({
    required this.id,
    required this.name,
    required this.format,
    required this.separateSetters,
    required this.teamSelectionMode,
    List<Player>? registeredPlayers,
    Team? teamInCourtA,
    Team? teamInCourtB,
    Team? nextTeam,
    WaitingQueue? waitingQueue,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : registeredPlayers = registeredPlayers ?? [],
        teamInCourtA = teamInCourtA ?? Team.empty(),
        teamInCourtB = teamInCourtB ?? Team.empty(),
        nextTeam = nextTeam ?? Team.empty(),
        waitingQueue = waitingQueue ?? WaitingQueue(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt;

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
    final maxPossibleTeams = (registeredPlayers.length / playersPerTeam).floor();

    if (maxPossibleTeams < 2) {
      throw ArgumentError('Número insuficiente de jogadores para formar times');
    }

    List<Player> availablePlayers = List.from(registeredPlayers);

    if (separateSetters) {
      final setters = List<Player>.from(availablePlayers.where((p) => p.isSetter));
      final nonSetters = List<Player>.from(availablePlayers.where((p) => !p.isSetter));

      if (setters.length < 2) {
        throw ArgumentError('Número insuficiente de levantadores para os times');
      }

      if (teamSelectionMode == TeamSelectionMode.random) {
        setters.shuffle();
        nonSetters.shuffle();
      }

      final teamA = createTeam('Time A', nonSetters, setters);
      final teamB = createTeam('Time B', nonSetters, setters);
      final nextTeam = createTeam('Próxima', nonSetters, setters);

      final newWaitingQueue = WaitingQueue(
        players: nonSetters,
        setterQueue: setters,
      );

      return copyWith(
        teamInCourtA: teamA,
        teamInCourtB: teamB,
        nextTeam: nextTeam,
        waitingQueue: newWaitingQueue,
        updatedAt: DateTime.now(),
      );
    } else {
      // Sem separação de levantadores
      if (teamSelectionMode == TeamSelectionMode.random) {
        availablePlayers.shuffle();
      }

      final teamA = createTeam('Time A', availablePlayers, List.empty());
      final teamB = createTeam('Time B', availablePlayers, List.empty());
      final nextTeam = createTeam('Próxima', availablePlayers, List.empty());

      // Todos os jogadores restantes vão para a fila de espera
      final newWaitingQueue = WaitingQueue(
        players: availablePlayers,
        setterQueue: [],
      );

      return copyWith(
        teamInCourtA: teamA,
        teamInCourtB: teamB,
        nextTeam: nextTeam,
        waitingQueue: newWaitingQueue,
        updatedAt: DateTime.now(),
      );
    }
  }

  Team createTeam(String name, List<Player> availablePlayers, List<Player> availableSetters) {
    if (availablePlayers.isNotEmpty) {
      Player? setter;
      if (availableSetters.isNotEmpty) {
        setter = availableSetters.removeAt(0);
      }

      final players = <Player>[];
      while (players.length < _getExpectedPlayersCount(format) - (separateSetters ? 1 : 0) && availablePlayers.isNotEmpty) {
        players.add(availablePlayers.removeAt(0));
      }

      return Team(
        id: 'team_${DateTime.now().millisecondsSinceEpoch.toString()}',
        name: name,
        format: format,
        players: players,
        setter: setter,
      );
    } else {
      return Team.empty();
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

  // Cria uma cópia da pelada com campos modificados
  Match copyWith({
    String? id,
    String? name,
    TeamFormat? format,
    bool? separateSetters,
    TeamSelectionMode? teamSelectionMode,
    List<Player>? registeredPlayers,
    Team? teamInCourtA,
    Team? teamInCourtB,
    Team? nextTeam,
    WaitingQueue? waitingQueue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      separateSetters: separateSetters ?? this.separateSetters,
      teamSelectionMode: teamSelectionMode ?? this.teamSelectionMode,
      registeredPlayers: registeredPlayers ?? this.registeredPlayers,
      teamInCourtA: teamInCourtA,
      teamInCourtB: teamInCourtB,
      nextTeam: nextTeam,
      waitingQueue: waitingQueue ?? this.waitingQueue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'teamInCourtA': teamInCourtA.toMap(),
      'teamInCourtB': teamInCourtB.toMap(),
      'nextTeam': nextTeam.toMap(),
      'waitingQueue': waitingQueue.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
      teamInCourtA: Team.fromMap(map['teamInCourtA'] as Map<String, dynamic>),
      teamInCourtB: Team.fromMap(map['teamInCourtB'] as Map<String, dynamic>),
      nextTeam: Team.fromMap(map['nextTeam'] as Map<String, dynamic>),
      waitingQueue: WaitingQueue.fromMap(map['waitingQueue'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  @override
  String toString() => 'Match(id: $id, name: $name, format: $format, teamInCoutA: $teamInCourtA, teamInCoutB: $teamInCourtB, nextTeam: $nextTeam)';
}
