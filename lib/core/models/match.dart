import 'package:hive/hive.dart';
import 'team.dart';
import 'player.dart';
import 'waiting_queue.dart';
import '../extensions/match_helpers.dart';

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
  final List<Player> players;

  @HiveField(6)
  final List<Player> setters;

  @HiveField(7)
  final Team teamInCourtA;
  @HiveField(8)
  final Team teamInCourtB;
  @HiveField(9)
  final Team nextTeam;
  
  @HiveField(10)
  final WaitingQueue waitingQueue;
  
  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? updatedAt;

  Match({
    required this.id,
    required this.name,
    required this.format,
    required this.separateSetters,
    required this.teamSelectionMode,
    List<Player>? players,
    List<Player>? setters,
    Team? teamInCourtA,
    Team? teamInCourtB,
    Team? nextTeam,
    WaitingQueue? waitingQueue,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : players = players ?? [],
        setters = setters ?? [],
        teamInCourtA = teamInCourtA ?? Team.empty(),
        teamInCourtB = teamInCourtB ?? Team.empty(),
        nextTeam = nextTeam ?? Team.empty(),
        waitingQueue = waitingQueue ?? WaitingQueue(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt;


  // Gera os times baseado no modo de seleção
  Match generateTeams() {
    if (players.isEmpty) {
      throw ArgumentError('Não há jogadores registrados para gerar times');
    }

    final playersPerTeam = getExpectedPlayersCount(format);
    final maxPossibleTeams = ((players.length + setters.length) / playersPerTeam).floor();

    if (maxPossibleTeams < 2) {
      throw ArgumentError('Número insuficiente de jogadores para formar times');
    }

    List<Player> availablePlayers = [...players];

    if (separateSetters) {
      final availableSetters = [...setters];

      if (availableSetters.length < 2) {
        throw ArgumentError('Número insuficiente de levantadores para os times');
      }

      if (teamSelectionMode == TeamSelectionMode.random) {
        availableSetters.shuffle();
        availablePlayers.shuffle();
      }

      final teamA = createTeam('Time A', availablePlayers, availableSetters);
      final teamB = createTeam('Time B', availablePlayers, availableSetters);
      final nextTeam = createTeam('Próxima', availablePlayers, availableSetters);

      return copyWith(
        teamInCourtA: teamA,
        teamInCourtB: teamB,
        nextTeam: nextTeam,
        waitingQueue: WaitingQueue(players: availablePlayers, setterQueue: availableSetters),
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

      return copyWith(
        teamInCourtA: teamA,
        teamInCourtB: teamB,
        nextTeam: nextTeam,
        waitingQueue: WaitingQueue(players: availablePlayers, setterQueue: []),
        updatedAt: DateTime.now(),
      );
    }
  }

  Match processNextRound({required Team winningTeam}) {
    if (!hasNextTeamPlayers()) return this;
    final (losingTeamName, losingPlayers, losingSetter) = getLosingTeamData(winningTeam);

    Team nextRoundTeam;
    Team newNextTeam;

    final playersQueue = [...waitingQueue.players];
    final settersQueue = [...waitingQueue.setterQueue];

    if (separateSetters) {

      if(isNextTeamComplete()) {
        final nextSetter = resolveNextSetter(losingSetter, settersQueue);
        final nextPlayers = takePlayers(playersQueue, playersPerTeam - 1);

        newNextTeam = buildTeam(
          name: 'Próxima',
          players: nextPlayers,
          setter: nextSetter,
        );

        nextRoundTeam = buildTeam(
          name: losingTeamName,
          players: [...nextTeam.players],
          setter: nextTeam.setter,
        );

        playersQueue.addAll(losingPlayers);
      } else {
        final nextRoundPlayers = [...nextTeam.players];
        nextRoundPlayers.addAll(takePlayers(losingPlayers, playersPerTeam - 1 - nextRoundPlayers.length));

        final nextRoundSetter = nextTeam.setter ?? losingSetter!;
        final nextSetter = nextTeam.setter != null ? losingSetter : null;

        nextRoundTeam = buildTeam(
          name: losingTeamName,
          players: nextRoundPlayers,
          setter: nextRoundSetter,
        );

        newNextTeam = buildTeam(
          name: 'Próxima',
          players: losingPlayers,
          setter: nextSetter,
        );
      }
    } else {
      if (isNextTeamComplete()) {
        nextRoundTeam = buildTeam(
          name: losingTeamName,
          players: [...nextTeam.players],
        );

        final nextPlayers = takePlayers(playersQueue, playersPerTeam);

        if (nextPlayers.length < playersPerTeam) {
          nextPlayers.addAll(takePlayers(losingPlayers, playersPerTeam - nextPlayers.length));
        }

        newNextTeam = buildTeam(
          name: 'Próxima',
          players: nextPlayers,
        );
        playersQueue.addAll(losingPlayers);
      } else {
        final nextRoundPlayers = [...nextTeam.players];
        nextRoundPlayers.addAll(takePlayers(losingPlayers, playersPerTeam - nextRoundPlayers.length));

        nextRoundTeam = buildTeam(
          name: losingTeamName,
          players: nextRoundPlayers,
        );

        newNextTeam = buildTeam(
          name: 'Próxima',
          players: losingPlayers,
        );
      }
    }

    return copyWith(
      teamInCourtA: teamInCourtA == winningTeam ? teamInCourtA.copyWith(victories: teamInCourtA.victories + 1) : nextRoundTeam,
      teamInCourtB: teamInCourtA == winningTeam ? nextRoundTeam : teamInCourtB.copyWith(victories: teamInCourtB.victories + 1),
      nextTeam: newNextTeam,
      waitingQueue: WaitingQueue(
        players: playersQueue,
        setterQueue: settersQueue,
      ),
      updatedAt: DateTime.now(),
    );
  }

  // Cria uma cópia da pelada com campos modificados
  Match copyWith({
    String? id,
    String? name,
    TeamFormat? format,
    bool? separateSetters,
    TeamSelectionMode? teamSelectionMode,
    List<Player>? players,
    List<Player>? setters,
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
      players: players ?? this.players,
      setters: setters ?? this.setters,
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
      'players': players.map((p) => p.toMap()).toList(),
      'setters': setters.map((p) => p.toMap()).toList(),
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
      players: (map['players'] as List)
          .map((p) => Player.fromMap(p as Map<String, dynamic>))
          .toList(),
      setters: (map['setters'] as List)
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
