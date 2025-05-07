import 'player.dart';

class WaitingQueue {
  final List<Player> players;
  final List<Player> setterQueue; // Fila específica para levantadores

  WaitingQueue({
    List<Player>? players,
    List<Player>? setterQueue,
  })  : players = players ?? [],
        setterQueue = setterQueue ?? [];

  // Adiciona um jogador à fila principal
  WaitingQueue addPlayer(Player player) {
    if (player.isSetter) {
      return copyWith(setterQueue: [...setterQueue, player]);
    }
    return copyWith(players: [...players, player]);
  }

  // Remove um jogador da fila principal
  WaitingQueue removePlayer(Player player) {
    if (player.isSetter) {
      return copyWith(
        setterQueue: setterQueue.where((p) => p.id != player.id).toList(),
      );
    }
    return copyWith(
      players: players.where((p) => p.id != player.id).toList(),
    );
  }

  // Obtém os próximos jogadores da fila
  List<Player> getNextPlayers(int count) {
    if (players.length < count) {
      return [];
    }
    return players.sublist(0, count);
  }

  // Obtém o próximo levantador da fila
  Player? getNextSetter() {
    if (setterQueue.isEmpty) {
      return null;
    }
    return setterQueue.first;
  }

  // Cria uma cópia da fila com campos modificados
  WaitingQueue copyWith({
    List<Player>? players,
    List<Player>? setterQueue,
  }) {
    return WaitingQueue(
      players: players ?? this.players,
      setterQueue: setterQueue ?? this.setterQueue,
    );
  }

  // Converte a fila em um Map (útil para persistência)
  Map<String, dynamic> toMap() {
    return {
      'players': players.map((player) => player.toMap()).toList(),
      'setterQueue': setterQueue.map((player) => player.toMap()).toList(),
    };
  }

  // Cria uma fila a partir de um Map
  factory WaitingQueue.fromMap(Map<String, dynamic> map) {
    return WaitingQueue(
      players: (map['players'] as List)
          .map((playerMap) => Player.fromMap(playerMap as Map<String, dynamic>))
          .toList(),
      setterQueue: (map['setterQueue'] as List)
          .map((playerMap) => Player.fromMap(playerMap as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() => 'WaitingQueue(players: $players, setterQueue: $setterQueue)';
} 