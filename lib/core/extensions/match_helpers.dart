
import 'dart:math';

import '../models/match.dart';
import '../models/team.dart';
import '../models/player.dart';

/// Extensão que adiciona métodos auxiliares à classe [Match] para facilitar
/// operações como formação de times, manipulação de filas e resolução de lógica de rodada.
extension MatchHelpers on Match {

  /// Quantidade de jogadores por time, considerando o formato da partida.
  int get playersPerTeam => getExpectedPlayersCount(format);

  /// Gera um identificador único para um time com base no timestamp atual.
  String _generateTeamId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = Random().nextInt(100000); // de 0 a 99999
    return 'team_${timestamp}_$randomPart';
  }

  /// Remove até [count] jogadores de [source] e retorna a lista removida.
  List<Player> takePlayers(List<Player> source, int count) {
    final result = <Player>[];
    while (result.length < count && source.isNotEmpty) {
      result.add(source.removeAt(0));
    }
    return result;
  }

  /// Retorna o próximo levantador da fila ou o [fallbackSetter] caso a fila esteja vazia.
  /// Se houver um próximo levantador, o fallback é adicionado ao final da fila.
  Player resolveNextSetter(Player? fallbackSetter, List<Player> setterQueue) {
    if (setterQueue.isNotEmpty) {
      final next = setterQueue.removeAt(0);
      setterQueue.add(fallbackSetter!);
      return next;
    }
    return fallbackSetter!;
  }

  List<Player> resolveNextPlayers(List<Player> fallbackPlayers, List<Player> playersQueue, int count) {
    final result = takePlayers(playersQueue, count);

    if (result.length < count) {
      result.addAll(takePlayers(fallbackPlayers, count - result.length));
    }

    return result;
  }

  /// Cria uma instância de [Team] com os dados fornecidos, incluindo nome, jogadores e levantador.
  Team buildTeam({
    required String name,
    required List<Player> players,
    Player? setter,
  }) {
    return Team(
      id: _generateTeamId(),
      name: name,
      format: format,
      players: players,
      setter: setter,
      victories: 0
    );
  }

  /// Cria um time removendo jogadores e, se necessário, um levantador das listas fornecidas.
  Team createTeam(String name, List<Player> availablePlayers, List<Player> availableSetters, int victories) {
    Player? setter;
    if (availableSetters.isNotEmpty) {
      setter = availableSetters.removeAt(0);
    }

    final players = <Player>[];
    while (players.length < getExpectedPlayersCount(format) - (separateSetters ? 1 : 0) && availablePlayers.isNotEmpty) {
      players.add(availablePlayers.removeAt(0));
    }

    return Team(
      id: _generateTeamId(),
      name: name,
      format: format,
      players: players,
      setter: setter,
      victories: victories
    );
  }

  /// Retorna a quantidade esperada de jogadores por time, conforme o formato configurado.
  int getExpectedPlayersCount(TeamFormat format) {
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

  int getMinimunNumberOfPlayers() {
    if (separateSetters) {
      return playersPerTeam * 2;
    } else {
      return (playersPerTeam * 2) - 1;
    }
  }

  int getMinimumNumberOfSetters() {
    return 2;
  }

  /// Verifica se o time "Próxima" está completo com base na configuração atual.
  bool isNextTeamComplete() {
    return nextTeam.players.length == (separateSetters ? playersPerTeam - 1 : playersPerTeam);
  }

  bool hasNextTeamPlayers() {
    return nextTeam.players.isNotEmpty || nextTeam.setter != null;
  }

  (String, List<Player>, Player?) getLosingTeamData(Team winningTeam) {
    final isAWinning = teamInCourtA == winningTeam;
    final losingTeam = isAWinning ? teamInCourtB : teamInCourtA;
    return (losingTeam.name, [...losingTeam.players], losingTeam.setter);
  }
}